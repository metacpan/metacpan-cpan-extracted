# Spawn a private gearmand on a free TCP port and verify a basic
# round-trip survives transport setup outside the shared CI gearmand.
# Real Unix-socket coverage lives in t/08_unix_socket.t (uses socat).
#
# Skipped unless gearmand is in $PATH.
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use EV;
use EV::Gearman;

my $gearmand;
for my $dir (split(/:/, $ENV{PATH}), '/usr/sbin', '/usr/local/sbin') {
    next unless $dir;
    my $exe = "$dir/gearmand";
    if (-f $exe && -x $exe) { $gearmand = $exe; last }
}
plan skip_all => 'gearmand not found' unless $gearmand;

# gearmand only listens on TCP by default. We can't easily make it
# listen on Unix sockets in ad-hoc mode without protocol version
# inspection — fall back to a plain TCP test on a unique port.
my $port = 19000 + ($$ % 1000);

my $pid = fork;
die "fork: $!" unless defined $pid;
if (!$pid) {
    close STDIN; close STDOUT; close STDERR;
    exec $gearmand, '--port', $port, '--listen', '127.0.0.1', '-t', 1;
    exit 1;
}

# wait for gearmand to be ready
sleep 1;
my $ok = 0;
for (1..20) {
    require IO::Socket::INET;
    my $s = IO::Socket::INET->new(
        PeerAddr => "127.0.0.1:$port", Timeout => 1,
    );
    if ($s) { close $s; $ok = 1; last }
    select undef, undef, undef, 0.2;
}
unless ($ok) {
    kill 'TERM', $pid; waitpid $pid, 0;
    plan skip_all => "spawned gearmand not reachable";
}

my $cli = EV::Gearman->new(host => '127.0.0.1', port => $port);
my $wkr = EV::Gearman->new(host => '127.0.0.1', port => $port);
$wkr->register_function('xt_local_'.$$ => sub { lc $_[0]->workload });
$wkr->work;

my ($r, $e);
$cli->submit_job('xt_local_'.$$, "HELLO", sub { ($r, $e) = @_; EV::break });
my $g = EV::timer 5, 0, sub { fail "spawned timeout"; EV::break };
EV::run;
is $r, 'hello', 'spawned gearmand round-trip works';
is $e, undef, 'no error';

undef $cli; undef $wkr;
kill 'TERM', $pid;
waitpid $pid, 0;

done_testing;
