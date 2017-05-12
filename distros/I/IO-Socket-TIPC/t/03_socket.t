use strict;
use warnings;
use IO::Socket::TIPC ':all';
use Test::More;
my $tests;
BEGIN { $tests = 0 };
eval "use Test::Exception;";
my $test_exception_loaded = defined($Test::Exception::VERSION);


# simple creation
my $socket = IO::Socket::TIPC->new(SocketType => 'rdm');
ok(defined($socket), "new() can create a socket");
BEGIN { $tests += 1 };

# setsockopt defaults
is($socket->getsockopt(SOL_TIPC(), TIPC_IMPORTANCE()),
   TIPC_LOW_IMPORTANCE   , "new() doesn't clobber default importance");
is($socket->getsockopt(SOL_TIPC(), TIPC_CONN_TIMEOUT()),
   8000                  , "new() doesn't clobber default timeout");
BEGIN { $tests += 2 };

# setsockopt gets called internally by ->new()
$socket = IO::Socket::TIPC->new(SocketType     => 'rdm',
                                ConnectTimeout => 3000,
                                Importance     => TIPC_MEDIUM_IMPORTANCE);
ok(defined($socket), "new() can handle Timeout and Importance arguments");
is($socket->getsockopt(SOL_TIPC, TIPC_IMPORTANCE),
   TIPC_MEDIUM_IMPORTANCE, "new() sets specified importance");
is($socket->getsockopt(SOL_TIPC, TIPC_CONN_TIMEOUT),
   3000                  , "new() sets specified timeout");
BEGIN { $tests += 3 };

# setsockopt can be called directly
$socket->setsockopt(SOL_TIPC, TIPC_IMPORTANCE  , TIPC_HIGH_IMPORTANCE);
$socket->setsockopt(SOL_TIPC, TIPC_CONN_TIMEOUT, 4000);
is($socket->getsockopt(SOL_TIPC, TIPC_IMPORTANCE),
   TIPC_HIGH_IMPORTANCE  , "can setsockopt() importance manually");
is($socket->getsockopt(SOL_TIPC, TIPC_CONN_TIMEOUT),
   4000                  , "can setsockopt() timeout manually");
BEGIN { $tests += 2 };

# ->new() barfs on unknown SocketTypes
SKIP: {
	skip 'need Test::Exception', 1 unless $test_exception_loaded;
	throws_ok(sub { $socket = IO::Socket::TIPC->new(SocketType => 'foo') },
		qr/unknown SocketType foo/i, "TIPC->new() barfs on unknown SocketTypes");
}
BEGIN { $tests += 1 };

# ->new() barfs on unknown parameters
SKIP: {
	skip 'need Test::Exception', 2 unless $test_exception_loaded;
	throws_ok(sub { $socket = IO::Socket::TIPC->new(SocketType => 'rdm', Unknown => 1) },
		qr/unknown argument/i, "TIPC->new() barfs on unknown parameters");
	throws_ok(sub { $socket = IO::Socket::TIPC->new(SocketType => 'rdm', LocalUnknown => 1) },
		qr/unknown argument/i, "Sockaddr->new() barfs on unknown parameters");
}
BEGIN { $tests += 2 };

# ->new() can also take existing Sockaddr values for Peer=> or Local=> params.
# (passthrough of normal params is tested separately, in 10_*.t).
my $addr = IO::Socket::TIPC::Sockaddr->new(Type => 0x73570000 | $$, Instance => 0x73570001);
my $ssock = IO::Socket::TIPC->new(SocketType => 'seqpacket', Listen => 1, Local => $addr);
ok(defined($ssock), "->new() accepted an existing Sockaddr for Local=> param");
if(fork()) {
	# server (and test) process
	my $csock = $ssock->accept();
	$csock->print("does it work?\n");
	my $string = $csock->getline();
	like($string, qr/it works/, "client message got through");
} else {
	# child process
	my $csock = IO::Socket::TIPC->new(SocketType => 'seqpacket', Peer => $addr);
	$csock->print("Yes, it works!\n")
		if $csock->getline() =~ /does it work/;
	exit(0);
}
BEGIN { $tests += 2 };


BEGIN {
	if(IO::Socket::TIPC->detect()) {
		plan tests => $tests;
	} else {
		plan skip_all => 'you need to load the tipc module';
	}
}
