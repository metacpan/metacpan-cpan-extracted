#!perl

BEGIN {
  unless ($ENV{RELEASE_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for release candidate testing');
  }
}


use strict;
use warnings;

use Test::More 0.88 tests => 3;
use MetaCPAN::Helper;

my $helper = MetaCPAN::Helper->new();
ok(defined($helper), "instantiate MetaCPAN::Helper");

{
    my $RELEASE_NAME = 'Moose';
    my $repo         = eval { $helper->release2repo($RELEASE_NAME) };

    ok(
        (!defined $repo or !ref($repo)),
        "release2repo('$RELEASE_NAME') should return a scalar value"
    );
}

{
    my $DIST_NAME = 'Moose';
    my $repo      = eval { $helper->dist2repo($DIST_NAME) };

    ok(
        (!defined $repo or !ref($repo)),
        "dist2repo('$DIST_NAME') should return a scalar value"
    );
}
