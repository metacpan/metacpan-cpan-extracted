#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

BEGIN {
    eval { require Test::LeakTrace };
    plan skip_all => 'Test::LeakTrace required' if $@;
}
use Test::LeakTrace;

use Func::Util qw(
    array_len array_first array_last
    hash_size
    uniq partition
    pick omit pluck defaults
    is_empty is_empty_array is_empty_hash
);

# Warmup
for (1..10) {
    array_len([1,2,3]);
    hash_size({a=>1});
}

subtest 'array_len' => sub {
    my $arr = [1, 2, 3, 4, 5];
    no_leaks_ok {
        for (1..1000) {
            my $r = array_len($arr);
        }
    } 'array_len does not leak';
};

subtest 'array_first and array_last' => sub {
    my $arr = [1, 2, 3, 4, 5];
    no_leaks_ok {
        for (1..1000) {
            my $r = array_first($arr);
            my $r2 = array_last($arr);
        }
    } 'array_first/last do not leak';
};

subtest 'hash_size' => sub {
    my $hash = {a => 1, b => 2, c => 3};
    no_leaks_ok {
        for (1..1000) {
            my $r = hash_size($hash);
        }
    } 'hash_size does not leak';
};

subtest 'uniq' => sub {
    my @arr = (1, 2, 2, 3, 3, 3, 4, 4, 4, 4);
    no_leaks_ok {
        for (1..500) {
            my @r = uniq(@arr);
        }
    } 'uniq does not leak';
};

subtest 'partition' => sub {
    my $arr = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
    no_leaks_ok {
        for (1..500) {
            my ($evens, $odds) = partition(sub { $_ % 2 == 0 }, $arr);
        }
    } 'partition does not leak';
};

subtest 'pick' => sub {
    my $hash = {a => 1, b => 2, c => 3, d => 4};
    no_leaks_ok {
        for (1..500) {
            my $r = pick($hash, 'a', 'c');
        }
    } 'pick does not leak';
};

subtest 'omit' => sub {
    my $hash = {a => 1, b => 2, c => 3, d => 4};
    no_leaks_ok {
        for (1..500) {
            my $r = omit($hash, 'b', 'd');
        }
    } 'omit does not leak';
};

subtest 'pluck' => sub {
    my $users = [
        {name => 'alice', age => 30},
        {name => 'bob', age => 25},
        {name => 'charlie', age => 35},
    ];
    no_leaks_ok {
        for (1..500) {
            my @names = pluck($users, 'name');
        }
    } 'pluck does not leak';
};

subtest 'defaults' => sub {
    my $partial = {a => 1, b => 2};
    my $defaults = {b => 99, c => 3, d => 4};
    no_leaks_ok {
        for (1..500) {
            my $r = defaults($partial, $defaults);
        }
    } 'defaults does not leak';
};

subtest 'is_empty checks' => sub {
    my $empty_arr = [];
    my $empty_hash = {};
    my $non_empty_arr = [1];
    my $non_empty_hash = {a => 1};

    no_leaks_ok {
        for (1..1000) {
            my $r1 = is_empty("");
            my $r2 = is_empty("x");
            my $r3 = is_empty_array($empty_arr);
            my $r4 = is_empty_array($non_empty_arr);
            my $r5 = is_empty_hash($empty_hash);
            my $r6 = is_empty_hash($non_empty_hash);
        }
    } 'is_empty checks do not leak';
};

done_testing();
