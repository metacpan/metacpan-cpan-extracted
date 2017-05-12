#!/bin/env perl

use strict;
use warnings;

use Test::More tests => 2;

use FindBin qw($Bin);
use lib grep { -d } map { "$Bin/$_" } qw(../lib ./lib ./t/lib);
use Hash::MostUtils qw(lvalues lkeys);

# perl's built-in values() function only operates on hashes. lvalues() acts like values(), but for lists.
{
  my @list_values = lvalues 1..10;
  is_deeply( \@list_values, [2, 4, 6, 8, 10], 'lvalues returns list values' );
}

# same gripe but with keys()
{
  my @list_keys = lkeys 1..10;
  is_deeply( \@list_keys, [1, 3, 5, 7, 9], 'lkeys returns list keys' );
}
