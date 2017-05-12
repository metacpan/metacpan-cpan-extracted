package Microsoft::AdCenter::V7::Test::CampaignManagementService;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V7::CampaignManagementService;

sub test_can_create_v7_campaign_management_service_and_set_all_fields : Test(9) {
    my $v7_campaign_management_service = Microsoft::AdCenter::V7::CampaignManagementService->new
        ->EndPoint('http://some.where.that/does/not/exists')
        ->ApplicationToken('application token')
        ->CustomerAccountId('customer account id')
        ->CustomerId('customer id')
        ->DeveloperToken('developer token')
        ->Password('password')
        ->UserName('user name')
        ->TrackingId('tracking id')
    ;

    ok($v7_campaign_management_service);

    is($v7_campaign_management_service->EndPoint, 'http://some.where.that/does/not/exists', 'can get end point');
    is($v7_campaign_management_service->ApplicationToken, 'application token', 'can get application token');
    is($v7_campaign_management_service->CustomerAccountId, 'customer account id', 'can get customer account id');
    is($v7_campaign_management_service->CustomerId, 'customer id', 'can get customer id');
    is($v7_campaign_management_service->DeveloperToken, 'developer token', 'can get developer token');
    is($v7_campaign_management_service->Password, 'password', 'can get password');
    is($v7_campaign_management_service->UserName, 'user name', 'can get user name');
    is($v7_campaign_management_service->TrackingId, 'tracking id', 'can get tracking id');
};

1;
