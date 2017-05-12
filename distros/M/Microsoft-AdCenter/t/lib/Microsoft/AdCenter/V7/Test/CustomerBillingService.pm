package Microsoft::AdCenter::V7::Test::CustomerBillingService;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V7::CustomerBillingService;

sub test_can_create_v7_customer_billing_service_and_set_all_fields : Test(7) {
    my $v7_customer_billing_service = Microsoft::AdCenter::V7::CustomerBillingService->new
        ->EndPoint('http://some.where.that/does/not/exists')
        ->ApplicationToken('application token')
        ->DeveloperToken('developer token')
        ->Password('password')
        ->UserName('user name')
        ->TrackingId('tracking id')
    ;

    ok($v7_customer_billing_service);

    is($v7_customer_billing_service->EndPoint, 'http://some.where.that/does/not/exists', 'can get end point');
    is($v7_customer_billing_service->ApplicationToken, 'application token', 'can get application token');
    is($v7_customer_billing_service->DeveloperToken, 'developer token', 'can get developer token');
    is($v7_customer_billing_service->Password, 'password', 'can get password');
    is($v7_customer_billing_service->UserName, 'user name', 'can get user name');
    is($v7_customer_billing_service->TrackingId, 'tracking id', 'can get tracking id');
};

1;
