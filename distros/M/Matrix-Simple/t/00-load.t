#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Matrix::Simple' ) || print "Bail out!\n";
}

diag( "Testing Matrix::Simple $Matrix::Simple::VERSION, Perl $], $^X" );
