#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Func::Util' ) || print "Bail out!\n";
}

diag( "Testing Func::Util $Func::Util::VERSION, Perl $], $^X" );
