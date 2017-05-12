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

my $DIST_NAME = 'Moose';
my $releases  = eval { $helper->dist2releases($DIST_NAME) };

ok(
    ($releases and ref($releases) eq 'MetaCPAN::Client::ResultSet'),
    "dist2releases('$DIST_NAME') should return a 'MetaCPAN::Client::ResultSet' object"
);

my $next_release = $releases->next;

ok(
    (!defined($next_release) or ref($next_release) eq 'MetaCPAN::Client::Release'),
    "dist2releases('$DIST_NAME')->next should return a 'MetaCPAN::Client::Release' object"
);
