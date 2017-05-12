#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Image::Imlib2::Thumbnail::Scaled' ) || print "Bail out!\n";
}

diag( "Testing Image::Imlib2::Thumbnail::Scaled $Image::Imlib2::Thumbnail::Scaled::VERSION, Perl $], $^X" );
