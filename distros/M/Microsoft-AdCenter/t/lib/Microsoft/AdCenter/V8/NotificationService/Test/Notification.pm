package Microsoft::AdCenter::V8::NotificationService::Test::Notification;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V8::NotificationService;
use Microsoft::AdCenter::V8::NotificationService::Notification;

sub test_can_create_notification_and_set_all_fields : Test(4) {
    my $notification = Microsoft::AdCenter::V8::NotificationService::Notification->new
        ->NotificationDate('2010-05-31T12:23:34')
        ->NotificationId('notification id')
        ->NotificationType('notification type')
    ;

    ok($notification);

    is($notification->NotificationDate, '2010-05-31T12:23:34', 'can get 2010-05-31T12:23:34');
    is($notification->NotificationId, 'notification id', 'can get notification id');
    is($notification->NotificationType, 'notification type', 'can get notification type');
};

1;
