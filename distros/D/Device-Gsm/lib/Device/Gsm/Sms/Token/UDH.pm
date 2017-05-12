# Sms::Token::UDH - SMS UDH token (User Data Header  stores non text data inluding CSMS ref,parts,part number)
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

package Sms::Token::UDH;
use strict;

use Device::Gsm::Pdu;
use Device::Gsm::Sms::Token;

#IEI types corresponding CSMS
use constant IEI_T_8    => 0x00;
use constant IEI_T_16   => 0x08;
use constant IEI_T_8_L  => 5;
use constant IEI_T_16_L => 6;

#constants for compatibility with older versions
##user data headers in CSMS more here : http://mobiletidings.com/2009/02/18/combining-sms-messages/
use constant UDH1 => '050003';
use constant UDH2 => '060804';

#lenght in septets
use constant UDH1_LENGTH => 7;
use constant UDH2_LENGTH => 8;

@Sms::Token::UDH::ISA = ('Sms::Token');

# takes (scalar message (string) reference)
# returns success/failure of decoding
# if all ok, removes user data header from message
sub decode {
    my ($self, $rMessage) = @_;

    # Get length of message
    my $ud_len = hex substr($$rMessage, 0, 2);

    #get UDH length
    my $udhl = hex substr($$rMessage, 2, 2);

    #get UDH raw data
    my $udh = substr($$rMessage, 4, 2 * $udhl);

    #cut udh from message
    $$rMessage = substr($$rMessage, 4 + 2 * $udhl);
    my $udhCp = $udh;
    my %udh_data_hash;
    while (length($udh)) {

        #Information-Element-Identifier  type octet
        my $IEI_t = hex(substr($udh, 0, 2));

        #Information-Element-Identifier data length
        my $IEI_l = hex(substr($udh, 2, 2));

        #Information-Element-Identifier data
        my $IEI_d = substr($udh, 4, 2 * $IEI_l);

        #cut element form data
        $udh = substr($udh, 4 + 2 * $IEI_l);

        #store data in hash
        $udh_data_hash{$IEI_t} = $IEI_d;
    }
    my $csms_ref_hex;
    my $csms_ref_num;
    my $csms_parts;
    my $csms_part_num;
    if (defined($udh_data_hash{ +IEI_T_8 })) {
        ($csms_ref_hex, $csms_parts, $csms_part_num)
            = ($udh_data_hash{ +IEI_T_8 }
                =~ /^([A-F0-9]{2})([A-F0-9]{2})([A-F0-9]{2})/);
        $csms_parts    = hex($csms_parts);
        $csms_part_num = hex($csms_part_num);
        $csms_ref_num  = hex($csms_ref_hex);

    }
    elsif (defined($udh_data_hash{ +IEI_T_16 })) {
        ($csms_ref_hex, $csms_parts, $csms_part_num)
            = ($udh_data_hash{ +IEI_T_16 }
                =~ /^([A-F0-9]{4})([A-F0-9]{2})([A-F0-9]{2})/);
        $csms_parts    = hex($csms_parts);
        $csms_part_num = hex($csms_part_num);
        $csms_ref_num  = hex($csms_ref_hex);
    }
    if (defined($csms_ref_hex)) {
        $self->set('IS_CSMS'  => 1);
        $self->set('REF_NUM'  => $csms_ref_num);
        $self->set('REF_HEX'  => $csms_ref_hex);
        $self->set('PARTS'    => $csms_parts);
        $self->set('PART_NUM' => $csms_part_num);
    }
    else {
        $self->set('IS_CSMS' => 0);
    }
    $self->set('UDHI'     => 1);
    $self->set('length'   => $udhl);
    $self->set('raw_data' => $udhCp);
    $self->data(\%udh_data_hash);
    $self->state(Sms::Token::DECODED);

    #restore ud_len
    $$rMessage = sprintf("%02X", $ud_len - ($udhl + 1)) . $$rMessage;

    return 1;
}

#
# [token]->encode($IEI_t1=>$IEI_d1,$IEI_t2=>$IEI_d2,... )
# takes %opts like above, returns complete UDH string
# eg. my $udh=new Sms::Token("UDH");print $udh->encode(0x00=>"050401") gives 050003050401
#
sub encode {
    my $self          = shift;
    my %udh_data_hash = @_;
    my $udh;
    foreach (keys %udh_data_hash) {
        my $IEI_t = sprintf("%02X", $_);
        my $IEI_l = sprintf("%02X", length($udh_data_hash{$_}) / 2);
        $udh .= $IEI_t . $IEI_l . $udh_data_hash{$_};
    }
    $udh = sprintf("%02X", length($udh) / 2) . $udh;
    return $udh;
}

#
#return padding for given user data header lenght
#

sub calculate_padding {

    #my $self=shift;
    my $udhl = shift;
    return 0 unless ($udhl);
    return 7 - ((($udhl + 1) * 8) % 7);
}

1;

