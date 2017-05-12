package Microsoft::AdCenter::V6::CustomerManagementService::Test::AdCenterCardInvoiceHeader;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V6::CustomerManagementService;
use Microsoft::AdCenter::V6::CustomerManagementService::AdCenterCardInvoiceHeader;

sub test_can_create_ad_center_card_invoice_header_and_set_all_fields : Test(21) {
    my $ad_center_card_invoice_header = Microsoft::AdCenter::V6::CustomerManagementService::AdCenterCardInvoiceHeader->new
        ->AccountName('account name')
        ->AccountNumber('account number')
        ->ActivityEndDate('2010-05-31T12:23:34')
        ->ActivityStartDate('2010-06-01T12:23:34')
        ->AttnAddress1('attn address1')
        ->AttnAddress2('attn address2')
        ->AttnAddress3('attn address3')
        ->AttnCity('attn city')
        ->AttnName('attn name')
        ->AttnPostalCode('attn postal code')
        ->AttnStateOrProvince('attn state or province')
        ->BillingInquiriesURL('billing inquiries url')
        ->CountryCode('country code')
        ->CurrencyCode('currency code')
        ->CustomerName('customer name')
        ->DocumentType('document type')
        ->InvoiceNumber('invoice number')
        ->PreferredLanguageId('preferred language id')
        ->TaxId('tax id')
        ->UserLCID('user lcid')
    ;

    ok($ad_center_card_invoice_header);

    is($ad_center_card_invoice_header->AccountName, 'account name', 'can get account name');
    is($ad_center_card_invoice_header->AccountNumber, 'account number', 'can get account number');
    is($ad_center_card_invoice_header->ActivityEndDate, '2010-05-31T12:23:34', 'can get 2010-05-31T12:23:34');
    is($ad_center_card_invoice_header->ActivityStartDate, '2010-06-01T12:23:34', 'can get 2010-06-01T12:23:34');
    is($ad_center_card_invoice_header->AttnAddress1, 'attn address1', 'can get attn address1');
    is($ad_center_card_invoice_header->AttnAddress2, 'attn address2', 'can get attn address2');
    is($ad_center_card_invoice_header->AttnAddress3, 'attn address3', 'can get attn address3');
    is($ad_center_card_invoice_header->AttnCity, 'attn city', 'can get attn city');
    is($ad_center_card_invoice_header->AttnName, 'attn name', 'can get attn name');
    is($ad_center_card_invoice_header->AttnPostalCode, 'attn postal code', 'can get attn postal code');
    is($ad_center_card_invoice_header->AttnStateOrProvince, 'attn state or province', 'can get attn state or province');
    is($ad_center_card_invoice_header->BillingInquiriesURL, 'billing inquiries url', 'can get billing inquiries url');
    is($ad_center_card_invoice_header->CountryCode, 'country code', 'can get country code');
    is($ad_center_card_invoice_header->CurrencyCode, 'currency code', 'can get currency code');
    is($ad_center_card_invoice_header->CustomerName, 'customer name', 'can get customer name');
    is($ad_center_card_invoice_header->DocumentType, 'document type', 'can get document type');
    is($ad_center_card_invoice_header->InvoiceNumber, 'invoice number', 'can get invoice number');
    is($ad_center_card_invoice_header->PreferredLanguageId, 'preferred language id', 'can get preferred language id');
    is($ad_center_card_invoice_header->TaxId, 'tax id', 'can get tax id');
    is($ad_center_card_invoice_header->UserLCID, 'user lcid', 'can get user lcid');
};

1;
