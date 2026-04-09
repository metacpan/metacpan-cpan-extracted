#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use LRU::Cache;

# Test lru functions with various loop variable patterns

subtest 'for with $key' => sub {
    my $cache = LRU::Cache->new(10);

    for my $key ('a', 'b', 'c') {
        $cache->set($key, ord($key));
    }

    my @result;
    for my $key ('a', 'b', 'c') {
        push @result, $cache->get($key);
    }
    is_deeply(\@result, [97, 98, 99], 'lru with $key');
};

subtest 'map with "key$_"' => sub {
    my $cache = LRU::Cache->new(10);

    for (1..5) {
        $cache->set("key$_", $_ * 10);
    }

    my @keys = map { "key$_" } (1..5);
    my @values = map { $cache->get($_) } @keys;
    is_deeply(\@values, [10, 20, 30, 40, 50], 'lru with interpolated keys');
};

subtest 'for with $item hashref' => sub {
    my $cache = LRU::Cache->new(10);
    my @items = (
        { key => 'x', val => 100 },
        { key => 'y', val => 200 },
        { key => 'z', val => 300 },
    );

    for my $item (@items) {
        $cache->set($item->{key}, $item->{val});
    }

    my $sum = 0;
    for my $item (@items) {
        $sum += $cache->get($item->{key});
    }
    is($sum, 600, 'lru with $item hashref');
};

subtest 'for with $k' => sub {
    my $cache = LRU::Cache->new(10);
    my @keys = qw(alpha beta gamma);

    for my $k (@keys) {
        $cache->set($k, length($k));
    }

    my @lens;
    for my $k (@keys) {
        push @lens, $cache->get($k);
    }
    is_deeply(\@lens, [5, 4, 5], 'lru with $k');
};

subtest 'nested with $outer/$inner' => sub {
    my $cache = LRU::Cache->new(20);

    for my $outer (1..2) {
        for my $inner ('a', 'b', 'c') {
            my $key = "$outer$inner";
            $cache->set($key, $outer * ord($inner));
        }
    }

    my @result;
    for my $outer (1..2) {
        my @row;
        for my $inner ('a', 'b', 'c') {
            my $key = "$outer$inner";
            push @row, $cache->get($key);
        }
        push @result, \@row;
    }
    is_deeply($result[0], [97, 98, 99], 'nested row 1');
    is_deeply($result[1], [194, 196, 198], 'nested row 2');
};

subtest 'grep with $_' => sub {
    my $cache = LRU::Cache->new(10);
    $cache->set("num$_", $_) for (1..10);

    my @keys = map { "num$_" } (1..10);
    my @even_keys = grep { $cache->get($_) % 2 == 0 } @keys;
    is(scalar(@even_keys), 5, 'grep on cached values');
};

subtest 'for with $n numeric' => sub {
    my $cache = LRU::Cache->new(10);

    for my $n (10, 20, 30, 40, 50) {
        $cache->set("val$n", $n * 2);
    }

    my $sum = 0;
    for my $n (10, 20, 30, 40, 50) {
        $sum += $cache->get("val$n");
    }
    is($sum, 300, 'lru with $n numeric');
};

subtest 'while with $_' => sub {
    my $cache = LRU::Cache->new(10);
    my @keys = qw(one two three);
    my $i = 0;
    while ($i < @keys) {
        local $_ = $keys[$i];
        $cache->set($_, $i + 1);
        $i++;
    }

    my @vals;
    for (@keys) {
        push @vals, $cache->get($_);
    }
    is_deeply(\@vals, [1, 2, 3], 'lru in while with $_');
};

done_testing();
