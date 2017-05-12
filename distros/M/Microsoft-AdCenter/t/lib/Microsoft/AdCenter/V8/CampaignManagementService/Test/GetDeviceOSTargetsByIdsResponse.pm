package Microsoft::AdCenter::V8::CampaignManagementService::Test::GetDeviceOSTargetsByIdsResponse;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V8::CampaignManagementService;
use Microsoft::AdCenter::V8::CampaignManagementService::GetDeviceOSTargetsByIdsResponse;

sub test_can_create_get_device_ostargets_by_ids_response_and_set_all_fields : Test(2) {
    my $get_device_ostargets_by_ids_response = Microsoft::AdCenter::V8::CampaignManagementService::GetDeviceOSTargetsByIdsResponse->new
        ->TargetAssociations('target associations')
    ;

    ok($get_device_ostargets_by_ids_response);

    is($get_device_ostargets_by_ids_response->TargetAssociations, 'target associations', 'can get target associations');
};

1;
