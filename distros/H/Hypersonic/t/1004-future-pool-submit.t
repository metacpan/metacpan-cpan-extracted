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

# Test simple submit and process
{
    my $f = Hypersonic::Future->new;
    ok(!$f->is_ready, 'Future starts pending');

    $pool->submit($f, sub {
        my ($a, $b) = @_;
        return $a + $b;
    }, [10, 20]);

    # Give worker thread time to move it to completed queue
    select(undef, undef, undef, 0.1);

    my $processed = $pool->process_ready;
    ok($processed >= 1, "Processed $processed operations");

    ok($f->is_done, 'Future is done after processing');
    my @result = $f->result;
    is($result[0], 30, 'Future has correct result (10 + 20 = 30)');
}

# Test submit with no args
{
    my $f = Hypersonic::Future->new;

    $pool->submit($f, sub {
        return 'no args';
    });

    select(undef, undef, undef, 0.1);
    $pool->process_ready;

    ok($f->is_done, 'Future done with no args');
    is($f->result, 'no args', 'Result correct');
}

# Test submit returning multiple values
{
    my $f = Hypersonic::Future->new;

    $pool->submit($f, sub {
        return ('a', 'b', 'c');
    }, []);

    select(undef, undef, undef, 0.1);
    $pool->process_ready;

    ok($f->is_done, 'Future done');
    my @r = $f->result;
    is_deeply(\@r, ['a', 'b', 'c'], 'Multiple return values preserved');
}

$pool->shutdown;

done_testing;
