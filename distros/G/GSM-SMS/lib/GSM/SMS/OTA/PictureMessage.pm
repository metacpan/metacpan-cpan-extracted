package GSM::SMS::OTA::PictureMessage;

=head1 NAME

GSM::SMS::OTA::PictureMessage - Create a PictureMessage 

=head1 DESCRIPTION

This package implements the creation of a Picture Message. A Picture message
contains a text and an image. I'm not sure about the size of this image, but is seems it can be either 14 or 28 pixels in height. SO this is what we support.

=cut


use strict;
use vars qw($VERSION $PORT);

use base qw( Exporter );
use GSM::SMS::OTA::Bitmap;

# For compatibility
use constant OTAPictureMessage_PORT => 5514;

# New way to access PORT -> $GSM::SMS::OTA::PictureMessage::PORT
$PORT = 5514;

# This nomenclature is not what I want ... I should rewrite them 
# ( with a thin layer of backwards compatibility ) to 
# <PACKAGENAME>::<FUNCTIONNAME>, e.g.:
# GSM::SMS::OTA::PictureMessage::FromBase64
#           ^
# GSM::SMS::NBS::Format::PictureMessage
# ---> The Smart Message Spec talks about Message Formats, hence 'Format'

sub OTAPictureMessage_fromb64 {
	my ($text, $b64, $picture_format) = @_;

	my ($bitmap, $width, $height) = GSM::SMS::OTA::Bitmap::OTABitmap_fromb64( $b64, $picture_format );
	return -1 if $bitmap == -1;

	return OTAPictureMessage_makestream( $text, $bitmap, $width, $height);	

}

sub OTAPictureMessage_fromfile {
	my ($text, $file) = @_;

	my ($bitmap, $width, $height) = GSM::SMS::OTA::Bitmap::OTABitmap_fromfile( $file );
	return -1 if $bitmap == -1;
	
	return OTAPictureMessage_makestream( $text, $bitmap, $width, $height);	
}

sub OTAPictureMessage_makestream {
	my ($text, $bitmap, $width, $height) = @_;

	# preamble
	my $stream;

	# text
	$stream .= sprintf( "%02X", ord('0') );
	$stream .= sprintf( "%02X", 0 );
	$stream .= sprintf( "%04X", length($text) );
	map { $stream .= sprintf( "%02X", ord($_)) } split(//,$text);

	# image
	$stream .= sprintf( "%02X", 2 );
	my $bitmap_stream = GSM::SMS::OTA::Bitmap::OTABitmap_makestream( $width, $height, 1, $bitmap );
	$stream .= sprintf( "%04X", length($bitmap_stream) );
	$stream .= sprintf( "%02X", 0 );
	$stream .= $bitmap_stream;

	return $stream;
}

## TODO!!!
## Provide an object class for the GSM::SMS::OTA::Bitmap package
## $bitmap = GSM::SMS::OTA::Bitmap->new( -filename => '' );
## $bitmap = GSM::SMS::OTA::Bitmap->new( -b64 => '' );
## $bitmap->width|height|depth|serialize

1;
