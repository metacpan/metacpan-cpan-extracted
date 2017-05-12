# Sms::Token::PID - SMS PID (protocol identifier) token
# Copyright (C) 2002-2015 Cosimo Streppone, cosimo@cpan.org
#
# This program is free software; you can redistribute it and/or modify
# it only under the terms of Perl itself.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# Perl licensing terms for details.

package Sms::Token::PID;
use integer;
use strict;
use Device::Gsm::Sms::Token;

@Sms::Token::PID::ISA = ('Sms::Token');

# takes (scalar message (string) reference)
# returns success/failure of decoding
# if all ok, removes PDUTYPE from message
sub decode {
    my ($self, $rMessage) = @_;
    my $ok = 0;

    $self->data(substr $$rMessage, 0, 2);
    $self->state(Sms::Token::DECODED);

    # Remove PID from message
    $$rMessage = substr($$rMessage, 2);

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
