package Microsoft::AdCenter::V8::NotificationService::Test::CreditCardPendingExpirationNotification;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V8::NotificationService;
use Microsoft::AdCenter::V8::NotificationService::CreditCardPendingExpirationNotification;

sub test_can_create_credit_card_pending_expiration_notification_and_set_all_fields : Test(4) {
    my $credit_card_pending_expiration_notification = Microsoft::AdCenter::V8::NotificationService::CreditCardPendingExpirationNotification->new
        ->AccountName('account name')
        ->CardType('card type')
        ->LastFourDigits('last four digits')
    ;

    ok($credit_card_pending_expiration_notification);

    is($credit_card_pending_expiration_notification->AccountName, 'account name', 'can get account name');
    is($credit_card_pending_expiration_notification->CardType, 'card type', 'can get card type');
    is($credit_card_pending_expiration_notification->LastFourDigits, 'last four digits', 'can get last four digits');
};

1;
