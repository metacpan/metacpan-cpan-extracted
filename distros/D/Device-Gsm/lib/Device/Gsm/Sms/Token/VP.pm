# Sms::Token::VP - SMS VP (validity period) token
# Copyright (C) 2002-2015 Cosimo Streppone, cosimo@cpan.org
#
# This program is free software; you can redistribute it and/or modify
# it only under the terms of Perl itself.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# Perl licensing terms for details.

package Sms::Token::VP;
use integer;
use strict;
use Device::Gsm::Sms::Token;

@Sms::Token::VP::ISA = ('Sms::Token');

# takes (scalar message (string) reference)
# returns success/failure of decoding
# if all ok, removes token from message
sub decode {
    my ($self, $rMessage) = @_;
    my $ok = 0;

    my $vpf = $self->messageTokens('PDUTYPE')->VPF();

    # Check if VP flag is present
    if ($vpf & 0x02) {

        my $vp = hex substr($$rMessage, 0, 2);

        # Decode value of VP field
        if ($vp <= 0x8F) {
            $vp = (($vp + 1) * 5) . ' minutes';
        }
        elsif ($vp <= 0xA7) {
            $vp = ((24 + ($vp - 143)) * 30) . ' minutes';
        }
        elsif ($vp <= 0xC4) {
            $vp = ($vp - 166) . ' days';
        }
        else {
            $vp = ($vp - 192) . ' weeks';
        }

        $self->set('validity_period' => $vp);
        $self->data($vp);

        # Remove VP from message
        $$rMessage = substr($$rMessage, 2);
    }

    $self->state(Sms::Token::DECODED);

    return 1;
}

#
# [token]->encode( [$data] )
#
# takes internal token data and encodes it, returning the result
# or undef value in case of errors
#
sub encode {
    my $self = shift;

    # Take supplied data (optional) or object internal data
    my $data = shift;
    if (!defined $data || $data eq '') {
        $data = $self->data();
        $data ||= '00';
    }

    return $data;
}

1;
