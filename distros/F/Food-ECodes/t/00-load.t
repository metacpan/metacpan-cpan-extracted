#!perl

use strict; use warnings;
use Test::More tests => 2;

BEGIN {
    use_ok('Food::ECodes')           || print "Bail out!";
    use_ok('Food::ECodes::Additive') || print "Bail out!";
}

diag( "Testing Food::ECodes $Food::ECodes::VERSION, Perl $], $^X" );
