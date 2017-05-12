#!/usr/bin/env perl

# by default, this benchmark only runs for CPAN Testers reports. To force it in other environments
# (if App::Benchmark is installed), supply a count/duration argument after the "arisdottle"
# operator (man prove):
#
#     prove -b t/benchmark.t :: -10     # run each benchmark for for 10 seconds
#     prove -b t/benchmark.t :: 1000000 # run each benchmark 1,000,000 times

use strict;
use warnings;

use Test::More;

sub cached_factorial($) {
    use Goto::Cached;
    my $n = shift;
    my $accum = 1;

    iter: return $accum if ($n < 2);
    $accum *= $n;
    --$n;
    goto iter;
}

sub uncached_factorial($) {
    my $n = shift;
    my $accum = 1;

    iter: return $accum if ($n < 2);
    $accum *= $n;
    --$n;
    goto iter;
}

sub loop_factorial($) {
    my $accum = 1;
    my $n = shift;

    while ($n > 1) {
        $accum *= $n;
        --$n;
    }

    return $accum;
}

sub recursive_factorial($);
sub recursive_factorial($) {
    my $n = shift;

    if ($n < 2) {
        return 1;
    } else {
        return $n * recursive_factorial($n - 1);
    }
}

my $N = 15;
my $N_FACTORIAL = 1_307_674_368_000;
my $COUNT = $_[0] || -5;

for (qw(uncached_factorial cached_factorial loop_factorial recursive_factorial)) {
    my $got = __PACKAGE__->can($_)->($N);
    my $want = $N_FACTORIAL;

    unless ($got == $want) {
        plan skip_all => "invalid result for $_: expected $want, got $got";
    }
}

if (not($ENV{PERL_CR_SMOKER_CURRENT}) && not(@ARGV)) {
    plan skip_all => 'not a CPAN Testers Report';
} elsif (not(eval 'use App::Benchmark 1.102310; 1')) {
    plan skip_all => 'App::Benchmark >= 1.102310 is not installed';
} else {
    benchmark_diag($COUNT, {
        uncached_factorial  => sub { uncached_factorial($N) },
        cached_factorial    => sub { cached_factorial($N) },
        loop_factorial      => sub { loop_factorial($N) },
        recursive_factorial => sub { recursive_factorial($N) },
    });
    done_testing();
}
