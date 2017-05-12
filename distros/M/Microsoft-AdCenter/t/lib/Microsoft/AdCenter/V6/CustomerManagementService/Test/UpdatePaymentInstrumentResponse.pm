package Microsoft::AdCenter::V6::CustomerManagementService::Test::UpdatePaymentInstrumentResponse;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V6::CustomerManagementService;
use Microsoft::AdCenter::V6::CustomerManagementService::UpdatePaymentInstrumentResponse;

sub test_can_create_update_payment_instrument_response_and_set_all_fields : Test(2) {
    my $update_payment_instrument_response = Microsoft::AdCenter::V6::CustomerManagementService::UpdatePaymentInstrumentResponse->new
        ->UpdatePaymentInstrumentResult('update payment instrument result')
    ;

    ok($update_payment_instrument_response);

    is($update_payment_instrument_response->UpdatePaymentInstrumentResult, 'update payment instrument result', 'can get update payment instrument result');
};

1;
