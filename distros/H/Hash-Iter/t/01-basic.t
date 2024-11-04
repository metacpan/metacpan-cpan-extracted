#!perl

use strict;
use warnings;
use Test::More 0.98;

use Hash::Iter qw(hash_iter pair_iter);

subtest hash_iter => sub {
    my $iter = hash_iter({1,2,3,4,5,6});
    my %res; while (my ($k,$v) = $iter->()) { $res{$k} = $v }
    is_deeply(\%res, {1,2,3,4,5,6});
};

subtest pair_iter => sub {
    my $iter = pair_iter(1,2,3,4,5,6);
    my %res; while (my ($k,$v) = $iter->()) { $res{$k} = $v }
    is_deeply(\%res, {1,2,3,4,5,6});
};

done_testing;
