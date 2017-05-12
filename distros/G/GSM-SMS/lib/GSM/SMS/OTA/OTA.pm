package GSM::SMS::OTA::OTA;

require Exporter;
@ISA = qw(Exporter);

@EXPORT = qw(	OTAdecode_8bit
				OTAencode_8bit); 

$VERSION = '0.1';

sub OTAdecode_8bit {
        my ($ud) = @_;
        my $msg;

        while (length($ud)) {
                $msg .= pack('H2',substr($ud,0,2));
                $ud = substr($ud,2);
        }
        return $msg;
}


sub OTAencode_8bit {
        my ($ud) = @_;
        my $msg;

        while (length($ud)) {
               $msg .= sprintf("%.2X", ord(substr($ud,0,1)));
               $ud = substr($ud,1);
        }
        return $msg;
}

1;

=head1 NAME

GSM::SMS::OTA::OTA

=head1 DESCRIPTION

This package contains 2 functions to decode and encode 8 bit data in an ASCII alphabet. It just writes out a byte as a 2 character string, containing the hexadecimal representation.

=head1 METHODS

	$binary = OTAdecode_8bit( $text )
	$text = OTAencode_8bit( $binary )

=head1 AUTHOR

Johan Van den Brande <johan@vandenbrande.com>
