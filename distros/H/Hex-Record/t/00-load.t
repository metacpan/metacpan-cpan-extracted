#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Hex::Record' ) || print "Bail out!\n";
}

diag( "Testing Hex::Record $Hex::Record::VERSION, Perl $], $^X" );
