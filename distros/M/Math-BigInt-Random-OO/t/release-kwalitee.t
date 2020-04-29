#!perl

BEGIN {
    unless ($ENV{RELEASE_TESTING}) {
        print "1..0 # SKIP these tests are for release candidate testing";
        exit;
    }
}

use strict;
use warnings;

use Test::More 0.88;
use Test::Kwalitee 1.21 'kwalitee_ok';

kwalitee_ok();

done_testing;
