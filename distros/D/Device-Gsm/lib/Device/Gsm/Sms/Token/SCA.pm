# Sms::Token::SCA - SMS SCA token (service center address)
# Copyright (C) 2002-2015 Cosimo Streppone, cosimo@cpan.org
#
# This program is free software; you can redistribute it and/or modify
# it only under the terms of Perl itself.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# Perl licensing terms for details.

package Sms::Token::SCA;
use integer;
use strict;
use Device::Gsm::Sms::Token;

@Sms::Token::SCA::ISA = ('Sms::Token');

# takes (scalar message (string) reference)
# returns success/failure of decoding
# if all ok, removes SCA from message
sub decode {
    my ($self, $rMessage) = @_;
    my $ok = 0;
    my ($length, $type, $address);
    my $msg      = $$rMessage;
    my $msg_copy = $msg;

    # .------------.----------.---------------------------------.
    # | LENGTH (1) | TYPE (1) | ADDRESS BCD DIGITS (0-8 octets) |
    # `------------'----------'---------------------------------'
    $length = substr $msg, 0, 2;

    # If length is `00', SCA = default end decoding ends
    if ($length eq '00') {
        $self->data('');
        $self->state(Sms::Token::DECODED);

        # Remove length-octet read from message
        $$rMessage = substr($$rMessage, 2);
        return 1;
    }

    # Begin decoding (length is number of octets for the SCA + 1 (length) )
    $length = hex $length;

    # Length > 9 is impossible; max is 8 + 1 (length)
    if ($length > 9) {
        $self->data(undef);
        $self->state(Sms::Token::ERROR);
        return 0;
    }

    $self->set('length' => $length);

    # Get type of message (81 = national, 91 = international, 80 = empty for status messages)
    $type = substr $msg, 2, 2;
    if ($type ne '81' and $type ne '91' and $type ne '80') {
        $self->data(undef);
        $self->state(Sms::Token::ERROR);
        return 0;
    }

    $self->set(type => $type);

    # Get rest of address
    $address = substr $msg, 4, (($length - 1) << 1);

    # Reverse each pair of bcd digits
    my $sca;
    while ($address) {
        $sca .= reverse substr($address, 0, 2);
        $address = substr $address, 2;
    }

    # Truncate last `F' if found (XXX)
    chop $sca if substr($sca, -1) eq 'F';

    # If sca is international, put a '+' sign before
    $sca = '+' . $sca if $type eq '91';

    $self->data($sca);
    $self->set(type     => $type);
    $self->set('length' => $length);
    $self->state(Sms::Token::DECODED);

    # Remove SCA info from message
    $$rMessage = substr($msg, ($length + 1) << 1);

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
    }

    # Begin encoding as SCA
    $data =~ s/\s+//g;

    my $type = index($data, '+') == 0 ? 91 : 81;

    # Remove all non-numbers
    $data =~ s/\D//g;

    my $len = unpack 'H2' => chr(length $data);

    $data .= 'F';
    my @digit = split // => $data;
    my $encoded;

    while (@digit > 1) {
        $encoded .= join '', reverse splice @digit, 0, 2;
    }

    $data = uc $len . $type . $encoded;

    $self->data($data);
    $self->set('length' => $len);
    $self->set('type'   => $type);
    $self->state(Sms::Token::ENCODED);

    return $data;

}

1;
