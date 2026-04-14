#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Enum::Declare' ) || print "Bail out!\n";
}

diag( "Testing Enum::Declare $Enum::Declare::VERSION, Perl $], $^X" );
