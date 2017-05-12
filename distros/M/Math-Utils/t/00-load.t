#!perl -T
use 5.010001;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Math::Utils' ) || print "Bail out!\n";
}

diag( "Testing Math::Utils $Math::Utils::VERSION, Perl $], $^X" );
