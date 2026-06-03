# Event storm: a single worker callback emits thousands of WORK_DATA
# events before its terminal WORK_COMPLETE. The active_jobs hash must
# route every event to the right per-job callback under high event
# rate without dropping any.
use strict;
use warnings;
use Test::More;
use IO::Socket::INET;
use EV;
use EV::Gearman;

my $host = $ENV{TEST_GEARMAN_HOST} || '127.0.0.1';
my $port = $ENV{TEST_GEARMAN_PORT} || 4730;
my $probe = IO::Socket::INET->new(
    PeerAddr => $host, PeerPort => $port, Proto => 'tcp', Timeout => 1,
);
plan skip_all => "no gearmand at $host:$port" unless $probe;
close $probe;

my $N = $ENV{STORM_N} || 5000;

my $cli  = EV::Gearman->new(host => $host, port => $port);
my $wkr  = EV::Gearman->new(host => $host, port => $port);
my $func = "storm_$$";

$wkr->register_function($func => { async => 1 }, sub {
    my $job = shift;
    for my $i (1 .. $N) {
        $job->send_data("evt-$i");
    }
    $job->complete("done after $N events");
});
$wkr->work;

my @data;
my ($r, $e);
$cli->submit_job($func, "go", {
    on_data => sub { push @data, $_[0] },
}, sub {
    ($r, $e) = @_; EV::break;
});

my $g = EV::timer 30, 0, sub { fail "storm timeout"; EV::break };
EV::run;

is $e, undef, 'no error';
is $r, "done after $N events", 'terminal result correct';
is scalar @data, $N, "all $N intermediate events delivered";

# Spot-check ordering preserved.
is $data[0],     'evt-1', 'first event correct';
is $data[$N-1],  "evt-$N", 'last event correct';
my $bad = 0;
for my $i (0 .. $#data) {
    $bad++ if $data[$i] ne "evt-".($i+1);
}
is $bad, 0, 'event ordering preserved';

done_testing;
