#!perl
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Method::Slice' ) || print "Bail out!\n";
}

diag( "Testing Method::Slice $Method::Slice::VERSION, Perl $], $^X" );
