package Microsoft::AdCenter::V6::CustomerManagementService::Test::AdCenterCardBillingStatement;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V6::CustomerManagementService;
use Microsoft::AdCenter::V6::CustomerManagementService::AdCenterCardBillingStatement;

sub test_can_create_ad_center_card_billing_statement_and_set_all_fields : Test(5) {
    my $ad_center_card_billing_statement = Microsoft::AdCenter::V6::CustomerManagementService::AdCenterCardBillingStatement->new
        ->BillingCycleDay('billing cycle day')
        ->CurrencyCode('currency code')
        ->StatementEntries('statement entries')
        ->ThresholdBalance('threshold balance')
    ;

    ok($ad_center_card_billing_statement);

    is($ad_center_card_billing_statement->BillingCycleDay, 'billing cycle day', 'can get billing cycle day');
    is($ad_center_card_billing_statement->CurrencyCode, 'currency code', 'can get currency code');
    is($ad_center_card_billing_statement->StatementEntries, 'statement entries', 'can get statement entries');
    is($ad_center_card_billing_statement->ThresholdBalance, 'threshold balance', 'can get threshold balance');
};

1;
