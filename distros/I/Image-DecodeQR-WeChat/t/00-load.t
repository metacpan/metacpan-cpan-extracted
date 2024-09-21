#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

our $VERSION = '2.2';

BEGIN {
    use_ok( 'Image::DecodeQR::WeChat' ); # || print "Bail out!\n";
    can_ok( 'Image::DecodeQR::WeChat', 'modelsdir'); # || print "Bail out!\n";
    can_ok( 'Image::DecodeQR::WeChat', 'opencv_has_highgui_xs'); # || print "Bail out!\n";
    can_ok( 'Image::DecodeQR::WeChat', 'detect_and_decode_qr'); # || print "Bail out!\n";
    can_ok( 'Image::DecodeQR::WeChat', 'detect_and_decode_qr_xs'); # || print "Bail out!\n";
}

diag( "Testing Image::DecodeQR::WeChat $Image::DecodeQR::WeChat::VERSION, Perl $], $^X" );

done_testing;
