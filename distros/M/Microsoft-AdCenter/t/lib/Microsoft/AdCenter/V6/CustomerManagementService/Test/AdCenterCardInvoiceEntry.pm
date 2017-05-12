package Microsoft::AdCenter::V6::CustomerManagementService::Test::AdCenterCardInvoiceEntry;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V6::CustomerManagementService;
use Microsoft::AdCenter::V6::CustomerManagementService::AdCenterCardInvoiceEntry;

sub test_can_create_ad_center_card_invoice_entry_and_set_all_fields : Test(7) {
    my $ad_center_card_invoice_entry = Microsoft::AdCenter::V6::CustomerManagementService::AdCenterCardInvoiceEntry->new
        ->Amount('amount')
        ->CPC('cpc')
        ->CampaignName('campaign name')
        ->Clicks('clicks')
        ->IndentLevel('indent level')
        ->OrderId('order id')
    ;

    ok($ad_center_card_invoice_entry);

    is($ad_center_card_invoice_entry->Amount, 'amount', 'can get amount');
    is($ad_center_card_invoice_entry->CPC, 'cpc', 'can get cpc');
    is($ad_center_card_invoice_entry->CampaignName, 'campaign name', 'can get campaign name');
    is($ad_center_card_invoice_entry->Clicks, 'clicks', 'can get clicks');
    is($ad_center_card_invoice_entry->IndentLevel, 'indent level', 'can get indent level');
    is($ad_center_card_invoice_entry->OrderId, 'order id', 'can get order id');
};

1;
