package Microsoft::AdCenter::V8::Test::NotificationService;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V8::NotificationService;

sub test_can_create_v8_notification_service_and_set_all_fields : Test(7) {
    my $v8_notification_service = Microsoft::AdCenter::V8::NotificationService->new
        ->EndPoint('http://some.where.that/does/not/exists')
        ->ApplicationToken('application token')
        ->DeveloperToken('developer token')
        ->Password('password')
        ->UserName('user name')
        ->TrackingId('tracking id')
    ;

    ok($v8_notification_service);

    is($v8_notification_service->EndPoint, 'http://some.where.that/does/not/exists', 'can get end point');
    is($v8_notification_service->ApplicationToken, 'application token', 'can get application token');
    is($v8_notification_service->DeveloperToken, 'developer token', 'can get developer token');
    is($v8_notification_service->Password, 'password', 'can get password');
    is($v8_notification_service->UserName, 'user name', 'can get user name');
    is($v8_notification_service->TrackingId, 'tracking id', 'can get tracking id');
};

1;
