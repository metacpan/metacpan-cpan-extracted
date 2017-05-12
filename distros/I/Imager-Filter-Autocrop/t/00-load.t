#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Imager::Filter::Autocrop' ) || print "Bail out!\n";
}

diag( "Testing Imager::Filter::Autocrop $Imager::Filter::Autocrop::VERSION, Perl $], $^X" );
