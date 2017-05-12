#!perl

BEGIN {
  unless ($ENV{RELEASE_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for release candidate testing');
  }
}


use strict;
use warnings;

use Test::More 0.88 tests => 2;
use MetaCPAN::Helper;

my $helper = MetaCPAN::Helper->new();
ok(defined($helper), "instantiate MetaCPAN::Helper");

my $DIST_NAME = 'Moose';
my $count     = eval { $helper->dist2favorite_count($DIST_NAME) };

ok(
    (!defined $count or !ref($count) and $count =~ /^[0-9]+$/),
    "dist2favorite_count('$DIST_NAME') should return a number or undef value"
);
