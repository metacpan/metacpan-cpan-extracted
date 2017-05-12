use strict;
use warnings;
use IO::Socket::TIPC ':all';
use Test::More;
my $tests;
BEGIN { $tests = 0; };

my $Type = 0x73570000 + $$;

# Long API.
my ($instance1, $instance2) = (0x73570401, 0x73570402);
my $sock1 = IO::Socket::TIPC->new(
	SocketType => SOCK_DGRAM,
	LocalAddrType => 'name',
	LocalType => $Type,
	LocalInstance => $instance2,
	LocalScope => 'node',
);
ok(defined($sock1), "Create the first socket");
if(fork()) {
	# PEER2 (and test) process.
	# SOCKET CREATION.
	my $sock2 = IO::Socket::TIPC->new(
		SocketType => 'dgram',
		LocalAddrType => 'name',
		LocalType => $Type,
		LocalInstance => $instance1,
		LocalScope => 'node',
	);
	ok(defined($sock2), "Create a second socket");

	# connectionless socket; getpeername() shouldn't work
	my $paddr = $sock2->getpeername();
	ok(!defined($paddr), "getpeername() doesn't work on SOCK_RDM");
	my $saddr = $sock2->getsockname();
	ok(defined($saddr), "getsockname() still works on SOCK_RDM");
	ok(length($saddr->stringify), "stringify doesn't barf on sockaddr");
	unlike($saddr->stringify, qr/[()]/, "sockaddr is well-formed");

	alarm(5);
	my $addr1 = IO::Socket::TIPC::Sockaddr->new(
		AddrType => 'name',
		Type => $Type,
		Instance => $instance2,
	);
	$sock2->sendto($addr1, "Hello there!\n");
	my $string;
	# recvfrom works with length specified
	my $replyaddr = $sock2->recvfrom($string, 13);
	like($string, qr/Well, hello/, "Client replied to our message");
} else {
	# PEER1 process
	alarm(5);
	my $string;
	# recvfrom works without length specified
	my $serv = $sock1->recvfrom($string);
	if($string =~ /Hello/) {
		$sock1->sendto($serv, "Well, hello!\n");
	}
	exit(0);
}
BEGIN { $tests += 7; }


# Shorthand version of the same thing.
($instance1, $instance2) = (0x73570403, 0x73570404);
$sock1 = IO::Socket::TIPC->new(
	SocketType => SOCK_DGRAM,
	Local => "{$Type, $instance1}",
);
ok(defined($sock1), "Create the first socket");
if(fork()) {
	# PEER2 (and test) process.
	# SOCKET CREATION.
	my $sock2 = IO::Socket::TIPC->new(
		SocketType => 'dgram',
		Local => "{$Type, $instance2}",
	);
	ok(defined($sock2), "Create a second socket");
	alarm(5);
	my $addr1 = IO::Socket::TIPC::Sockaddr->new("{$Type, $instance1}");
	$sock2->sendto($addr1, "Hello there!\n");
	my $string;
	my $replyaddr = $sock2->recvfrom($string, 13);
	like($string, qr/You again/, "Client replied to our message");
} else {
	# PEER1 process
	alarm(5);
	my $string;
	my $serv = $sock1->recvfrom($string, 13);
	if($string =~ /Hello/) {
		$sock1->sendto($serv, "You again??!\n");
	}
	exit(0);
}
BEGIN { $tests += 3; }


BEGIN {
    if(IO::Socket::TIPC->detect()) {
		plan tests => $tests;
	} else {
        plan skip_all => 'you need to load the tipc module';
	}
}
