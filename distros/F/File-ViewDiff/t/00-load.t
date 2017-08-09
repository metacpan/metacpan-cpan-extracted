#!perl -T
use strict;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'File::ViewDiff' ) || print "Bail out!\n";
}

diag( "Testing File::ViewDiff $File::ViewDiff::VERSION, Perl $], $^X" );
