#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Future::Batch::XS' ) || print "Bail out!\n";
}

diag( "Testing Future::Batch::XS $Future::Batch::XS::VERSION, Perl $], $^X" );
