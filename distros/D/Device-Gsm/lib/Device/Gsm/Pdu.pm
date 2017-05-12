# Device::Gsm::Pdu - PDU encoding/decoding functions for Device::Gsm class
# Copyright (C) 2002-2015 Cosimo Streppone, cosimo@cpan.org
# Copyright (C) 2006-2015 Grzegorz Wozniak, wozniakg@gmail.com
#
# This program is free software; you can redistribute it and/or modify
# it only under the terms of Perl itself.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# Perl licensing terms for details.
#
# Commercial support is available. Write me if you are
# interested in new features or software support.

# TODO document decode_text8()

package Device::Gsm::Pdu;

use strict;
use Device::Gsm::Charset;
use Device::Gsm::Sms::Token::UDH;

# decode a pdu encoded phone number into human readable format
sub decode_address {
    my $address = shift or return;

    my $number;
    my ($length, $type, $bcd_digits) = unpack('A2 A2 A*', $address);

    # XXX DEBUG
    #print STDERR "len=$length type=$type bcd=$bcd_digits\n";

    # Manage alphabetical addresses (as per TS 03.38 specs)
    # Alphabetical addresses begin with 'D0'.
    # Check also http://smslink.sourceforge.net/pdu.html
    #
    if ($type eq 'D0') {
        $number = decode_text7($length . $bcd_digits);
        return $number;
    }

    # Reverse each pair of bcd digits
    while ($bcd_digits) {
        $number .= reverse substr($bcd_digits, 0, 2);
        $bcd_digits = substr $bcd_digits, 2;
    }

    #print STDERR "num=$number - ";

    # Truncate last `F' if found (XXX ???)
    #$number = substr( $number, 0, hex($length) );
    chop $number if substr($number, -1) eq 'F';

    # Decode special characters for GPRS dialing
    $number =~ s/A/\*/;
    $number =~ s/B/#/;

    # If number is international, put a '+' sign before
    if ($type == 91 && $number !~ /^\s*\+/) {
        $number = '+' . $number;
    }

    return $number;
}

sub decode_text7 {
    pack '(b*)*',
        unpack 'C/(a7)',
        pack 'C a*',
        unpack 'C b*',
        pack 'H*', $_[0];
}

#remains for comatibility reasons with my production scripts :)
sub decode_text7_udh1 {
    my $unpacked = join '',
        unpack 'C/(a7)',
        pack 'C a*',
        unpack 'C b*',
        pack 'H*', $_[0];

    #remove bit of padding from message
    $unpacked = substr($unpacked, 1, length($unpacked));
    pack '(b*)*', ($unpacked =~ m/([01]{1,7})/gs);
}

#decode text with padding
sub decode_text7_udh {
    my ($encoded, $padding) = @_;
    $padding = 0 unless ($padding);
    my $unpacked = join '',
        unpack 'C/(a7)',
        pack 'C a*',
        unpack 'C b*',
        pack 'H*', $encoded;

    #remove bits of padding from message
    $unpacked = substr($unpacked, $padding, length($unpacked));
    pack '(b*)*', ($unpacked =~ m/([01]{7})/gs);

}

# decode 8-bit encoded text
sub decode_text8($) {

    my $text8 = shift();
    return unless $text8;

    my $str;
    while ($text8) {
        $str .= chr(hex(substr $text8, 0, 2));
        if (length($text8) > 2) {
            $text8 = substr($text8, 2);
        }
        else {
            $text8 = '';
        }
    }
    return $str;
}

sub encode_address {
    my $num     = shift;
    my $type    = '';
    my $len     = 0;
    my $encoded = '';

    $num =~ s/\s+//g;

    #warn('encode_address('.$num.')');

    # Check for alphabetical addresses (TS 03.38)
    if ($num =~ /[A-Z][a-z]/) {

        # Encode clear text in gsm0338 7-bit
        $type    = 'D0';
        $encoded = encode_text7($num);
        $len     = unpack 'H2' => chr(length $encoded);
    }
    else {
        $type = index($num, '+') == 0 ? 91 : 81;

        # Remove all non-numbers. Beware to GPRS dialing chars.
        $num =~ s/[^\d\*#]//g;
        $num =~ s/\*/A/g;        # "*" maps to A
        $num =~ s/#/B/g;         # "#" maps to B

        $len = unpack 'H2' => chr(length $num);
        $num .= 'F';
        my @digit = split // => $num;

        while (@digit > 1) {
            $encoded .= join '', reverse splice @digit, 0, 2;
        }
    }

    #warn('   [' . (uc $len . $type . $encoded ) . ']' );

    return (uc $len . $type . $encoded);
}

sub decode_text_UCS2 {
    my $encoded = shift;
    return undef unless $encoded;

    my $len = hex substr($encoded, 0, 2);
    $encoded = substr $encoded, 2;

    my $decoded = "";
    while ($encoded) {
        $decoded .= pack("C0U", hex(substr($encoded, 0, 4)));
        $encoded = substr($encoded, 4);
    }
    return $decoded;
}

sub encode_text7 {
    uc
        unpack 'H*',
        pack 'C b*',
        length $_[0],
        join '',
        unpack '(b7)*', $_[0];
}

#
#return complete ud with udh
#remains for comatibility reasons with my production scripts :)
#
sub encode_text7_udh1 {
    my $decoded        = shift;
    my $udh1           = shift;
    my $decoded_length = length($decoded);
    $decoded = Device::Gsm::Charset::iso8859_to_gsm0338($decoded);
    my $pdu_msg = uc
        unpack 'H*',
        pack 'b*',

        #add one bit of padding to align septet boundary
        '0' . join '', unpack '(b7)*', $decoded;

    #below add 7 septets length for udh1
    return
          sprintf("%02X", $decoded_length + Sms::Token::UDH::UDH1_LENGTH)
        . $udh1
        . $pdu_msg;
}

#
#encode text with padding
#
sub encode_text7_udh {
    my $decoded = shift;
    my $padding = shift;
    $padding = 0 unless ($padding);
    my $decoded_length = length($decoded);
    $decoded = Device::Gsm::Charset::iso8859_to_gsm0338($decoded);
    my $pdu_msg = uc
        unpack 'H*',
        pack 'b*',

        #add bits of padding to align septet boundary
        '0' x $padding . join '', unpack '(b7)*', $decoded;

    #below add septets length of text
    my $len_hex = sprintf("%02X", $decoded_length);
    return
        wantarray
        ? ($len_hex, $pdu_msg, $len_hex . $pdu_msg)
        : $len_hex . $pdu_msg;
}

sub pdu_to_latin1 {

    # Reattach a length octet.
    my $s   = shift;
    my $len = length $s;

    #arn "len=$len, len/2=", $len/2, "\n";
    my $l = uc unpack("H*", pack("C", int(length($s) / 2 * 8 / 7)));
    if (length($l) % 2 == 1) { $l = '0' . $l }
    my $pdu = $l . $s;

    #arn "l=$l, pdu=$pdu\n";
    my $decoded = Device::Gsm::Pdu::decode_text7($pdu);

    #arn "decoded_text7=$decoded\n";
    my $latin1 = Device::Gsm::Charset::gsm0338_to_iso8859($decoded);

    #arn "latin1=$latin1\n";
    return $latin1;
}

sub latin1_to_pdu {
    my $latin1_text = $_[0];

    #arn "latin1=$latin1_text\n";
    my $gsm0338 = Device::Gsm::Charset::iso8859_to_gsm0338($latin1_text);

    #arn "gsm0338=$gsm0338\n";
    my $fullpdu = Device::Gsm::Pdu::encode_text7($gsm0338);

    #arn "pdu=$fullpdu\n";
    return substr($fullpdu, 2);    # strip off the length octet
}

1;

=head1 NAME

Device::Gsm::Pdu - library to manage PDU encoded data for GSM messaging

=head1 WARNING 

   This is C<BETA> software, still needs extensive testing and
   support for custom GSM commands, so use it at your own risk,
   and without C<ANY> warranty! Have fun.

=head1 NOTICE

    This module is meant to be used internally by C<Device::Gsm> class,
    so you probably do not want to use it directly.

=head1 SYNOPSIS

  use Device::Gsm::Pdu;

  # DA is destination address
  $DA = Device::Gsm::Pdu::encode_address('+39347101010');
  $number = Device::Gsm::Pdu::decode_address( $DA );

  # Encode 7 bit text to send messages
  $text = Device::Gsm::Pdu::encode_text7('hello');

=head1 DESCRIPTION

C<Device::Gsm::Pdu> module includes a few basic functions to deal with SMS in PDU mode,
such as encoding GSM addresses (phone numbers) and, for now only, 7 bit text.

=head1 FUNCTIONS

=head2 decode_address( pdu_encoded_address )

Takes a PDU encoded address and decodes into human-readable mobile number.
If number type is international, result will be prepended with a `+' sign.

Clearly, it is intended as an internal function.

=head3 Example

    print Device::Gsm::Pdu::decode_address( '0B919343171010F0' );
    # prints `+39347101010';

=head2 encode_address( mobile_number )

Takes a mobile number and encodes it as DA (destination address).
If it begins with a `+', as in `+39328101010', it is treated as an international
number.

=head3 Example

    print Device::Gsm::Pdu::encode_address( '+39347101010' );
    # prints `0B919343171010F0'

=head2 encode_text7( text_string )

Encodes some text ASCII string in 7 bits PDU format, including a header byte
which tells the length is septets. This is the only 100% supported mode to
encode text.

=head3 Example

    print Device::Gsm::Pdu::encode_text7( 'hellohello' );
    # prints `0AE832...'

=head2 pdu_to_latin1($pdu)

Converts a PDU (without the initial length octet) into a latin1 string.

=head3 Example

    my $pdu = 'CAFA9C0E0ABBDF7474590E8296E56C103A3C5E97E5';
    print Device::Gsm::Pdu::pdu_to_latin1($pdu);
    # prints `Just another Perl hacker'

=head2 latin1_to_pdu($text)

Converts a text string in latin1 encoding (ISO-8859-1) into a PDU string.

=head3 Example

    my $text = "Just another Perl hacker";
    print Device::Gsm::Pdu::latin1_to_pdu($text);
    # prints `CAFA9C0E0ABBDF7474590E8296E56C103A3C5E97E5'

=head1 AUTHOR

Cosimo Streppone, cosimo@cpan.org

=head1 COPYRIGHT

This library is free software; you can redistribute it and/or modify
it only under the terms of Perl itself.

=head1 SEE ALSO

Device::Gsm(3), perl(1)

