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

    select(undef, undef, undef, 0.1);
    $pool->process_ready;

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

    select(undef, undef, undef, 0.1);
    $pool->process_ready;

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

    select(undef, undef, undef, 0.1);
    $pool->process_ready;

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

    select(undef, undef, undef, 0.1);
    $pool->process_ready;

    ok($finally_ran, 'Finally ran on failure');
    ok($chain->is_failed, 'Chain preserves failure');
}

$pool->shutdown;

done_testing;
