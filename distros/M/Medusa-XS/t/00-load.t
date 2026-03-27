#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Medusa::XS' ) || print "Bail out!\n";
}

diag( "Testing Medusa::XS $Medusa::XS::VERSION, Perl $], $^X" );
