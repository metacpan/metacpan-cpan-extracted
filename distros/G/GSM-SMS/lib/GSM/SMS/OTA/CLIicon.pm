package GSM::SMS::OTA::CLIicon;
use GSM::SMS::OTA::Bitmap;

require  Exporter;
@ISA = qw(Exporter);
 
@EXPORT = qw( 	OTACLIicon_makestream  
		OTACLIicon_PORT	
		OTACLIicon_fromb64
		OTACLIicon_fromfile
		); 

$VERSION = '0.1';

use constant OTACLIicon_PORT => 5507;

sub OTACLIicon_fromb64 {
	my ($b64, $format) = @_;

	my ($arr, $w, $h) = OTABitmap_fromb64( $b64, $format );
	return -1 if $arr == -1;

	return OTACLIicon_makestream( 72, 14, 1, $arr ); 
}

sub OTACLIicon_fromfile {
	my ($file) = @_;

	my ($arr, $w, $h) = OTABitmap_fromfile( $file );
	return -1 if $arr == -1;

	return OTACLIicon_makestream( 72, 14, 1, $arr );
}

sub OTACLIicon_makestream {
	my ($width, $height, $depth, $ref_bytearray) = @_;

	my $stream;

	$stream.='00';	# Nokia stuff for CLI identification
	$stream.=OTABitmap_makestream($width, $height, $depth, $ref_bytearray);

	return $stream;
}

1;

=head1 NAME

GSM::SMS::OTA::CLIicon

=head1 DESCRIPTION

This package implements encoding of a CLI ( Caller Line Identification ) icon. 

=head1 METHODS

=head2 OTACLIicon_fromb64

	$stream = OTACLIicon_fromb64( $b64, $format );

Generate a CLI icon from a b64 endoded bitmap in the specified format ( gif, png, bmp, ... ).

=head2 OTACLIicon_fromfile

	$stream =OTACLIicon_fromfile( $file );

Generate a CLI icon from an image file.

=head2 OTACLIicon_PORT

NSB port number for CLI icon message.

=head1 AUTHOR

Johan Van den Brande <johan@vandenbrande.com>
