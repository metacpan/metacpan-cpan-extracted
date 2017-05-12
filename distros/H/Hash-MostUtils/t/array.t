#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 1;

use FindBin qw($Bin);
use lib grep { -d } map { "$Bin/$_" } qw(../lib ./lib ./t/lib);
use Hash::MostUtils qw(reindex);

# reindex
{
  my @start = (1..5);
  my @reindex = reindex { map { $_ => $_ + 1 } 0..$#start } @start;
  is_deeply( \@reindex, [undef, 1..5] );
}
