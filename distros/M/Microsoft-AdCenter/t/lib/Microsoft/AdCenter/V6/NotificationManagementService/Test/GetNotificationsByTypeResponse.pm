package Microsoft::AdCenter::V6::NotificationManagementService::Test::GetNotificationsByTypeResponse;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V6::NotificationManagementService;
use Microsoft::AdCenter::V6::NotificationManagementService::GetNotificationsByTypeResponse;

sub test_can_create_get_notifications_by_type_response_and_set_all_fields : Test(2) {
    my $get_notifications_by_type_response = Microsoft::AdCenter::V6::NotificationManagementService::GetNotificationsByTypeResponse->new
        ->GetNotificationsByTypeResult('get notifications by type result')
    ;

    ok($get_notifications_by_type_response);

    is($get_notifications_by_type_response->GetNotificationsByTypeResult, 'get notifications by type result', 'can get get notifications by type result');
};

1;
