#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Import::Export' ) || print "Bail out!\n";
}

diag( "Testing Import::Export $Import::Export::VERSION, Perl $], $^X" );
