# Sms::Token::ST - SMS TP-ST token (Status of the MO message)
#
#/* TP-Status from 3GPP TS 23.040 section 9.2.3.15 */
#/* sms received sucessfully */
#TP_STATUS_RECEIVED_OK                   = 0x00,
#TP_STATUS_UNABLE_TO_CONFIRM_DELIVERY    = 0x01,
#TP_STATUS_REPLACED                      = 0x02,
#/* Reserved: 0x03 - 0x0f */
#/* Values specific to each SC: 0x10 - 0x1f */
#/* Temporary error, SC still trying to transfer SM: */
#TP_STATUS_TRY_CONGESTION             = 0x20,
#TP_STATUS_TRY_SME_BUSY               = 0x21,
#TP_STATUS_TRY_NO_RESPONSE_FROM_SME   = 0x22,
#TP_STATUS_TRY_SERVICE_REJECTED       = 0x23,
#TP_STATUS_TRY_QOS_NOT_AVAILABLE      = 0x24,
#TP_STATUS_TRY_SME_ERROR              = 0x25,
#/* Reserved: 0x26 - 0x2f */
#/* Values specific to each SC: 0x30 - 0x3f */
#/* Permanent error, SC is not making any more transfer attempts:  */
#TP_STATUS_PERM_REMOTE_PROCEDURE_ERROR   = 0x40,
#TP_STATUS_PERM_INCOMPATIBLE_DEST        = 0x41,
#TP_STATUS_PERM_REJECTED_BY_SME          = 0x42,
#TP_STATUS_PERM_NOT_OBTAINABLE           = 0x43,
#TP_STATUS_PERM_QOS_NOT_AVAILABLE        = 0x44,
#TP_STATUS_PERM_NO_INTERWORKING          = 0x45,
#TP_STATUS_PERM_VALID_PER_EXPIRED        = 0x46,
#TP_STATUS_PERM_DELETED_BY_ORIG_SME      = 0x47,
#TP_STATUS_PERM_DELETED_BY_SC_ADMIN      = 0x48,
#TP_STATUS_PERM_SM_NO_EXIST              = 0x49,
#/* Reserved: 0x4a - 0x4f */
#/* Values specific to each SC: 0x50 - 0x5f */
#/* Temporary error, SC is not making any more transfer attempts: */
#TP_STATUS_TMP_CONGESTION               = 0x60,
#TP_STATUS_TMP_SME_BUSY                 = 0x61,
#TP_STATUS_TMP_NO_RESPONSE_FROM_SME     = 0x62,
#TP_STATUS_TMP_SERVICE_REJECTED         = 0x63,
#TP_STATUS_TMP_QOS_NOT_AVAILABLE        = 0x64,
#TP_STATUS_TMP_SME_ERROR                = 0x65,
#/* Reserved: 0x66 - 0x6f */
#/* Values specific to each SC: 0x70 - 0x7f */
#/* Reserved: 0x80 - 0xff */
#TP_STATUS_NONE = 0xFF
#
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

package Sms::Token::ST;
use integer;
use strict;
use Device::Gsm::Sms::Token;

@Sms::Token::ST::ISA          = ('Sms::Token');
%Sms::Token::ST::STATUS_CODES = (
    0x00 => 'TP_STATUS_RECEIVED_OK',
    0x01 => 'TP_STATUS_UNABLE_TO_CONFIRM_DELIVERY',
    0x02 => 'TP_STATUS_REPLACED',
############
    0x20 => 'TP_STATUS_TRY_CONGESTION',
    0x21 => 'TP_STATUS_TRY_SME_BUSY',
    0x22 => 'TP_STATUS_TRY_NO_RESPONSE_FROM_SME',
    0x23 => 'TP_STATUS_TRY_SERVICE_REJECTED',
    0x24 => 'TP_STATUS_TRY_QOS_NOT_AVAILABLE',
    0x25 => 'TP_STATUS_TRY_SME_ERROR',
############
    0x40 => 'TP_STATUS_PERM_REMOTE_PROCEDURE_ERROR',
    0x41 => 'TP_STATUS_PERM_INCOMPATIBLE_DEST',
    0x42 => 'TP_STATUS_PERM_REJECTED_BY_SME',
    0x43 => 'TP_STATUS_PERM_NOT_OBTAINABLE',
    0x44 => 'TP_STATUS_PERM_QOS_NOT_AVAILABLE',
    0x45 => 'TP_STATUS_PERM_NO_INTERWORKING',
    0x46 => 'TP_STATUS_PERM_VALID_PER_EXPIRED',
    0x47 => 'TP_STATUS_PERM_DELETED_BY_ORIG_SME',
    0x48 => 'TP_STATUS_PERM_DELETED_BY_SC_ADMIN',
    0x49 => 'TP_STATUS_PERM_SM_NO_EXIST',
############
    0x60 => 'TP_STATUS_TMP_CONGESTION',
    0x61 => 'TP_STATUS_TMP_SME_BUSY',
    0x62 => 'TP_STATUS_TMP_NO_RESPONSE_FROM_SME',
    0x63 => 'TP_STATUS_TMP_SERVICE_REJECTED',
    0x64 => 'TP_STATUS_TMP_QOS_NOT_AVAILABLE',
    0x65 => 'TP_STATUS_TMP_SME_ERROR',
############
    0xFF => 'TP_STATUS_NONE'
);

# takes (scalar message (string) reference)
# returns success/failure of decoding
# if all ok, removes token from message
sub decode {
    my ($self, $rMessage) = @_;
    my $ok = 0;

    $self->data(substr($$rMessage, 0, 2));
    $self->state(Sms::Token::DECODED);

    # Remove ST from message
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
