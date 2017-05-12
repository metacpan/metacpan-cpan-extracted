package Microsoft::AdCenter::V6::NotificationManagementService::Test::UserNameReminderNotification;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V6::NotificationManagementService;
use Microsoft::AdCenter::V6::NotificationManagementService::UserNameReminderNotification;

sub test_can_create_user_name_reminder_notification_and_set_all_fields : Test(1) {
    my $user_name_reminder_notification = Microsoft::AdCenter::V6::NotificationManagementService::UserNameReminderNotification->new
    ;

    ok($user_name_reminder_notification);

};

1;
