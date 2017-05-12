package Microsoft::AdCenter::V6::NotificationManagementService::Test::UserNotification;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V6::NotificationManagementService;
use Microsoft::AdCenter::V6::NotificationManagementService::UserNotification;

sub test_can_create_user_notification_and_set_all_fields : Test(4) {
    my $user_notification = Microsoft::AdCenter::V6::NotificationManagementService::UserNotification->new
        ->ActivationCode('activation code')
        ->UserId('user id')
        ->UserName('user name')
    ;

    ok($user_notification);

    is($user_notification->ActivationCode, 'activation code', 'can get activation code');
    is($user_notification->UserId, 'user id', 'can get user id');
    is($user_notification->UserName, 'user name', 'can get user name');
};

1;
