#!/bin/env perl

use strict;
use warnings;
no warnings 'once';

use Test::More tests => 4;

use FindBin qw($Bin);
use lib grep { -d } map { "$Bin/$_" } qw(../lib ./lib ./t/lib);
use Hash::MostUtils qw(hashmap n_map);

# hashmap
{
  my @got = hashmap { uc($a) => $b + 100 } (
    revenue     => 10,
    search      => 20,
    contributor => 30,
  );
  is_deeply( \@got, [REVENUE => 110, SEARCH => 120, CONTRIBUTOR => 130], 'hashmap works' );
}

# n_map
{
  my @by_three = Hash::MostUtils::n_map(3, sub { [$::a, $::b, $::c] }, (1..9));
  is_deeply( \@by_three, [[1..3], [4..6], [7..9]], 'can call Hash::MostUtils::n_map directly' );
}

# we don't nuke your existing variables
{
  my ($a, $b, $c, $d) = (1..4);
  hashmap { 1 } ('a'..'z');
  is_deeply( [$a, $b, $c, $d], [1..4], 'hashmap localized variables properly' );

  n_map(7, sub { 1 }, 'a'..'n');
  is_deeply( [$a, $b, $c, $d], [1..4], 'n_map localized variables properly' );
}
