#!perl -T

use strict;
use warnings;

use Test::Most tests => 1;

BEGIN {
    use_ok( 'Locale::CA' ) || print "Bail out!
";
}

diag( "Testing Locale::CA $Locale::CA::VERSION, Perl $], $^X" );
