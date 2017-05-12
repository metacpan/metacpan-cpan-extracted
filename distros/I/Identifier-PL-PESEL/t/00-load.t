#!perl -T

use strict;
use warnings;

use Test::More tests => 1;

BEGIN {
    use_ok( 'Identifier::PL::PESEL' ) || print "Bail out!\n";
}

diag( "Testing Identifier::PL::PESEL $Identifier::PL::PESEL::VERSION, Perl $], $^X" );
