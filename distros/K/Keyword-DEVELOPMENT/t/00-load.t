#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Keyword::DEVELOPMENT' ) || print "Bail out!\n";
}

diag( "Testing Keyword::DEVELOPMENT $Keyword::DEVELOPMENT::VERSION, Perl $], $^X" );
