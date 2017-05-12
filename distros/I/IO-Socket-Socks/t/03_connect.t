#!/usr/bin/env perl

use Test::More;
use Socket;
use IO::Socket::Socks;
use IO::Select;
use Time::HiRes 'time';
use strict;
use Cwd;
require(getcwd."/t/subs.pm");

if( $^O eq 'MSWin32' ) {
	plan skip_all => 'Fork and Windows are incompatible';
}

my ($s_pid, $s_host, $s_port) = make_socks_server(4);
my ($h_pid, $h_host, $h_port) = make_http_server();

my $sock = IO::Socket::Socks->new(
	SocksVersion => 4, ProxyAddr => $s_host, ProxyPort => $s_port, ConnectAddr => $h_host, ConnectPort => $h_port
);
ok(defined($sock), 'Socks 4 connect') or diag $SOCKS_ERROR;
is($sock->version, 4, 'Version is 4');
my @dst = $sock->dst;
is(@dst, 3, 'Socks 4 dst after connect has 3 elements');
like($dst[0], qr/^\d+\.\d+\.\d+\.\d+$/, 'dst[0] looks like ip');
like($dst[1], qr/^\d+$/, 'dst[1] looks like port');
is($dst[2], IO::Socket::Socks::ADDR_IPV4, 'dst[2] is ipv4');

my $family = length($sock->sockaddr) == 4 ? PF_INET : PF_INET6;

kill 15, $s_pid;
($s_pid, $s_host, $s_port) = make_socks_server(5);
$sock = IO::Socket::Socks->new(
	SocksVersion => 5, ProxyAddr => $s_host, ProxyPort => $s_port, ConnectAddr => $h_host, ConnectPort => $h_port
);
ok(defined($sock), 'Socks 5 connect') or diag $SOCKS_ERROR;
is($sock->version, 5, 'Version is 5');
@dst = $sock->dst;
is(@dst, 3, 'Socks 5 dst after connect has 3 elements');
like($dst[1], qr/^\d+$/, 'dst[1] looks like port');
ok(
	$dst[2] == IO::Socket::Socks::ADDR_IPV4 ||
	$dst[2] == IO::Socket::Socks::ADDR_IPV6,
	'dst[2] is ipv4 or ipv6'
);

kill 15, $s_pid;
($s_pid, $s_host, $s_port) = make_socks_server(5, 'root', 'toor');
$sock = IO::Socket::Socks->new(
	SocksVersion => 5, ProxyAddr => $s_host, ProxyPort => $s_port, ConnectAddr => $h_host, ConnectPort => $h_port, Username => 'root', Password => 'toor',
	AuthType => 'userpass'
);
ok(defined($sock), 'Socks 5 connect with auth') or diag $SOCKS_ERROR;

$sock = IO::Socket::Socks->new(
	SocksVersion => 5, ProxyAddr => $s_host, ProxyPort => $s_port, ConnectAddr => $h_host, ConnectPort => $h_port, Username => 'root', Password => '123',
	AuthType => 'userpass'
) or my $error = int($!); # save it _immediately_ after fail
ok(!defined($sock), 'Socks 5 connect with auth and incorrect password');
ok($error == ESOCKSPROTO, '$! == ESOCKSPROTO') or diag $error, "!=", ESOCKSPROTO;
ok($SOCKS_ERROR == IO::Socket::Socks::AUTHREPLY_FAILURE, '$SOCKS_ERROR == AUTHREPLY_FAILURE')
	or diag int($SOCKS_ERROR), "!=", IO::Socket::Socks::AUTHREPLY_FAILURE;

kill 15, $s_pid;

SKIP: {
	skip "SOCKS_SLOW_TESTS environment variable should has true value", 1 unless $ENV{SOCKS_SLOW_TESTS} || $ENV{AUTOMATED_TESTING};
	
	($s_pid, $s_host, $s_port) = make_socks_server(4, undef, undef, accept => 3, reply => 2);
	my $start = time();
	$sock = IO::Socket::Socks->new(
		SocksVersion => 4, ProxyAddr => $s_host, ProxyPort => $s_port, ConnectAddr => $h_host, ConnectPort => $h_port
	);
	ok(defined($sock), 'Socks 4 blocking connect success');
	
	$start = time();
	$sock = IO::Socket::Socks->new(
		SocksVersion => 4, ProxyAddr => $s_host, ProxyPort => $s_port, ConnectAddr => $h_host, ConnectPort => $h_port, Blocking => 0
	);
	ok(defined($sock), 'Socks 4 non-blocking connect success');
	my $time_spent = time()-$start;
	ok($time_spent < 3, 'Socks 4 non-blocking connect time') or diag "$time_spent sec spent";
	my $sel = IO::Select->new($sock);
	my $i = 0;
	$start = time();
	until ($sock->ready) {
		$i++;
		$time_spent = time()-$start;
		ok($time_spent < 1, "Connection attempt $i not blocked") or diag "$time_spent sec spent";
		if ($SOCKS_ERROR == SOCKS_WANT_READ) {
			$sel->can_read(0.8);
		}
		elsif ($SOCKS_ERROR == SOCKS_WANT_WRITE) {
			$sel->can_write(0.8);
		}
		else {
			last;
		}
		$start = time();
	}
	ok($sock->ready, 'Socks 4 non-blocking socket ready') or diag $SOCKS_ERROR;
    is($sock->version, 4, 'Version is 4 for non-blocking connect');

	kill 15, $s_pid;
	($s_pid, $s_host, $s_port) = make_socks_server(5, 'root', 'toor', accept => 3, reply => 2);
	$start = time();
	$sock = IO::Socket::Socks->new(
		SocksVersion => 5, ProxyAddr => $s_host, ProxyPort => $s_port, ConnectAddr => $h_host, ConnectPort => $h_port, Username => 'root', Password => 'toor',
		AuthType => 'userpass', Blocking => 0
	);
	ok(defined($sock), 'Socks 5 non-blocking connect success');
	$time_spent = time()-$start;
	ok($time_spent < 3, 'Socks 5 non-blocking connect time') or diag "$time_spent sec spent";
	$sel = IO::Select->new($sock);
	$i = 0;
	$start = time();
	until ($sock->ready) {
		$i++;
		$time_spent = time()-$start;
		ok($time_spent < 1, "Connection attempt $i not blocked") or diag "$time_spent sec spent";
		if ($SOCKS_ERROR == SOCKS_WANT_READ) {
			$sel->can_read(0.8);
		}
		elsif ($SOCKS_ERROR == SOCKS_WANT_WRITE) {
			$sel->can_write(0.8);
		}
		else {
			last;
		}
		$start = time();
	}
	ok($sock->ready, 'Socks 5 non-blocking socket ready') or diag $SOCKS_ERROR;
    is($sock->version, 5, 'Version is 5 for non-blocking connect');

	$sock = IO::Socket::Socks->new(
		SocksVersion => 5, ProxyAddr => $s_host, ProxyPort => $s_port, ConnectAddr => $h_host, ConnectPort => $h_port, Username => 'root', Password => 'toot',
		AuthType => 'userpass', Blocking => 0
	);
	if (defined $sock) {
		$sel = IO::Select->new($sock);
		$i = 0;
		$start = time();
		until ($sock->ready) {
			$i++;
			$time_spent = time()-$start;
			ok($time_spent < 1, "Connection attempt $i not blocked") or diag "$time_spent sec spent";
			if ($SOCKS_ERROR == SOCKS_WANT_READ) {
				$sel->can_read(0.8);
			}
			elsif ($SOCKS_ERROR == SOCKS_WANT_WRITE) {
				$sel->can_write(0.8);
			}
			else {
				last;
			}
			$start = time();
		}
		
		ok(!$sock->ready, 'Socks 5 non-blocking connect with fail auth');
	}
	else {
		pass('Socks 5 non-blocking connect with fail auth (immediatly)');
	}

	kill 15, $s_pid;
}

($s_pid, $s_host, $s_port) = make_socks_server(5);

socket(my $unconnected_sock, $family, SOCK_STREAM, getprotobyname('tcp'))  || die "socket: $!";
$sock = IO::Socket::Socks->new_from_socket($unconnected_sock, ProxyAddr => $s_host, ProxyPort => $s_port, ConnectAddr => $h_host, ConnectPort => $h_port);
ok($unconnected_sock, "plain socket still alive");
if (ok($sock, "socks object created from plain socket")) {
	is(fileno($sock), fileno($unconnected_sock), "socks object uses plain socket");
}
        # without quotes will not work on old perl (<= 5.14?)
$sock = "$IO::Socket::Socks::SOCKET_CLASS"->new(PeerAddr => $s_host, PeerPort => $s_port);
if (ok($sock, "$IO::Socket::Socks::SOCKET_CLASS socket created")) {
	$sock = IO::Socket::Socks->start_SOCKS($sock, ConnectAddr => $h_host, ConnectPort => $h_port);
	ok($sock, "$IO::Socket::Socks::SOCKET_CLASS socket upgraded to IO::Socket::Socks");
	isa_ok($sock, 'IO::Socket::Socks');
	$sock->syswrite(
		"GET / HTTP/1.1\015\012\015\012"
	);
	is($sock->getline(), "HTTP/1.1 200 OK\015\012", 'socket works properly');
}

kill 15, $s_pid;

SKIP: {
	skip "SOCKS_SLOW_TESTS environment variable should has true value", 1 unless $ENV{SOCKS_SLOW_TESTS} || $ENV{AUTOMATED_TESTING};
	($s_pid, $s_host, $s_port) = make_socks_server(5, undef, undef, reply => 3);
	
	socket(my $unconnected_sock, $family, SOCK_STREAM, getprotobyname('tcp'))  || die "socket: $!";
	my $start = time();
	$sock = IO::Socket::Socks->new_from_socket($unconnected_sock, ProxyAddr => $s_host, ProxyPort => $s_port, ConnectAddr => $h_host, ConnectPort => $h_port, Blocking => 0);
	ok($sock, "new non-bloking object from plain socket created");
	ok(!$sock->blocking, 'object is non-blocking');
	my $time_spent = time()-$start;
	ok($time_spent < 3, 'new_from_socket: Socks 5 non-blocking connect time') or diag "$time_spent sec spent";
	
	my $sel = IO::Select->new($sock);
	my $i = 0;
	$start = time();
	until ($sock->ready) {
		$i++;
		$time_spent = time()-$start;
		ok($time_spent < 1, "new_from_socket: Connection attempt $i not blocked") or diag "$time_spent sec spent";
		if ($SOCKS_ERROR == SOCKS_WANT_READ) {
			$sel->can_read(0.8);
		}
		elsif ($SOCKS_ERROR == SOCKS_WANT_WRITE) {
			$sel->can_write(0.8);
		}
		else {
			last;
		}
		$start = time();
	}
	ok($sock->ready, 'new_from_socket: Socks 5 non-blocking socket ready') or diag $SOCKS_ERROR;
    is($sock->version, 5, 'new_from_socket: Version is 5 for non-blocking connect');
	
	$SOCKS_ERROR->set(SOCKS_WANT_WRITE, 'TEST rt#118471');
	$sock = "$IO::Socket::Socks::SOCKET_CLASS"->new(PeerAddr => $s_host, PeerPort => $s_port);
	$sock->blocking(0);
	$start = time();
	$sock = IO::Socket::Socks->start_SOCKS($sock, ConnectAddr => $h_host, ConnectPort => $h_port);
	ok($sock, "$IO::Socket::Socks::SOCKET_CLASS socket upgraded to IO::Socket::Socks");
	ok(!$sock->blocking, 'object is non-blocking');
	$time_spent = time()-$start;
	ok($time_spent < 3, 'start_SOCKS: Socks 5 non-blocking connect time') or diag "$time_spent sec spent";
	
	$sel = IO::Select->new($sock);
	$i = 0;
	$start = time();
	until ($sock->ready) {
		$i++;
		$time_spent = time()-$start;
		ok($time_spent < 1, "start_SOCKS: Connection attempt $i not blocked") or diag "$time_spent sec spent";
		if ($SOCKS_ERROR == SOCKS_WANT_READ) {
			$sel->can_read(0.8);
		}
		elsif ($SOCKS_ERROR == SOCKS_WANT_WRITE) {
			$sel->can_write(0.8);
		}
		else {
			last;
		}
		$start = time();
	}
	ok($sock->ready, 'start_SOCKS: Socks 5 non-blocking socket ready') or diag $SOCKS_ERROR;
    is($sock->version, 5, 'start_SOCKS: Version is 5 for non-blocking connect');
    
	kill 15, $s_pid;
}

kill 15, $h_pid;
done_testing();
