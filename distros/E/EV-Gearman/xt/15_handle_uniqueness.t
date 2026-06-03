# Sanity: gearmand assigns distinct handles to distinct submissions
# (without `unique`). 10k handles, all unique. Pins the contract that
# our active_jobs hash relies on for routing.
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

my $N = $ENV{HANDLES_N} || 10_000;

my $cli = EV::Gearman->new(host => $host, port => $port);

my %handles;
my $remaining = $N;
my $err_count = 0;
for my $i (1 .. $N) {
    $cli->submit_job_bg('handle_uniq_'.$$, "v$i", sub {
        my ($h, $e) = @_;
        $err_count++ if $e;
        $handles{$h}++ if defined $h;
        EV::break unless --$remaining;
    });
}
my $g = EV::timer 60, 0, sub { fail "uniq handles timeout"; EV::break };
EV::run;

is $err_count, 0, "no errors among $N submissions";
is scalar(keys %handles), $N, "all $N handles distinct";
my $dups = grep { $_ > 1 } values %handles;
is $dups, 0, 'no duplicate handles';

done_testing;
