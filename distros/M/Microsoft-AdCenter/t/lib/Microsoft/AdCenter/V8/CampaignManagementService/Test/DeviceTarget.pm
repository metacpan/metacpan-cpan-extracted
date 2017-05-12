package Microsoft::AdCenter::V8::CampaignManagementService::Test::DeviceTarget;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V8::CampaignManagementService;
use Microsoft::AdCenter::V8::CampaignManagementService::DeviceTarget;

sub test_can_create_device_target_and_set_all_fields : Test(2) {
    my $device_target = Microsoft::AdCenter::V8::CampaignManagementService::DeviceTarget->new
        ->Devices('devices')
    ;

    ok($device_target);

    is($device_target->Devices, 'devices', 'can get devices');
};

1;
