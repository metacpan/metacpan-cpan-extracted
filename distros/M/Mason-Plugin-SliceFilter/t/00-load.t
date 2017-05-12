#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Mason::Plugin::SliceFilter' ) || print "Bail out!\n";
}

diag( "Testing Mason::Plugin::SliceFilter $Mason::Plugin::SliceFilter::VERSION, Perl $], $^X" );
