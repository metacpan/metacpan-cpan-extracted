package Microsoft::AdCenter::V8::CampaignManagementService::Test::GetAdRotationByAdGroupIdsResponse;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V8::CampaignManagementService;
use Microsoft::AdCenter::V8::CampaignManagementService::GetAdRotationByAdGroupIdsResponse;

sub test_can_create_get_ad_rotation_by_ad_group_ids_response_and_set_all_fields : Test(2) {
    my $get_ad_rotation_by_ad_group_ids_response = Microsoft::AdCenter::V8::CampaignManagementService::GetAdRotationByAdGroupIdsResponse->new
        ->AdRotationByAdGroupIds('ad rotation by ad group ids')
    ;

    ok($get_ad_rotation_by_ad_group_ids_response);

    is($get_ad_rotation_by_ad_group_ids_response->AdRotationByAdGroupIds, 'ad rotation by ad group ids', 'can get ad rotation by ad group ids');
};

1;
