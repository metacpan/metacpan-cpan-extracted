#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'HTML::CruftText' ) || print "Bail out!\n";
}

diag( "Testing HTML::CruftText $HTML::CruftText::VERSION, Perl $], $^X" );
