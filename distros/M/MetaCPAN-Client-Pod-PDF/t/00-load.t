#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'MetaCPAN::Client::Pod::PDF' ) || print "Bail out!\n";
}

diag( "Testing MetaCPAN::Client::Pod::PDF $MetaCPAN::Client::Pod::PDF::VERSION, Perl $], $^X" );
