#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Locked::Storage' ) || print "Bail out!\n";
}

diag( "Testing Locked::Storage $Locked::Storage::VERSION, Perl $], $^X" );
