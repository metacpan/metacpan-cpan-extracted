package Microsoft::AdCenter::V6::NotificationManagementService::Test::NewUserAddedNotification;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V6::NotificationManagementService;
use Microsoft::AdCenter::V6::NotificationManagementService::NewUserAddedNotification;

sub test_can_create_new_user_added_notification_and_set_all_fields : Test(1) {
    my $new_user_added_notification = Microsoft::AdCenter::V6::NotificationManagementService::NewUserAddedNotification->new
    ;

    ok($new_user_added_notification);

};

1;
