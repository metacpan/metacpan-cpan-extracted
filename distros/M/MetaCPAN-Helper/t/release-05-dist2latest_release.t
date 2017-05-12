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

my $DIST_NAME      = 'Moose';
my $latest_release = eval { $helper->dist2latest_release($DIST_NAME) };

ok(
    ($latest_release and ref($latest_release) eq 'MetaCPAN::Client::Release'),
    "dist2latest_release('$DIST_NAME') should return a 'MetaCPAN::Client::Release' object"
);
