#!perl

BEGIN {
    unless ($ENV{AUTHOR_TESTING}) {
        print "1..0 # SKIP these tests are for author testing";
        exit;
    }
}

use strict;
use warnings;

use Test::Synopsis;

all_synopsis_ok();
