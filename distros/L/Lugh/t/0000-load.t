#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Lugh' ) || print "Bail out!\n";
}

diag( "Testing Lugh $Lugh::VERSION, Perl $], $^X" );
