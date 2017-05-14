package GSM::SMS::OTA::VCard;
use GSM::SMS::OTA::OTA;

# Generic package for VCARDS 
# experimental!

require Exporter;
@ISA = qw(Exporter);

@EXPORT = qw( OTAVcard_makestream
			  OTAVcard_PORT );

$VERSION = "0.161";

use constant OTAVcard_PORT => 9204;


sub OTAVcard_makestream {
	my ($lastname, $firstname, $phone) = @_;

	$lastname = encode( $lastname );
	$firstname = encode( $firstname);
	$phone = encode( $phone );

	$vcard=<<EOT;
BEGIN:VCARD
VERSION:2.1
N:$lastname,$firstname
TEL;PREF:$phone
END:VCARD
EOT


	return OTAencode_8bit($vcard);
}

sub encode {
	my ($string) = @_;

	$string=~s/([,;:])/\\$1/g;

	return $string;
}

1;

=head1 NAME

GSM::SMS::OTA::VCard

=head1 DESCRIPTION

This package allows you to create a VCard to send an address/phone book item to a handset capable receiving it. This is only tested with a Nokia Phone (7110).
Anyway, this module is rather experimental.

=head1 METHODS

=head2 OTAVcard_makestream

	$stream = OTAVcard_makestream( $lastname, $firstname, $phone );

Make a VCard with only name, lastname and (home)phonenumber. A lot more is possible to include, but I think this is sufficient for most uses (?) ... or until somebody motivates me to expand this ...

=head2 OTAVcard_PORT

NSB Port number for a VCard message.

=head1 AUTHOR

Joha Van den Brande <johan@vandenbrande.com>
