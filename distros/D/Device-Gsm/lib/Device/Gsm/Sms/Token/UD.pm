# Sms::Token::UD - SMS UD (user data length + user data) token
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

package Sms::Token::UD;
use integer;
use strict;

use Device::Gsm::Charset;
use Device::Gsm::Pdu;
use Device::Gsm::Sms::Token;

#my $udh1_length=UDH1_LENGTH;
#my $udh2_length=UDH2_LENGTH;

@Sms::Token::UD::ISA = ('Sms::Token');

# takes (scalar message (string) reference)
# returns success/failure of decoding
# if all ok, removes user data from message
sub decode {
    my ($self, $rMessage) = @_;
    my $ok      = 0;
    my $padding = 0;

    # Get length of message
    my $ud_len = hex substr($$rMessage, 0, 2);

    # Finally get text of message
    my $dcs     = $self->get('_messageTokens')->{'DCS'}->get('_data')->[0];
    my $is_csms = $self->get('_messageTokens')->{'UDH'}->{'_IS_CSMS'};
    $is_csms
        and my $udhl = $self->get('_messageTokens')->{'UDH'}->{'_length'};
    my $text;

    if ($dcs == 8) {
        $text = Device::Gsm::Pdu::decode_text_UCS2($$rMessage);
    }
    else {
        if ($is_csms) {
            $padding = Sms::Token::UDH::calculate_padding($udhl);
            $text = Device::Gsm::Pdu::decode_text7_udh($$rMessage, $padding);
        }
        else {
            $text = Device::Gsm::Pdu::decode_text7($$rMessage);
        }
        $text = Device::Gsm::Charset::gsm0338_to_iso8859($text);
    }
    $self->set('padding' => $padding);
    $self->set('length'  => $ud_len);
    $self->set('text'    => $text);
    $self->data($text);
    $self->state(Sms::Token::DECODED);

    # Empty message
    $$rMessage = '';

    return 1;
}

#
# [token]->encode( [$data] )
#
# takes internal token data and encodes it, returning the result or undef value in case of errors
#
sub encode {
    my $self    = shift;
    my $padding = shift;

    #my $ud_len = $self->get('length');
    my $text = $self->get('text');

    return Device::Gsm::Pdu::encode_text7($text);

}

1;

