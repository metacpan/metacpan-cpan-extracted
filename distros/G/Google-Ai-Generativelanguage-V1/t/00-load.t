#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Google::Ai::Generativelanguage::V1' ) || print "Bail out!\n";
}

diag( "Testing Google::Ai::Generativelanguage::V1 $Google::Ai::Generativelanguage::V1::VERSION, Perl $], $^X" );
