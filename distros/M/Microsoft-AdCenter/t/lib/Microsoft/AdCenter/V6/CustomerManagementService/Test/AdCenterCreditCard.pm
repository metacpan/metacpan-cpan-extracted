package Microsoft::AdCenter::V6::CustomerManagementService::Test::AdCenterCreditCard;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V6::CustomerManagementService;
use Microsoft::AdCenter::V6::CustomerManagementService::AdCenterCreditCard;

sub test_can_create_ad_center_credit_card_and_set_all_fields : Test(9) {
    my $ad_center_credit_card = Microsoft::AdCenter::V6::CustomerManagementService::AdCenterCreditCard->new
        ->CreditCardExpirationDate('2010-05-31T12:23:34')
        ->CreditCardFirstName('credit card first name')
        ->CreditCardLastFour('credit card last four')
        ->CreditCardLastName('credit card last name')
        ->CreditCardMiddleInitial('credit card middle initial')
        ->CreditCardNumber('credit card number')
        ->CreditCardSecurityCode('credit card security code')
        ->CreditCardTypeId('credit card type id')
    ;

    ok($ad_center_credit_card);

    is($ad_center_credit_card->CreditCardExpirationDate, '2010-05-31T12:23:34', 'can get 2010-05-31T12:23:34');
    is($ad_center_credit_card->CreditCardFirstName, 'credit card first name', 'can get credit card first name');
    is($ad_center_credit_card->CreditCardLastFour, 'credit card last four', 'can get credit card last four');
    is($ad_center_credit_card->CreditCardLastName, 'credit card last name', 'can get credit card last name');
    is($ad_center_credit_card->CreditCardMiddleInitial, 'credit card middle initial', 'can get credit card middle initial');
    is($ad_center_credit_card->CreditCardNumber, 'credit card number', 'can get credit card number');
    is($ad_center_credit_card->CreditCardSecurityCode, 'credit card security code', 'can get credit card security code');
    is($ad_center_credit_card->CreditCardTypeId, 'credit card type id', 'can get credit card type id');
};

1;
