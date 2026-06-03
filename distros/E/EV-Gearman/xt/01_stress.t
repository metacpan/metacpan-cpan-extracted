# Stress: many concurrent foreground submissions, single connection.
# Verifies that pipelining + handle-routing handle large in-flight
# windows without dropping responses.
use strict;
use warnings;
use Test::More;
use IO::Socket::INET;
use EV;
use EV::Gearman;
use Time::HiRes qw(time);

my $host = $ENV{TEST_GEARMAN_HOST} || '127.0.0.1';
my $port = $ENV{TEST_GEARMAN_PORT} || 4730;

my $probe = IO::Socket::INET->new(
    PeerAddr => $host, PeerPort => $port,
    Proto => 'tcp', Timeout => 1,
);
plan skip_all => "no gearmand at $host:$port" unless $probe;
close $probe;

my $N = $ENV{STRESS_N} || 5_000;

my $cli = EV::Gearman->new(host => $host, port => $port);
my $wkr = EV::Gearman->new(host => $host, port => $port);
$wkr->register_function('xt_stress_'.$$ => sub { uc $_[0]->workload });
$wkr->work;

my %seen;
my $remaining = $N;
my $had_err = 0;

my $start = time;
for my $i (1 .. $N) {
    $cli->submit_job('xt_stress_'.$$, "v$i", sub {
        my ($r, $e) = @_;
        $had_err++ if $e;
        $seen{$i} = $r if defined $r;
        EV::break if --$remaining == 0;
    });
}
my $guard = EV::timer 30, 0, sub { fail "stress timeout"; EV::break };
EV::run;
my $dt = time - $start;

is $had_err, 0, "no errors in $N jobs";
is scalar(keys %seen), $N, "all $N callbacks fired";

my $bad = 0;
for my $i (1 .. $N) {
    $bad++ if !defined $seen{$i} || $seen{$i} ne uc "v$i";
}
is $bad, 0, "all results correct";

diag sprintf "stress: %d jobs in %.2fs (%.0f rps)", $N, $dt, $N/$dt;
done_testing;
