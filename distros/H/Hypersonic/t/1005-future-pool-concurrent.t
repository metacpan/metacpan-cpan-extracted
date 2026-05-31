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

# Test multiple concurrent operations
{
    my @futures;
    for my $i (1..5) {
        my $f = Hypersonic::Future->new;
        $pool->submit($f, sub {
            my ($n) = @_;
            return $n * 2;
        }, [$i]);
        push @futures, $f;
    }

    select(undef, undef, undef, 0.2);
    $pool->process_ready;

    for my $i (0..4) {
        ok($futures[$i]->is_done, "Future $i is done");
        my @r = $futures[$i]->result;
        is($r[0], ($i+1) * 2, "Future $i has result " . (($i+1) * 2));
    }
}

# Test many concurrent operations
{
    my @futures;
    my $count = 20;

    for my $i (1..$count) {
        my $f = Hypersonic::Future->new;
        $pool->submit($f, sub {
            my ($n) = @_;
            return $n * $n;
        }, [$i]);
        push @futures, $f;
    }

    # Wait and process multiple times to ensure all complete
    for (1..3) {
        select(undef, undef, undef, 0.1);
        $pool->process_ready;
    }

    my $done_count = 0;
    for my $i (0..$count-1) {
        if ($futures[$i]->is_done) {
            $done_count++;
            my @r = $futures[$i]->result;
            is($r[0], ($i+1) ** 2, "Future $i has squared result");
        }
    }
    is($done_count, $count, "All $count futures completed");
}

$pool->shutdown;

done_testing;
