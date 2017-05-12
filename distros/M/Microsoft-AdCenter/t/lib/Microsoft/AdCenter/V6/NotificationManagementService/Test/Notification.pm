package Microsoft::AdCenter::V6::NotificationManagementService::Test::Notification;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V6::NotificationManagementService;
use Microsoft::AdCenter::V6::NotificationManagementService::Notification;

sub test_can_create_notification_and_set_all_fields : Test(6) {
    my $notification = Microsoft::AdCenter::V6::NotificationManagementService::Notification->new
        ->CustomerId('customer id')
        ->NotificationDate('2010-05-31T12:23:34')
        ->NotificationType('notification type')
        ->RecipientEmailAddress('recipient email address')
        ->UserLocale('user locale')
    ;

    ok($notification);

    is($notification->CustomerId, 'customer id', 'can get customer id');
    is($notification->NotificationDate, '2010-05-31T12:23:34', 'can get 2010-05-31T12:23:34');
    is($notification->NotificationType, 'notification type', 'can get notification type');
    is($notification->RecipientEmailAddress, 'recipient email address', 'can get recipient email address');
    is($notification->UserLocale, 'user locale', 'can get user locale');
};

1;
