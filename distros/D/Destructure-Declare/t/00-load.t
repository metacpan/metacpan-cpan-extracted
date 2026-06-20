#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Destructure::Declare' ) || print "Bail out!\n";
}

diag( "Testing Destructure::Declare $Destructure::Declare::VERSION, Perl $], $^X" );
