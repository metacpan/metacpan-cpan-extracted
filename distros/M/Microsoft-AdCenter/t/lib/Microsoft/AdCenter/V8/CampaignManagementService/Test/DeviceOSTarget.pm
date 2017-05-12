package Microsoft::AdCenter::V8::CampaignManagementService::Test::DeviceOSTarget;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V8::CampaignManagementService;
use Microsoft::AdCenter::V8::CampaignManagementService::DeviceOSTarget;

sub test_can_create_device_ostarget_and_set_all_fields : Test(2) {
    my $device_ostarget = Microsoft::AdCenter::V8::CampaignManagementService::DeviceOSTarget->new
        ->DeviceOSList('device oslist')
    ;

    ok($device_ostarget);

    is($device_ostarget->DeviceOSList, 'device oslist', 'can get device oslist');
};

1;
