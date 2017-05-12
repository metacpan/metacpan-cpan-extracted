use strict;
use warnings;
use Test::More;

BEGIN {
    eval "use IO::Socket::INET;";
    if ($@) {
        plan skip_all => "No IO::Socket::INET installed";
        exit(0);
    }
    if (!$ENV{LOG_HANDLER_SOCK_TEST}) {
        plan skip_all => "Set \$ENV{LOG_HANDLER_SOCK_TEST} to 1 to enable this test";
        exit(0);
    }
};

use Log::Handler::Output::Socket;
use IO::Socket::INET;

eval {
    $SIG{ALRM} = sub { die "STOP TEST" };
    alarm 60;
};

my $sock = IO::Socket::INET->new(
    LocalAddr => "127.0.0.1",
    Proto     => "tcp",
    Listen    => 1,
    Timeout   => 15
) or die $!;

my $port = $sock->sockport;
my $pid  = fork;

if (!$pid) {
    my $r = $sock->accept;
    my $m = <$r> || "empty";
    if ($m ne "test message from logger") {
        die "something wents wrong ($m)";
    }
    $sock->close;
    waitpid($pid, 0);
    exit(0);
}

$sock->close;
sleep 1;
plan tests => 4;
ok(1, "fork");

my $log = Log::Handler::Output::Socket->new(
    peeraddr    => "127.0.0.1",
    peerport    => $port,
    proto       => "tcp",
    timeout     => 15,
    persistent  => 0,
    reconnect   => 0,
);

ok(1, "new");

$log->log(message => "test message from logger") or do {
    ok(0, "testing log() - ".$log->errstr);
};

ok(1, "testing log()");

$log->reload(
    {
        peeraddr    => "localhost",
        peerport    => $port,
        proto       => "tcp",
        timeout     => 15,
        persistent  => 0,
        reconnect   => 0,
    }
);

ok($log->{sockopts}->{PeerAddr} eq "localhost", "checking reload ($log->{sockopts}->{PeerAddr})");
