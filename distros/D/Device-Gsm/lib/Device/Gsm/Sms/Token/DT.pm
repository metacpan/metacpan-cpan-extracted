# Sms::Token::DT - SMS TP-DT token (Discharge-Time of <TP-ST>,
# given in semioctet representation, and represents
# the local time as described in GSM03.40)
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

package Sms::Token::DT;
use integer;
use strict;
use Device::Gsm::Sms::Token;

@Sms::Token::DT::ISA = ('Sms::Token');

# takes (scalar message (string) reference)
# returns success/failure of decoding
# if all ok, removes DT from message
sub decode {
    my ($self, $rMessage) = @_;
    my $ok = 0;

    my @ts = split //, substr($$rMessage, 0, 14);

    $self->set(year     => $ts[1] . $ts[0]);
    $self->set(month    => $ts[3] . $ts[2]);
    $self->set(day      => $ts[5] . $ts[4]);
    $self->set(hour     => $ts[7] . $ts[6]);
    $self->set(minute   => $ts[9] . $ts[8]);
    $self->set(second   => $ts[11] . $ts[10]);
    $self->set(timezone => $ts[13] . $ts[12]);

    # Store also timestamp as convenient format
    $self->set('date' => $self->get('day') . '/'
            . $self->get('month') . '/'
            . $self->get('year'));
    $self->set('time' => $self->get('hour') . ':'
            . $self->get('minute') . ':'
            . $self->get('second'));

    # TODO: add timezone decoding ...
    $self->data($self->get('date') . ' '
            . $self->get('time') . ' '
            . $self->get('timezone'));

    # Signal token as correctly decoded (?)
    $self->state(Sms::Token::DECODED);

    # Remove DT info from message
    $$rMessage = substr($$rMessage, 14);

    return 1;
}

#
# [token]->encode( [$data] )
#
# takes internal token data and encodes it, returning the result
# or undef value in case of errors
#
sub encode {
    return '99211332959500';
}

1;
