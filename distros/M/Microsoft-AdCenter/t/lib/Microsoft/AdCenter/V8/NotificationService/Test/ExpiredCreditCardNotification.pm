package Microsoft::AdCenter::V8::NotificationService::Test::ExpiredCreditCardNotification;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V8::NotificationService;
use Microsoft::AdCenter::V8::NotificationService::ExpiredCreditCardNotification;

sub test_can_create_expired_credit_card_notification_and_set_all_fields : Test(4) {
    my $expired_credit_card_notification = Microsoft::AdCenter::V8::NotificationService::ExpiredCreditCardNotification->new
        ->AccountName('account name')
        ->CardType('card type')
        ->LastFourDigits('last four digits')
    ;

    ok($expired_credit_card_notification);

    is($expired_credit_card_notification->AccountName, 'account name', 'can get account name');
    is($expired_credit_card_notification->CardType, 'card type', 'can get card type');
    is($expired_credit_card_notification->LastFourDigits, 'last four digits', 'can get last four digits');
};

1;
