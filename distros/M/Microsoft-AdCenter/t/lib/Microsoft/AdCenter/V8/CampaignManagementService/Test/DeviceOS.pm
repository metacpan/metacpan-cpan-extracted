package Microsoft::AdCenter::V8::CampaignManagementService::Test::DeviceOS;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V8::CampaignManagementService;
use Microsoft::AdCenter::V8::CampaignManagementService::DeviceOS;

sub test_can_create_device_os_and_set_all_fields : Test(3) {
    my $device_os = Microsoft::AdCenter::V8::CampaignManagementService::DeviceOS->new
        ->DeviceName('device name')
        ->OSName('osname')
    ;

    ok($device_os);

    is($device_os->DeviceName, 'device name', 'can get device name');
    is($device_os->OSName, 'osname', 'can get osname');
};

1;
