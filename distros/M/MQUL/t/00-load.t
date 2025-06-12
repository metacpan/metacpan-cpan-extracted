#!/usr/bin/env perl

use lib './lib';
use Test2::V0;

BEGIN {
    use ok 'MQUL' || print "Bail out!\n";
}

diag("Testing MQUL $MQUL::VERSION, Perl $], $^X");

done_testing();
