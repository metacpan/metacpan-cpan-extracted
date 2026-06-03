# Per-job event routing under interleaving: multiple foreground jobs
# active at once, each emitting WORK_DATA / WORK_STATUS in arbitrary
# order. The handle-keyed active_jobs hash must route every event
# to the right per-job callbacks.
use strict;
use warnings;
use Test::More;
use IO::Socket::INET;
use EV;
use EV::Gearman;

my $host = $ENV{TEST_GEARMAN_HOST} || '127.0.0.1';
my $port = $ENV{TEST_GEARMAN_PORT} || 4730;

my $probe = IO::Socket::INET->new(
    PeerAddr => $host, PeerPort => $port,
    Proto => 'tcp', Timeout => 1,
);
plan skip_all => "no gearmand at $host:$port" unless $probe;
close $probe;

# 4 worker connections to ensure jobs run in parallel
my @wkrs;
for (1..4) {
    my $w = EV::Gearman->new(host => $host, port => $port);
    $w->register_function('xt_route_'.$$ => sub {
        my $job = shift;
        my $tag = $job->workload;
        # Send a fixed sequence of events tagged with the workload
        $job->send_data("$tag-data1");
        $job->status(1, 4);
        $job->send_data("$tag-data2");
        $job->warning("$tag-warn");
        $job->status(3, 4);
        return "$tag-final";
    });
    $w->work;
    push @wkrs, $w;
}

my $cli = EV::Gearman->new(host => $host, port => $port);

my $N = 20;
my %tags;
for my $i (1 .. $N) {
    my $tag = "tag$i";
    $tags{$tag} = { data => [], warn => [], status => [], result => undef, err => undef };
    $cli->submit_job('xt_route_'.$$, $tag, {
        on_data    => sub { push @{ $tags{$tag}{data}   }, $_[0] },
        on_warning => sub { push @{ $tags{$tag}{warn}   }, $_[0] },
        on_status  => sub { push @{ $tags{$tag}{status} }, [@_]  },
    }, sub {
        $tags{$tag}{result} = $_[0];
        $tags{$tag}{err}    = $_[1];
    });
}

# Wait for all to finish
my $done = 0;
my $check = EV::timer 0.05, 0.05, sub {
    $done = grep { defined $tags{$_}{result} || defined $tags{$_}{err} } keys %tags;
    EV::break if $done == $N;
};
my $g = EV::timer 30, 0, sub { fail "routing timeout"; EV::break };
EV::run;

is $done, $N, "all $N jobs delivered terminal events";

my $bad = 0;
for my $i (1 .. $N) {
    my $tag = "tag$i";
    my $t = $tags{$tag};
    if ($t->{err}) { $bad++; next }
    next if @{$t->{data}}   == 2
         && $t->{data}[0]   eq "$tag-data1"
         && $t->{data}[1]   eq "$tag-data2"
         && @{$t->{warn}}   == 1
         && $t->{warn}[0]   eq "$tag-warn"
         && @{$t->{status}} == 2
         && $t->{result}    eq "$tag-final";
    diag "BAD $tag: ", explain $t;
    $bad++;
}
is $bad, 0, "all $N event sequences correctly routed";

done_testing;
