#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Future::Batch' ) || print "Bail out!\n";
}

diag( "Testing Future::Batch $Future::Batch::VERSION, Perl $], $^X" );
