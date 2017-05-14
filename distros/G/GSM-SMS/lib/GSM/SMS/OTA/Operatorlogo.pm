package GSM::SMS::OTA::Operatorlogo;
use GSM::SMS::OTA::Bitmap;

require  Exporter;
@ISA = qw(Exporter);
 
@EXPORT = qw( 	OTAOperatorlogo_makestream  
		OTAOperatorlogo_PORT	
		OTAOperatorlogo_fromb64
		OTAOperatorlogo_fromfile
		); 

$VERSION = "0.161";

use constant OTAOperatorlogo_PORT => 5506;

sub OTAOperatorlogo_fromb64 {
	my ($countrycode, $operatorcode, $b64, $format) = @_;

	my ($arr, $w, $h) = OTABitmap_fromb64( $b64, $format );
	return -1 if $arr == -1;

	return OTAOperatorlogo_makestream( $countrycode, $operatorcode, 72, 14, 1, $arr ); 
}

sub OTAOperatorlogo_fromfile {
	my ($countrycode, $operatorcode, $file) = @_;

	my ($arr, $w, $h) = OTABitmap_fromfile( $file );
	return -1 if $arr == -1;

	return OTAOperatorlogo_makestream( $countrycode, $operatorcode, 72, 14, 1, $arr ); 
}


sub OTAOperatorlogo_makestream {
	my ($countrycode, $operatorcode, $width, $height, $depth, $ref_bytearray) = @_;

	my $stream;

	$stream.= encodeOperatorID($countrycode, $operatorcode);
	$stream.='00';	# Nokia stuff for validity period
	$stream.=OTABitmap_makestream($width, $height, $depth, $ref_bytearray);

	return $stream;
}

# encode the operator ID (country, operator) into a litlle endian BCD string
sub encodeOperatorID {
	my ($country, $operator) = @_;

	my $c = sprintf("%03d", $country);
	my $o = sprintf("%02d", $operator);

	my @arr = split /|/, sprintf("%03d%02d", $country, $operator);
	my @enc;
 
	$enc[0] = ($arr[1] & 0x0F) << 4 | ($arr[0] & 0x0F);
	$enc[1] = (0x0F << 4)           | ($arr[2] & 0x0F);
	$enc[2] = ($arr[4] & 0x0F) << 4 | ($arr[3] & 0x0F);
 
	return join("", map { sprintf("%02X", $_) } @enc );
} 

1;

=head1 NAME

GSM::SMS::OTA::Operatorlogo

=head1 DESCRIPTION

This package implements encoding of an Operatorlogo icon.

=head1 METHODS

=head2 OTAOperatorlogo_fromb64

	$stream = OTAOperatorlogo_fromb64($countrycode, $operatorcode, $b64, $format);

Create a operator logo from a b64 encoded image in the specified format ( gif, png, ...). The countrycode and operator code are 2 codes that specfify either the operator or the country of the receiving handset.

=head2 OTAOperatorlogo_fromfile

	$stream = OTAOperatorlogo_fromfile($countrycode, $operatorcode, $file );

Create a operator logo from a file.

=head2 OTAOperatorlogo_PORT

NSB Port number for Operator logos.

=head1 ISSUES

The country and operator coe have to be provided manually. It would be 
interesting to have other modules: GSM::SMS::Countrycode and GSM::SMS::OPeratorcode , that handle this automatically. Give them a msisdn and they provide you with the code.

=head1 AUTHOR

Johan Van den Brande <johan@vandenbrande.com>
