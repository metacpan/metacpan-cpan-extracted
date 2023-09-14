#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'FixerIO::API' ) || print "Bail out!\n";
}

diag( "Testing FixerIO::API $FixerIO::API::VERSION, Perl $], $^X" );
