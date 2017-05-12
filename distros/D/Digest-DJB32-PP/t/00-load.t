#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Digest::DJB32::PP' ) || print "Bail out!\n";
}

diag( "Testing Digest::DJB32::PP $Digest::DJB32::PP::VERSION, Perl $], $^X" );
