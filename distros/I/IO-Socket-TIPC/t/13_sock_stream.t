use strict;
use warnings;
use IO::Socket::TIPC ':all';
use Test::More;
my $tests;
BEGIN { $tests = 0; };

my $Type = 0x73570000 + $$;

# Long API.
# This time around, also test getpeername and getsockname.
# SOCKET CREATION.  almost straight from the POD examples...
# Create a server
my $sock1 = IO::Socket::TIPC->new(
	SocketType => SOCK_STREAM,
	Listen => 1,
	LocalAddrType => 'name',
	LocalType => $Type,
	LocalInstance => 73570101,
	LocalScope => 'node',
);
ok(defined($sock1), "Create a server socket");
if(fork()) {
	# server (and test) process.
	alarm(5);
	my $sock2 = $sock1->accept();
	ok(defined($sock2), "Client connected");

	# test getpeername and getsockname
	my $caddr = $sock2->getpeername();
	ok(defined($caddr), "getpeername() returned a sockaddr");
	ok(length($caddr->stringify), "stringify doesn't barf on sockaddr");
	unlike($caddr->stringify, qr/[()]/, "sockaddr is well-formed");
	my $saddr = $sock2->getsockname();
	ok(defined($saddr), "getsockname() returned a sockaddr");
	ok(length($saddr->stringify), "stringify doesn't barf on sockaddr");
	unlike($saddr->stringify, qr/[()]/, "sockaddr is well-formed");

	# same thing, for getpeerid and getsockid
	$caddr = $sock2->getpeerid();
	ok(defined($caddr), "getpeerid() returned a sockaddr");
	ok(length($caddr->stringify), "stringify doesn't barf on sockaddr");
	unlike($caddr->stringify, qr/[()]/, "sockaddr is well-formed");
	$saddr = $sock2->getsockid();
	ok(defined($saddr), "getsockid() returned a sockaddr");
	ok(length($saddr->stringify), "stringify doesn't barf on sockaddr");
	unlike($saddr->stringify, qr/[()]/, "sockaddr is well-formed");

	# test server-side I/O
	alarm(5);
	$sock2->print("Hello there!\n");
	like($sock2->getline(), qr/hello yourself/, "Client replied to our message");
} else {
	# child process
	alarm(5);
	# Connect to the above server
	my $sock2 = IO::Socket::TIPC->new(
		SocketType => 'stream',
		PeerAddrType => 'name',
		PeerType => $Type,
		PeerInstance => 73570101,
		PeerDomain => '<0.0.0>',
	);

	# make sure client sockets support getpeername/getsockname too
	my $caddr = $sock2->getpeername();
	die unless defined $caddr;
	die unless length $caddr->stringify();
	die if $caddr->stringify() =~ /[()]/;
	my $saddr = $sock2->getsockname();
	die unless defined $saddr;
	die unless length $saddr->stringify();
	die if $saddr->stringify() =~ /[()]/;
	# and getpeerid/getsockid, while we're at it
	$caddr = $sock2->getpeerid();
	die unless defined $caddr;
	die unless length $caddr->stringify();
	die if $caddr->stringify() =~ /[()]/;
	$saddr = $sock2->getsockid();
	die unless defined $saddr;
	die unless length $saddr->stringify();
	die if $saddr->stringify() =~ /[()]/;

	# test client-side I/O
	my $string = $sock2->getline();
	if($string =~ /Hello/) {
		$sock2->print("Well, hello yourself!\n");
	}
	exit(0);
}
BEGIN { $tests += 15; }

# Same thing again, this time with the short API.
# Create a server
$sock1 = IO::Socket::TIPC->new(
	SocketType => SOCK_STREAM, Listen => 1, Local => "{$Type, 73570102}");
ok(defined($sock1), "Create a server socket");
if(fork()) {
	# server (and test) process.
	alarm(5);
	my $sock2 = $sock1->accept();
	ok(defined($sock2), "Client connected");
	alarm(5);
	$sock2->print("Hello there!\n");
	like($sock2->getline(), qr/you again/i, "Client replied to our message");
} else {
	# child process
	alarm(5);
	# Connect to the above server
	my $sock2 = IO::Socket::TIPC->new(
		SocketType => 'stream', Peer => "{$Type, 73570102}");
	my $string = $sock2->getline();
	if($string =~ /Hello/) {
		$sock2->print("You again?\n");
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
