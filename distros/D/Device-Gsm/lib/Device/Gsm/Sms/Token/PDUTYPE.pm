# Sms::Token::PDUTYPE - SMS PDU TYPE token (type of message)
# Copyright (C) 2002-2015 Cosimo Streppone, cosimo@cpan.org
#
# This program is free software; you can redistribute it and/or modify
# it only under the terms of Perl itself.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# Perl licensing terms for details.

package Sms::Token::PDUTYPE;
use integer;
use strict;
use Device::Gsm::Sms::Token;

@Sms::Token::PDUTYPE::ISA = ('Sms::Token');

# takes (scalar message (string) reference)
# returns success/failure of decoding
# if all ok, removes PDUTYPE from message
sub decode {
    my ($self, $rMessage) = @_;
    my $ok = 0;

    $self->data(substr($$rMessage, 0, 2));

    # Update PDU type flags into token object
    $self->set('pdutype', hex(substr($$rMessage, 0, 2)));
    $self->set('MTI',     $self->MTI());
    $self->set('MMS',     $self->MMS());
    $self->set('RD',      $self->RD());
    $self->set('VPF',     $self->VPF());
    $self->set('SRR',     $self->SRR());
    $self->set('SRI',     $self->SRI());
    $self->set('UDHI',    $self->UDHI());
    $self->set('RP',      $self->RP());

    # Remove PDU TYPE from message
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
    }

    return $data;
}

#--------------------------------------------
# Bit component flags

sub RP {    # REPLY PATH PARAMETER SET
    my $self = shift;
    ($self->get('pdutype') & 0x80) >> 7;
}

sub UDHI {    # USER DATA HEADER PRESENT
    my $self = shift;
    ($self->get('pdutype') & 0x40) >> 6;
}

sub SRR {     # STATUS REPORT REQUESTED
    my $self = shift;
    ($self->get('pdutype') & 0x20) >> 5;
}

sub SRI {     # STATUS REPORT WILL BE RETURNED
    my $self = shift;
    ($self->get('pdutype') & 0x20) >> 5;
}

sub VPF
{    # VALIDITY PERIOD FLAG 0=not present, 1=reserved, 2=integer, 3=semioctet
    my $self = shift;
    ($self->get('pdutype') & 0x18) >> 3;
}

sub MMS {    # MORE MESSAGES WAITING AT SMS-C
    my $self = shift;
    ($self->get('pdutype') & 0x04) >> 2;
}

sub RD {     # ... allow repeated sending (REJECT DUPLICATES)
    my $self = shift;
    ($self->get('pdutype') & 0x04) >> 2;
}

sub MTI
{ # TYPE OF SMS (0x00=SMS-DELIVER, 0x01=SMS-SUBMIT, 0x10=SMS-STATUS/COMMAND, 0x11=RESERVED
    my $self = shift;
    $self->get('pdutype') & 0x03;
}

1;
