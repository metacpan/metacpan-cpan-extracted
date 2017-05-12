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

my $MODULE_NAME        = 'Module::Path';
my $EXPECTED_DIST_NAME = 'Module-Path';

my $distname           = eval { $helper->module2dist($MODULE_NAME); };

ok(defined($distname) && $distname eq $EXPECTED_DIST_NAME,
   "module2dist('$MODULE_NAME') should return '$EXPECTED_DIST_NAME'");
