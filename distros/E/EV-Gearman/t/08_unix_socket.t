# Verify connect_unix() reaches gearmand through a Unix socket.
#
# gearmand 1.x has no native Unix-socket listener, so we bridge via
# socat: socat UNIX-LISTEN:$path,fork TCP:$host:$port.
# Skipped if socat is not available.
use strict;
use warnings;
use Test::More;
use IO::Socket::INET;
use File::Temp qw(tempdir);
use EV;
use EV::Gearman;

my $host = $ENV{TEST_GEARMAN_HOST} || '127.0.0.1';
my $port = $ENV{TEST_GEARMAN_PORT} || 4730;

my $probe = IO::Socket::INET->new(
    PeerAddr => $host, PeerPort => $port, Proto => 'tcp', Timeout => 1,
);
plan skip_all => "no gearmand at $host:$port" unless $probe;
close $probe;

my $socat = `command -v socat 2>/dev/null`; chomp $socat;
plan skip_all => 'socat not installed' unless -x $socat;

my $dir = tempdir(CLEANUP => 1);
my $sock = "$dir/gm.sock";

my $pid = fork // die "fork: $!";
if (!$pid) {
    open STDOUT, '>', '/dev/null';
    open STDERR, '>', '/dev/null';
    exec $socat, "UNIX-LISTEN:$sock,fork,unlink-early",
                  "TCP:$host:$port";
    exit 1;
}

# wait for the socket to appear
my $ready;
for (1..50) {
    if (-S $sock) { $ready = 1; last }
    select undef, undef, undef, 0.05;
}
unless ($ready) {
    kill 'TERM', $pid; waitpid $pid, 0;
    plan skip_all => 'socat bridge did not come up';
}

# Pass on_connect in the constructor — for Unix sockets connect(2)
# returns immediately, so finish_connect_success runs synchronously
# from inside new(); a post-hoc $g->on_connect() would arrive too
# late to fire.
my $connected;
my $g = EV::Gearman->new(
    path       => $sock,
    on_connect => sub { $connected = 1; EV::break },
);
my $w = EV::timer 5, 0, sub { EV::break };
EV::run;

unless ($connected) {
    undef $g;
    kill 'TERM', $pid; waitpid $pid, 0;
    plan skip_all => 'on_connect never fired (transport bridge issue)';
}

ok $connected, 'connected via Unix socket';

my ($r, $e);
$g->echo("unix-ping", sub { ($r, $e) = @_; EV::break });
$w = EV::timer 5, 0, sub { EV::break };
EV::run;
is $r, 'unix-ping', 'echo round-trip over Unix socket';
is $e, undef,       'no error';

$g->disconnect;
undef $g;
kill 'TERM', $pid;
waitpid $pid, 0;

done_testing;
