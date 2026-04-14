#!perl
use 5.014;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Enum::Declare::Common' ) || print "Bail out!\n";
}

diag( "Testing Enum::Declare::Common $Enum::Declare::Common::VERSION, Perl $], $^X" );
