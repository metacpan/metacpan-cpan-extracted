#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use lib ".";
use t::Unrandom;

use List::UtilsBy qw( weighted_shuffle_by );

is_deeply( [ weighted_shuffle_by { } ], [], 'empty list' );

is_deeply( [ weighted_shuffle_by { 1 } "a" ], [ "a" ], 'unit list' );

my @vals = weighted_shuffle_by { 1 } "a", "b", "c";
is_deeply( [ sort @vals ], [ "a", "b", "c" ], 'set of return values' );

my %got;
unrandomly {
   my $order = join "",
               weighted_shuffle_by { { a => 1, b => 2, c => 3 }->{$_} }
               qw( a b c );
   $got{$order}++;
};

my %expect = (
   'abc' => 1 * 2,
   'acb' => 1 * 3,
   'bac' => 2 * 1,
   'bca' => 2 * 3,
   'cab' => 3 * 1,
   'cba' => 3 * 2,
);

is_deeply( \%got, \%expect, 'Got correct distribution of ordering counts' );

done_testing;
