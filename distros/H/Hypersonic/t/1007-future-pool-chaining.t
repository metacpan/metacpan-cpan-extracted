#!/usr/bin/env perl
use strict;
use warnings;

# Load and compile Future/Pool BEFORE Test::More
use Hypersonic::Future;
use Hypersonic::Future::Pool;
Hypersonic::Future->compile();

use Test::More;
plan skip_all => "Hypersonic::Future / ::Pool not supported on native Win32 (POSIX pthread + self-pipe)" if $^O eq "MSWin32";

# Create and init pool (OO API)
my $pool = Hypersonic::Future::Pool->new(workers => 4);
$pool->init;

# Wait for a future to become done/failed, processing pool readiness as we
# go. Pre-0.18 these tests just called `select undef,undef,undef,0.1` once
# and then `$pool->process_ready` once - that's flaky on slow CPAN smokers
# (the perl 5.18.4 DCANTRELL smoker reported "Future is not done at line 80"
# for exactly this reason: the worker thread hadn't published its result yet
# when the parent ran process_ready). Poll up to PERL_TEST_TIME_OUT_FACTOR
# * 10 seconds in 20ms slices; that's enough headroom for any sane smoker
# while still failing fast on a real bug.
sub wait_for_future {
    my ($f, %opts) = @_;
    my $factor = $ENV{PERL_TEST_TIME_OUT_FACTOR};
    $factor = 1 unless defined $factor && $factor =~ /^\d+(?:\.\d+)?$/ && $factor > 0;
    my $deadline = ($opts{timeout} // 10) * $factor;
    my $slice    = 0.02;
    my $waited   = 0;
    while ($waited < $deadline) {
        $pool->process_ready;
        return 1 if $f->is_done || $f->is_failed;
        select undef, undef, undef, $slice;
        $waited += $slice;
    }
    # One last pump in case readiness arrived during the final sleep.
    $pool->process_ready;
    return $f->is_done || $f->is_failed;
}

# Test chaining with pool - then
{
    my $f = Hypersonic::Future->new;
    my $chained_result;

    my $chain = $f->then(sub {
        my ($val) = @_;
        $chained_result = $val * 10;
        return $chained_result;
    });

    $pool->submit($f, sub {
        return 5;
    }, []);

    wait_for_future($chain);

    ok($f->is_done, 'Original future done');
    ok($chain->is_done, 'Chained future done');
    is($chained_result, 50, 'Chained callback executed with result');
    my @r = $chain->result;
    is($r[0], 50, 'Chain has transformed result');
}

# Test multiple then chains
{
    my $f = Hypersonic::Future->new;

    my $chain = $f
        ->then(sub { $_[0] * 2 })
        ->then(sub { $_[0] + 10 })
        ->then(sub { $_[0] . '!' });

    $pool->submit($f, sub {
        return 5;
    }, []);

    wait_for_future($chain);

    ok($chain->is_done, 'Multi-chain completed');
    is($chain->result, '20!', '(5 * 2) + 10 = 20, then "20!"');
}

# Test finally with pool
{
    my $f = Hypersonic::Future->new;
    my $finally_ran = 0;

    my $chain = $f->finally(sub {
        $finally_ran = 1;
    });

    $pool->submit($f, sub {
        return 'success';
    }, []);

    wait_for_future($chain);

    ok($finally_ran, 'Finally ran');
    ok($chain->is_done, 'Chain preserves success');
    is($chain->result, 'success', 'Result preserved through finally');
}

# Test finally on failure
{
    my $f = Hypersonic::Future->new;
    my $finally_ran = 0;

    my $chain = $f->finally(sub {
        $finally_ran = 1;
    });

    $pool->submit($f, sub {
        die "error";
    }, []);

    wait_for_future($chain);

    ok($finally_ran, 'Finally ran on failure');
    ok($chain->is_failed, 'Chain preserves failure');
}

$pool->shutdown;

done_testing;
