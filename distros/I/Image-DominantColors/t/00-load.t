#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Image::DominantColors' ) || print "Bail out!\n";
}

diag( "Testing Image::DominantColors $Image::DominantColors::VERSION, Perl $], $^X" );
