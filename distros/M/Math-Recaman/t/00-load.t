#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Math::Recaman' ) || print "Bail out!\n";
}

diag( "Testing Math::Recaman $Math::Recaman::VERSION, Perl $], $^X" );
