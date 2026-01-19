#! /usr/bin/perl

use strict;
use warnings;

use Test2::V1 -import, -utf8;

use Future::Uring;

use POSIX qw/setlocale LC_ALL/;
use Socket qw/
	pack_sockaddr_in sockaddr_family INADDR_LOOPBACK
	AF_INET AF_UNIX SOCK_DGRAM SOCK_STREAM PF_UNSPEC
/;
use IO::Socket::INET;
use IO::Socket::UNIX;
use Time::HiRes qw/time/;

sub time_about(&@) {
	my ($code, $want_time, $name) = @_;
	my $ctx = Test2::API::context;
	my $t0 = time();
	$code->();
	my $t1 = time();
	my $got_time = $t1 - $t0;
	$ctx->ok(
		$got_time >= $want_time * 0.9 && $got_time <= $want_time * 1.5, $name
	) or
		$ctx->diag(sprintf "Test took %.3f seconds", $got_time);
	$ctx->release;
}

setlocale(LC_ALL, 'C');

subtest accept => sub {
	my $server_sock = IO::Socket::INET->new(
		Type      => Socket::SOCK_STREAM(),
		LocalAddr => "localhost",
		LocalPort => 0,
		Listen    => 1,
	) or die "Cannot socket()/listen() - $@";
	$server_sock->blocking(0);

	my $server_handle = Future::Uring::to_handle($server_sock);

	my $f = $server_handle->accept;
	my $sockname = $server_sock->sockname;

	my $client_sock = IO::Socket::INET->new(Type => SOCK_STREAM) or die "Cannot socket():  $@";
	$client_sock->connect($sockname) or die "Cannot connect(): $@";
	my $accepted_sock = $f->get;
	ok($client_sock->peername eq $accepted_sock->inner->sockname, 'Accepted socket address matches');
};

subtest connect => sub {
	my $server_sock = IO::Socket::INET->new(
		Type      => Socket::SOCK_STREAM(),
		LocalAddr => "localhost",
		LocalPort => 0,
		Listen    => 1,
	) or die "Cannot socket()/listen() - $@";

	my $sockname = $server_sock->sockname;
	# ->connect success
	{
		my $client_sock = IO::Socket::INET->new(
			Type => Socket::SOCK_STREAM(),
		) or die "Cannot socket() - $@";
		my $client_handle = Future::Uring::to_handle($client_sock);

		my $f = $client_handle->connect($sockname);
		$f->get;
		my $acceptedsock = $server_sock->accept;
		ok($client_sock->peername eq $acceptedsock->sockname, 'Accepted socket address matches');
	}
	$server_sock->close;
	undef $server_sock;

	# ->connect fails
	{
		my $client_sock = IO::Socket::INET->new(
			Type => Socket::SOCK_STREAM(),
		) or die "Cannot socket() - $@";
		my $client_handle = Future::Uring::to_handle($client_sock);

		my $f = $client_handle->connect($sockname);
		ok(!eval { $f->get; 1 }, 'Future::Uring::connect fails on closed server');
		like($f->failure, qr/^connect: Connection refused at t\/io\.t line \d+\n$/, 'Future::Uring::connect failure');
	}
};

subtest timeout => sub {
	time_about sub {
		Future::Uring::timeout_for(0.2)->get;
	}, 0.2, 'Future::Uring::timeout(0.2) sleeps 0.2 seconds';
	time_about sub {
		my $f1 = Future::Uring::timeout_for(0.1);
		my $f2 = Future::Uring::timeout_for(0.3);
		$f1->cancel;
		$f2->get;
	}, 0.3, 'Future::Uring::timeout_for can be cancelled';
	{
		my $f1 = Future::Uring::timeout_for(0.1);
		my $f2 = Future::Uring::timeout_for(0.3);
		is($f2->await, $f2, '->await returns Future');
		ok($f2->is_ready, '$f2 is ready after ->await');
		ok($f1->is_ready, '$f1 is also ready after ->await');
	}
	time_about sub {
		Future::Uring::timeout_until(time() + 0.2)->get;
	}, 0.2, 'Future::Uring::timeout_until(now + 0.2) sleeps 0.2 seconds';
};

subtest read => sub {
	# yielding bytes
	{
		pipe my ($rd, $wr) or die "Cannot pipe() - $!";
		my $reader = Future::Uring::to_handle($rd);
		$wr->autoflush();
		$wr->print("BYTES");
		my $f = $reader->read(5);
		is(scalar $f->get, "BYTES", "Future::Uring::Handle::read yields bytes from pipe");
	}
	# yielding EOF
	{
		pipe my ($rd, $wr) or die "Cannot pipe() - $!";
		my $reader = Future::Uring::to_handle($rd);
		$wr->close; undef $wr;
		my $f = $reader->read(1);
		is([ $f->get ], [], "Future::Uring::Handle::read yields nothing on EOF");
	}
	# TODO: is there a nice portable way we can test for an IO error?
};

sub _socketpair_INET_DGRAM
{
	my ($connected) = @_;
	$connected //= 1;
	# The IO::Socket constructors are unhelpful to us here; we'll do it ourselves
	my $rd = IO::Socket::INET->new->socket(AF_INET, SOCK_DGRAM, 0) or die "Cannot socket rd - $!";
	$rd->bind(pack_sockaddr_in(0, INADDR_LOOPBACK)) or die "Cannot bind rd - $!";
	my $wr = IO::Socket::INET->new->socket(AF_INET, SOCK_DGRAM, 0);
	$wr->connect($rd->sockname) or die "Cannot connect wr - $!" if $connected;
	return ($rd, $wr);
}

subtest recv => sub {
	my ($method, $expect_fromaddr) = @_;
	# yielding bytes
	{
		my ($rd, $wr) = _socketpair_INET_DGRAM();
		my $reader = Future::Uring::to_handle($rd);
		$wr->autoflush();
		$wr->send("BYTES");
		my $f = $reader->recv(5);
		is(scalar $f->get, "BYTES", "Future::IO::recv yields bytes from socket");
		# We can't know exactly what address it will be but 
		my $fromaddr = ($f->get)[1];
	}
	# From here onwards we don't need working sockaddr/peeraddr so we can just
	# use simpler IO::Socket::UNIX->socketpair instead

	# yielding EOF
	{
		my ($rd, $wr) = IO::Socket::UNIX->socketpair(AF_UNIX, SOCK_STREAM, PF_UNSPEC) or die "Cannot socketpair() - $!";
		my $reader = Future::Uring::to_handle($rd);
		$wr->close; undef $wr;
		my $f = $reader->recv(1);
		is ([ $f->get ], [], "Future::IO::recv yields nothing on EOF");
	}
};

subtest recvfrom => sub {
	plan(skip_all => 'unimplemented');

	my ($method, $expect_fromaddr) = @_;
	# yielding bytes
	{
		my ($rd, $wr) = _socketpair_INET_DGRAM();
		my $reader = Future::Uring::to_handle($rd);
		$wr->autoflush();
		$wr->send("BYTES");
		my $f = $reader->recvfrom(5);
		is(scalar $f->get, "BYTES", "Future::IO::recvfrom yields bytes from socket");
		# We can't know exactly what address it will be but 
		my $fromaddr = ($f->get)[1];
		ok(defined $fromaddr, "Future::IO::recvfrom also yields a fromaddr");
		is(sockaddr_family($fromaddr), AF_INET, "Future::IO::recvfrom fromaddr is valid AF_INET address");
	}
	# From here onwards we don't need working sockaddr/peeraddr so we can just
	# use simpler IO::Socket::UNIX->socketpair instead

	# yielding EOF
	{
		my ($rd, $wr) = IO::Socket::UNIX->socketpair(AF_UNIX, SOCK_STREAM, PF_UNSPEC) or die "Cannot socketpair() - $!";
		my $reader = Future::Uring::to_handle($rd);
		$wr->close; undef $wr;
		my $f = $reader->recvfrom(1);
		is ([ $f->get ], [], "Future::IO::recvfrom yields nothing on EOF");
	}
};

subtest send => sub {
	# success
	{
		# An unconnected socketpair to prove that ->send used the correct address later on
		my ($rd, $wr) = _socketpair_INET_DGRAM(0);
		my $writer = Future::Uring::to_handle($wr);
		my $f = $writer->sendto('BYTES', $rd->sockname);
		is(scalar $f->get, 5, 'Future::Uring::send yields sent count');
		$rd->recv(my $buf, 5);
		is($buf, "BYTES", 'Future::Uring::send sent bytes');
	}
	# From here onwards we don't need working sockaddr/peeraddr so we can just
	# use simpler IO::Socket::UNIX->socketpair instead
	
	# yielding EAGAIN
	{
		my ($rd, $wr) = IO::Socket::UNIX->socketpair(AF_UNIX, SOCK_STREAM, PF_UNSPEC) or die "Cannot socketpair() - $!";
		my $writer = Future::Uring::to_handle($wr);
		$wr->blocking(0);
		# Attempt to fill the buffer
		$wr->write("X" x 4096) for 1..256;
		my $f = $writer->send('more');
		ok(!$f->is_ready, '$f is still pending');
		# Now make some space. We need to drain it quite a lot for mechanisms
		# like ppoll() to be happy that the socket is actually writable
		$rd->blocking(0);
		$rd->read(my $buf, 4096) for 1..256;
		is(scalar $f->get, 4, 'Future::Uring::send yields written count');
	}
	# yielding EPIPE
	{
		my ($rd, $wr) = IO::Socket::UNIX->socketpair(AF_UNIX, SOCK_STREAM, PF_UNSPEC) or die "Cannot socketpair() - $!";
		my $writer = Future::Uring::to_handle($wr);
		$rd->close; undef $rd;
		local $SIG{PIPE} = 'IGNORE';
		my $f = $writer->send('BYTES');
		ok(!eval { $f->get }, 'Future::Uring::send fails on EPIPE');
		like($f->failure, qr/send: Broken pipe at t\/io\.t line \d+\n/, 'Future::Uring::send failure for EPIPE');
	}
};

subtest write => sub {
	{
		pipe my ($rd, $wr) or die "Cannot pipe() - $!";
		my $writer = Future::Uring::to_handle($wr);
		my $f = $writer->write("BYTES");
		is(scalar $f->get, 5, "Future::Uring::Handle::write yields written count");
		$rd->read(my $buf, 5);
		is($buf, "BYTES", "Future::Uring::Handle::write wrote bytes");
	}
	# yielding EAGAIN
	SKIP: {
		pipe my ($rd, $wr) or die "Cannot pipe() - $!";
		my $writer = Future::Uring::to_handle($wr);
		$wr->blocking(0);
		# Attempt to fill the pipe
		$wr->write("X" x 4096) for 1..256;
		my $f = $writer->write("more");
		ok(!$f->is_ready, '$f is still pending');
		# Now make some space
		$rd->read(my $buf, 4096);
		no warnings 'io';
		is(scalar $f->get, 4, "Future::Uring::Handle::write yields written count");
	}
	# yielding EPIPE
	{
		pipe my ($rd, $wr) or die "Cannot pipe() - $!";
		my $writer = Future::Uring::to_handle($wr);
		$rd->close; undef $rd;
		local $SIG{PIPE} = 'IGNORE';
		my $f = $writer->write("BYTES");
		ok(!eval { $f->get }, "Future::Uring::Handle::write fails on EPIPE");
		like($f->failure, qr/write: Broken pipe at t\/io\.t line \d+\n/, "Future::Uring::Handle::write failure for EPIPE");
	}
};

subtest waitpid => sub {
	# pre-exit
	{
		defined(my $pid = fork) or die "Unable to fork() - $!";
		if ($pid == 0) {
			# child
			exit 3;
		}
		Time::HiRes::sleep 0.1;
		my $f = Future::Uring::waitpid($pid);
		is(scalar $f->get, (3 << 8), 'Future::Uring::waitpid yields child wait status for pre-exit');
	}
	# post-exit
	{
		defined(my $pid = fork) or die "Unable to fork() - $!";
		if ($pid == 0) {
			# child
			Time::HiRes::sleep 0.1;
			exit 4;
		}
		my $f = Future::Uring::waitpid($pid);
		is(scalar $f->get, (4 << 8), 'Future::Uring::waitpid yields child wait status for post-exit');
	}
};

subtest read_timeout => sub {
	local $SIG{ALRM} = sub { die "Timeout!" };

	{
		pipe my ($rd, $wr) or die "cannot pipe() - $!";
		my $reader = Future::Uring::to_handle($rd);
		my $future = $reader->read(4, timeout => 1);
		alarm 2;
		syswrite $wr, 'test';
		my $result = eval { $future->get };
		alarm 0;
		is $result, 'test';
	}
	{
		pipe my ($rd, $wr) or die "cannot pipe() - $!";
		my $reader = Future::Uring::to_handle($rd);
		my $future = $reader->read(4, timeout => 1);
		alarm 2;
		my $result = $future->await;
		alarm 0;
		my $failure = $result->failure;
		like $failure, qr/read: Operation canceled at t\/io\.t line \d+\n/;
	}
	{
		my $ring = $Future::Uring::ring;
		$ring->nop(0) while $ring->sq_space_left > 1;

		pipe my ($rd, $wr) or die "cannot pipe() - $!";
		my $reader = Future::Uring::to_handle($rd);
		my $future = $reader->read(4, timeout => 1);
		# cmp_ok $ring->sq_space_left, '>', 100;
		alarm 2;
		my $result = $future->await;
		alarm 0;
		my $failure = $result->failure;
		like $failure, qr/read: Operation canceled at t\/io\.t line \d+\n/;
	}
};

done_testing;
