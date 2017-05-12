package Microsoft::AdCenter::V6::NotificationManagementService::Test::CreditCardExpiredNotification;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V6::NotificationManagementService;
use Microsoft::AdCenter::V6::NotificationManagementService::CreditCardExpiredNotification;

sub test_can_create_credit_card_expired_notification_and_set_all_fields : Test(1) {
    my $credit_card_expired_notification = Microsoft::AdCenter::V6::NotificationManagementService::CreditCardExpiredNotification->new
    ;

    ok($credit_card_expired_notification);

};

1;
