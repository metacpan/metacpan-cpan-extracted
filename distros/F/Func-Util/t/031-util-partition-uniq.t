#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

use Func::Util;

# Test partition - returns [$matching, $non_matching]
my @nums = (1, 2, 3, 4, 5, 6, 7, 8, 9, 10);
my $result = Func::Util::partition(sub { $_ % 2 == 0 }, @nums);
is_deeply($result->[0], [2, 4, 6, 8, 10], 'partition: evens');
is_deeply($result->[1], [1, 3, 5, 7, 9], 'partition: odds');

my $result2 = Func::Util::partition(sub { $_ > 0 }, -2, -1, 0, 1, 2);
is_deeply($result2->[0], [1, 2], 'partition: positive');
is_deeply($result2->[1], [-2, -1, 0], 'partition: non-positive');

# Test uniq
my @with_dups = (1, 2, 2, 3, 3, 3, 4, 4, 4, 4);
my @unique = Func::Util::uniq(@with_dups);
is_deeply(\@unique, [1, 2, 3, 4], 'uniq: removes duplicates');

my @strings = ('a', 'b', 'a', 'c', 'b', 'a');
my @unique_strings = Func::Util::uniq(@strings);
is_deeply(\@unique_strings, ['a', 'b', 'c'], 'uniq: removes string duplicates');

done_testing();
