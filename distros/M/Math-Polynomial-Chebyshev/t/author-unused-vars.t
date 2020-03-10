#!perl

BEGIN {
    unless ($ENV{AUTHOR_TESTING}) {
        print "1..0 # SKIP these tests are for author testing";
        exit;
    }
}

use strict;
use warnings;

use Test::Vars;

all_vars_ok();
