package Microsoft::AdCenter::V6::NotificationManagementService::Test::ApproachingCreditCardExpirationNotification;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V6::NotificationManagementService;
use Microsoft::AdCenter::V6::NotificationManagementService::ApproachingCreditCardExpirationNotification;

sub test_can_create_approaching_credit_card_expiration_notification_and_set_all_fields : Test(1) {
    my $approaching_credit_card_expiration_notification = Microsoft::AdCenter::V6::NotificationManagementService::ApproachingCreditCardExpirationNotification->new
    ;

    ok($approaching_credit_card_expiration_notification);

};

1;
