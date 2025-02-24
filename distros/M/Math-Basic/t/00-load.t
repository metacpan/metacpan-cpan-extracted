#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Math::Basic' ) || print "Bail out!\n";
}

diag( "Testing Math::Basic $Math::Basic::VERSION, Perl $], $^X" );
