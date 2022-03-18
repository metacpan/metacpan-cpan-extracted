#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

our $VERSION = '0.8';

BEGIN {
    use_ok( 'Image::DecodeQR::WeChat' ); # || print "Bail out!\n";
    can_ok( 'Image::DecodeQR::WeChat', 'decode'); # || print "Bail out!\n";
}

diag( "Testing Image::DecodeQR::WeChat $Image::DecodeQR::WeChat::VERSION, Perl $], $^X" );

done_testing;
