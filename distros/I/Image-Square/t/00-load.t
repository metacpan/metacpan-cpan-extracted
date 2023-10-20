#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Image::Square' ) || print "Bail out!\n";
}

diag( "Testing Image::Square $Image::Square::VERSION, Perl $], $^X" );
