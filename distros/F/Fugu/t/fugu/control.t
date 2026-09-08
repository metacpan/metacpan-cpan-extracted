#!/usr/bin/env perl
# ex:ts=8 sw=4:
# Unit tests for Fugu::Control and Fugu::Control::Client over a
# temporary socket. A forked server serves one connection at a time,
# so the tests need no event loop.

use v5.36;
use Test::More;
use FindBin qw($RealBin);
use lib "$RealBin/../../lib";
use Fugu::TestLog;
use File::Temp qw(tempdir);
use IO::Socket::UNIX;
use POSIX       qw(_exit);
use Socket      qw(SOCK_STREAM);
use Time::HiRes qw(sleep);

use_ok('Fugu::Control');
use_ok('Fugu::EventLoop');
use_ok('Fugu::Imsg');

my $dir = tempdir( CLEANUP => 1 );
my $n   = 0;

# start_server($setup): fork a server that serves connections over a
#	real event loop until the parent kills it. $setup->($control)
#	registers the commands. The function returns ($path, $pid).
sub start_server ($setup)
{
	my $path = sprintf '%s/control%d.sock', $dir, $n++;

	my $pid = fork // die "fork: $!";
	if ( $pid == 0 ) {
		local $SIG{ALRM} = sub { _exit(1) };
		alarm 30;

		my $loop    = Fugu::EventLoop->new;
		my $control = Fugu::Control->new( path => $path );
		$setup->($control);
		$control->listen( loop => $loop ) or _exit(1);
		$loop->run;
		_exit(0);
	}

	# Wait until the child has bound the socket
	for ( 1 .. 100 ) {
		last if -S $path;
		sleep 0.05;
	}
	die 'the server never bound its socket' unless -S $path;

	return ( $path, $pid );
}

# stop_server($pid, $path)
sub stop_server ( $pid, $path )
{
	kill 'TERM', $pid;
	waitpid $pid, 0;
	unlink $path;

	return;
}

subtest 'a command answers' => sub {
	my ( $path, $pid ) = start_server(
		sub ($control) {
			$control->register( ping => sub ($) { { pong => 1 } } );
			$control->register(
				echo => sub ($args) { { got => $args->{say} } } );
		} );

	my $client = Fugu::Control::Client->new( path => $path );

	is_deeply( $client->request('ping'), { pong => 1 }, 'a reply decodes' );
	is( $client->error, undef, 'and no error is recorded' );

	is_deeply(
		$client->request( echo => { say => 'hello' } ),
		{ got => 'hello' },
		'the arguments reach the handler'
	);

	$client->disconnect;
	stop_server( $pid, $path );
};

subtest 'the constructor contracts hold' => sub {
	my $control = Fugu::Control->new( path => "$dir/unused.sock" );
	is( $control->path, "$dir/unused.sock", 'the server knows its path' );

	ok( !eval { $control->register( c => 'not code' ); 1 },
		'a handler must be code' );
	ok( !eval { Fugu::Control->new; 1 }, 'a server needs a path' );
	ok( !eval { Fugu::Control::Client->new; 1 },
		'and so does a client' );
	ok( !eval { $control->listen; 1 }, 'and listen needs a loop' );
};

subtest 'an unknown command is refused, not fatal' => sub {
	my ( $path, $pid ) = start_server(
		sub ($control) {
			$control->register( ping => sub ($) { { pong => 1 } } );
		} );

	my $client = Fugu::Control::Client->new( path => $path );

	is( $client->request('nonsense'), undef, 'the reply is undef' );
	like( $client->error, qr/unknown command: nonsense/,
		'and the reason names the command' );
	ok( !$client->socket_absent, 'the socket was there, so it was a refusal' );

	# The connection survives a refusal
	is_deeply( $client->request('ping'), { pong => 1 },
		'the next command still works' );

	$client->disconnect;
	stop_server( $pid, $path );
};

subtest 'a handler that dies gives an error reply' => sub {
	my ( $path, $pid ) = start_server(
		sub ($control) {
			$control->register( boom => sub ($) { die "no\n" } );
			$control->register( ping => sub ($) { { pong => 1 } } );
		} );

	my $client = Fugu::Control::Client->new( path => $path );

	is( $client->request('boom'), undef, 'the reply is undef' );
	like( $client->error, qr/command failed: boom/,
		'and the reason says which command' );

	# The server is still there. A daemon must not fall over
	# because one handler had a bad day.
	is_deeply( $client->request('ping'), { pong => 1 },
		'the server kept serving' );

	$client->disconnect;
	stop_server( $pid, $path );
};

subtest 'a reply larger than one frame spans frames' => sub {
	# One imsg frame carries about 16 KB. A device list can be
	# bigger than that, so this is the real case, not a corner.
	my $big = 'x' x ( 4 * Fugu::Imsg::MAX_PAYLOAD() );

	my ( $path, $pid ) = start_server(
		sub ($control) {
			$control->register( big => sub ($) { { data => $big } } );
			$control->register(
				list => sub ($) {
					return [ map { { id => $_, pad => 'y' x 200 } }
						    1 .. 200 ];
				} );
		} );

	my $client = Fugu::Control::Client->new( path => $path );

	my $reply = $client->request('big');
	ok( defined $reply, 'the big reply arrived' )
	    or diag( $client->error // 'no error recorded' );
	is( length( $reply->{data} ), length($big), 'and it is whole' );
	is( $reply->{data}, $big, 'byte for byte' );

	my $list = $client->request('list');
	is( ref $list,     'ARRAY', 'an array reply survives too' );
	is( scalar @$list, 200,     'with every entry' );
	is( $list->[199]{id}, 200, 'and the last one is intact' );

	$client->disconnect;
	stop_server( $pid, $path );
};

subtest 'a malformed request is refused' => sub {
	my ( $path, $pid ) = start_server(
		sub ($control) {
			$control->register( ping => sub ($) { { pong => 1 } } );
		} );

	# Speak the transport by hand, so the test can send what the
	# client would never send
	my $sock = IO::Socket::UNIX->new(
		Type => SOCK_STREAM,
		Peer => $path,
	) or die "connect: $!";
	my $imsg = Fugu::Imsg->new( fh => $sock );

	# reply($data, $type): send one raw frame and read the answer
	my $seq = 100;
	my $reply = sub ( $data, $type = Fugu::Control::TYPE_REQUEST() ) {
		my $id = $seq++;
		$imsg->send( type => $type, peerid => $id, data => $data )
		    or return;
		my $frame = $imsg->recv( timeout => 5 ) or return;
		return $frame;
	};

	my $frame = $reply->('this is not json');
	is( $frame->{type}, Fugu::Control::TYPE_ERROR(),
		'a payload that is not JSON gives an error frame' );
	like( $frame->{data}, qr/not a JSON object/, 'and says so' );

	$frame = $reply->('[1,2,3]');
	like( $frame->{data}, qr/not a JSON object/,
		'a JSON array is not a request either' );

	$frame = $reply->('{"args":{}}');
	like( $frame->{data}, qr/names no command/, 'a request needs a command' );

	$frame = $reply->( '{"command":"ping"}', 99 );
	like( $frame->{data}, qr/not a control request/,
		'a frame of the wrong type is refused' );

	# The peerid comes back, so a client can tell which request an
	# error answers
	is( $frame->{peerid}, $seq - 1, 'the error carries the peerid' );

	# After all of that, the server still answers
	$imsg->send(
		type   => Fugu::Control::TYPE_REQUEST(),
		peerid => 7,
		data   => '{"command":"ping"}',
	);
	my $good = $imsg->recv( timeout => 5 );
	is( $good->{type}, Fugu::Control::TYPE_REPLY(),
		'a good request after bad ones still works' );

	$imsg->close;
	stop_server( $pid, $path );
};

subtest 'an oversized frame does not reach a handler' => sub {
	my $called = 0;
	my ( $path, $pid ) = start_server(
		sub ($control) {
			$control->register( ping => sub ($) { { pong => 1 } } );
		} );

	my $sock = IO::Socket::UNIX->new(
		Type => SOCK_STREAM,
		Peer => $path,
	) or die "connect: $!";
	my $imsg = Fugu::Imsg->new( fh => $sock );

	# The framing refuses the payload before it reaches the wire
	is( $imsg->send( type => 1, data => 'x' x 65536 ),
		undef, 'an oversized payload is not sent' );
	ok( !$imsg->is_dead, 'and the refusal does not kill the connection' );

	# A hand-built header that claims more than the format allows
	# poisons the reader, which is the framing contract. The server
	# drops that connection and stays up.
	syswrite $sock, pack( 'L4', 1, 0x7fffffff, 1, $$ );
	sleep 0.5;
	$imsg->close;

	my $client = Fugu::Control::Client->new( path => $path );
	is_deeply( $client->request('ping'), { pong => 1 },
		'the server survived the bad frame' );

	$client->disconnect;
	stop_server( $pid, $path );
};

subtest 'an absent socket is not a refusal' => sub {
	my $client =
	    Fugu::Control::Client->new( path => "$dir/never-made.sock" );

	is( $client->request('ping'), undef, 'the request fails' );
	ok( $client->socket_absent, 'and the client says the daemon is absent' );
	like( $client->error, qr/never-made\.sock/, 'the reason names the path' );
};

# A socket inside a directory the caller may not search looks absent
# to a test for the file. It is not: the daemon is there and running.
# An operator told "not running" about a running daemon looks in the
# wrong place.
subtest 'a socket behind a closed directory is a permission problem' => sub {
	plan skip_all => 'the test runs as root, which searches any directory'
	    if $> == 0;

	my $closed = "$dir/closed";
	mkdir $closed or die "mkdir: $!";
	my $path = "$closed/control.sock";

	my $control = Fugu::Control->new( path => $path );
	$control->register( ping => sub ($) { { pong => 1 } } );
	ok( $control->listen( loop => Fugu::EventLoop->new ),
		'the server bound inside the directory' );

	chmod 0000, $closed or die "chmod: $!";

	my $client = Fugu::Control::Client->new( path => $path );
	is( $client->request('ping'), undef, 'the request fails' );
	ok( !$client->socket_absent,
		'and the client does not call the daemon absent' );
	like( $client->error, qr/Permission denied/,
		'the reason is the permission' );

	chmod 0700, $closed;
	$control->shutdown;
	rmdir $closed;
};

subtest 'a listen refuses to take a live socket' => sub {
	my ( $path, $pid ) = start_server(
		sub ($control) {
			$control->register( ping => sub ($) { { pong => 1 } } );
		} );

	my $second = Fugu::Control->new( path => $path );
	is( $second->listen( loop => Fugu::EventLoop->new ),
		undef, 'a second server does not bind' );
	like( $second->error, qr/Another process serves/,
		'and it says why' );

	# The first server is untouched
	my $client = Fugu::Control::Client->new( path => $path );
	is_deeply( $client->request('ping'), { pong => 1 },
		'the first server still answers' );

	$client->disconnect;
	stop_server( $pid, $path );
};

subtest 'a stale socket is replaced' => sub {
	my $path = "$dir/stale.sock";

	# A socket file that nothing is behind, as a crashed daemon
	# leaves. bind(2) fails on an existing name, and a daemon that
	# will not start after a crash needs a hand at every reboot.
	my $dead = IO::Socket::UNIX->new(
		Type   => SOCK_STREAM,
		Local  => $path,
		Listen => 1,
	) or die "bind: $!";
	close $dead;
	ok( -e $path, 'the stale socket is on disk' );

	my $control = Fugu::Control->new( path => $path );
	ok( $control->listen( loop => Fugu::EventLoop->new ),
		'the server takes the name' )
	    or diag( $control->error // 'no error recorded' );

	$control->shutdown;
	ok( !-e $path, 'and shutdown removes the socket' );
};

subtest 'the socket is 0600 from birth' => sub {
	my $path = "$dir/mode.sock";

	my $control = Fugu::Control->new( path => $path );
	ok( $control->listen( loop => Fugu::EventLoop->new ),
		'the server bound' );

	my $mode = ( stat $path )[2] & 07777;
	is( $mode, 0600, 'no other user can connect' );

	$control->shutdown;
};

subtest 'listen with mode gives the named mode' => sub {
	my $path = "$dir/mode0660.sock";

	# A wide umask must not widen the socket, and the named mode
	# must hold anyway: the guard derives from the mode.
	my $old     = umask 0;
	my $control = Fugu::Control->new( path => $path );
	ok( $control->listen( loop => Fugu::EventLoop->new, mode => 0660 ),
		'the server bound' )
	    or diag( $control->error // 'no error recorded' );
	umask $old;

	is( ( stat $path )[2] & 07777, 0660, 'the socket is 0660' );

	$control->shutdown;
};

# _other_group():
#	A supplementary group id of the test process that differs from
#	the effective group. The socket carries the effective group at
#	birth, so only an other group can prove the chown.
sub _other_group ()
{
	my ( $egid, @rest ) = split ' ', $);
	my ($other) = grep { $_ != $egid } @rest;

	return $other;
}

subtest 'listen with group sets the socket group' => sub {
	my $path = "$dir/group.sock";

	# A supplementary group: a process can chgrp its own file to a
	# group that it belongs to, so the call needs no root. The
	# effective group would prove nothing, because the socket
	# carries it already.
	my $gid = _other_group();
	plan skip_all => 'the test process has one group alone'
	    unless defined $gid;

	my $control = Fugu::Control->new( path => $path );
	ok(
		$control->listen(
			loop  => Fugu::EventLoop->new,
			mode  => 0660,
			group => $gid,
		),
		'the server bound'
	    )
	    or diag( $control->error // 'no error recorded' );

	is( ( stat $path )[5], $gid, 'the socket carries the group' );
	is( ( stat $path )[2] & 07777, 0660, 'and the mode' );

	$control->shutdown;
};

subtest 'listen resolves a group name with getgrnam' => sub {
	my $gid = _other_group();
	plan skip_all => 'the test process has one group alone'
	    unless defined $gid;

	my $name = getgrgid($gid);
	plan skip_all => 'the supplementary group has no name'
	    unless defined $name && length $name;

	my $path    = "$dir/groupname.sock";
	my $control = Fugu::Control->new( path => $path );
	ok(
		$control->listen(
			loop  => Fugu::EventLoop->new,
			mode  => 0660,
			group => $name,
		),
		'the server bound with a group name'
	    )
	    or diag( $control->error // 'no error recorded' );

	is( ( stat $path )[5], $gid, 'the name resolved to the group id' );

	$control->shutdown;
};

subtest 'an unresolvable group is a recoverable failure' => sub {
	my $path = "$dir/nogroup.sock";

	my $control = Fugu::Control->new( path => $path );
	is(
		$control->listen(
			loop  => Fugu::EventLoop->new,
			group => 'fugu-no-such-group',
		),
		undef,
		'listen returns undef'
	);
	like( $control->error, qr/fugu-no-such-group/,
		'the reason names the group' );
	ok( !-e $path, 'and no file stays at the path' );
};

subtest 'a numeric group without a group entry is refused too' => sub {

	# A chown to a group id that no group holds reports success,
	# so the boundary must catch the number like it catches a
	# name.
	my $bogus;
	for my $candidate ( 61000 .. 61050 ) {
		next if defined getgrgid($candidate);
		$bogus = $candidate;
		last;
	}
	plan skip_all => 'every probed group id exists'
	    unless defined $bogus;

	my $path    = "$dir/bogusgid.sock";
	my $control = Fugu::Control->new( path => $path );
	is(
		$control->listen(
			loop  => Fugu::EventLoop->new,
			group => $bogus,
		),
		undef,
		'listen returns undef'
	);
	like( $control->error, qr/\Q$bogus\E/,
		'the reason names the group id' );
	ok( !-e $path, 'and no file stays at the path' );
};

subtest 'a failed chown takes the socket down' => sub {
	plan skip_all => 'root can chgrp to any group' if $> == 0;

	# A non-root process cannot chgrp to a group outside its own
	# set, so group 0 forces the chown failure after the bind.
	my %mine = map { $_ => 1 } split ' ', $);
	plan skip_all => 'the test process is in group 0' if $mine{0};

	my $path    = "$dir/chownfail.sock";
	my $control = Fugu::Control->new( path => $path );

	is(
		$control->listen(
			loop  => Fugu::EventLoop->new,
			mode  => 0660,
			group => 0,
		),
		undef,
		'listen returns undef'
	);
	like( $control->error, qr/chown/, 'the reason names the chown' );
	ok( !-e $path, 'and the half-built socket is gone' );
};

subtest 'a mode outside the permission bits dies' => sub {
	my $control = Fugu::Control->new( path => "$dir/badmode.sock" );

	ok( !eval {
		$control->listen( loop => Fugu::EventLoop->new,
			mode => 07777 );
		1;
	    },
		'a mode above 0777 dies' );
	like( $@, qr/Invalid socket mode/, 'and says so' );
};

subtest 'the credential read answers or fails closed' => sub {

	# The read guards the constant, so a perl whose Socket module
	# defines no SO_PEERCRED gets a reason, never a croak. The
	# platform decides which branch this proves.
	socketpair( my $a_end, my $b_end, Socket::AF_UNIX(),
		SOCK_STREAM, Socket::PF_UNSPEC() )
	    or die "socketpair: $!";

	my ( $peer, $fault ) = Fugu::Control::_read_peer($a_end);

	if ( Fugu::Control->peer_supported ) {

		# The peer of a socketpair is this process, and the
		# field order is the sockpeercred order, so the values
		# must match exactly.
		is( $fault, undef, 'the read reports no fault' );
		is( $peer->{uid}, $>, 'the uid is the effective uid' );
		is( $peer->{gid}, ( split ' ', $) )[0],
			'the gid is the effective gid' );
		is( $peer->{pid}, $$, 'the pid is this process' );
	}
	elsif ( defined eval { Socket::SO_PEERCRED() } ) {

		# The platform defines the constant with an other
		# field order, so only the fail-closed shape holds
		# here. The fabricated-bytes subtest below locks the
		# unpack itself.
		ok( defined $peer || defined $fault, 'one of the two answers' );
	}
	else {
		is( $peer, undef, 'no credentials come back' );
		like( $fault, qr/SO_PEERCRED/,
			'and the reason names the constant' );
	}

	close $a_end;
	close $b_end;
};

subtest 'the credential unpack keeps a large id positive' => sub {

	# The id fields of a struct sockpeercred are unsigned, and the
	# process id is signed. A signed read would turn a uid at or
	# above 2**31 negative, and a gate would then compare the
	# wrong number.
	my @fields = Fugu::Control::_unpack_peer(
		pack 'L2l', 4026531840, 4026531841, 1234 );
	is_deeply(
		\@fields,
		[ 4026531840, 4026531841, 1234 ],
		'a uid and a gid at or above 2**31 stay positive'
	);
};

subtest 'peer answers only inside a handler' => sub {
	my $control = Fugu::Control->new( path => "$dir/peer.sock" );
	is( $control->peer, undef, 'peer is undef outside a handler' );

	is( Fugu::Control->peer_supported,
		$^O eq 'openbsd' ? 1 : 0,
		'peer_supported is true on OpenBSD alone' );
};

subtest 'peer is undef where the platform is not supported' => sub {
	plan skip_all => 'the platform reports peer credentials'
	    if Fugu::Control->peer_supported;

	my ( $path, $pid ) = start_server(
		sub ($control) {
			$control->register(
				has_peer => sub ($) {
					return { seen => $control->peer
						    ? 1 : 0 };
				} );
		} );

	my $client = Fugu::Control::Client->new( path => $path );
	is_deeply( $client->request('has_peer'), { seen => 0 },
		'a handler sees undef off OpenBSD' );

	$client->disconnect;
	stop_server( $pid, $path );
};

subtest 'peer names the connected peer on OpenBSD' => sub {
	plan skip_all => 'peer credentials need OpenBSD'
	    unless Fugu::Control->peer_supported;

	my ( $path, $pid ) = start_server(
		sub ($control) {
			$control->register(
				whoami => sub ($) { $control->peer } );
		} );

	my $client = Fugu::Control::Client->new( path => $path );
	my $peer   = $client->request('whoami');

	ok( defined $peer, 'the handler read the credentials' )
	    or diag( $client->error // 'no error recorded' );
	is( $peer->{uid}, $>, 'the uid is the effective uid of the client' );
	is( $peer->{gid}, ( split ' ', $) )[0],
		'the gid is the effective gid of the client' );
	is( $peer->{pid}, $$, 'the pid is the pid of the client' );

	$client->disconnect;
	stop_server( $pid, $path );
};

done_testing();
