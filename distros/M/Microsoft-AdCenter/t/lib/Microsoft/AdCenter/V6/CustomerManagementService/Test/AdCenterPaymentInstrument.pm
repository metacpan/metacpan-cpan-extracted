package Microsoft::AdCenter::V6::CustomerManagementService::Test::AdCenterPaymentInstrument;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V6::CustomerManagementService;
use Microsoft::AdCenter::V6::CustomerManagementService::AdCenterPaymentInstrument;

sub test_can_create_ad_center_payment_instrument_and_set_all_fields : Test(3) {
    my $ad_center_payment_instrument = Microsoft::AdCenter::V6::CustomerManagementService::AdCenterPaymentInstrument->new
        ->PaymentInstrAddress('payment instr address')
        ->PaymentInstrId('payment instr id')
    ;

    ok($ad_center_payment_instrument);

    is($ad_center_payment_instrument->PaymentInstrAddress, 'payment instr address', 'can get payment instr address');
    is($ad_center_payment_instrument->PaymentInstrId, 'payment instr id', 'can get payment instr id');
};

1;
