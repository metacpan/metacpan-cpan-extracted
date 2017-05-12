package Microsoft::AdCenter::V8::CampaignManagementService::Test::AdGroupAdRotation;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V8::CampaignManagementService;
use Microsoft::AdCenter::V8::CampaignManagementService::AdGroupAdRotation;

sub test_can_create_ad_group_ad_rotation_and_set_all_fields : Test(3) {
    my $ad_group_ad_rotation = Microsoft::AdCenter::V8::CampaignManagementService::AdGroupAdRotation->new
        ->AdGroupId('ad group id')
        ->AdRotation('ad rotation')
    ;

    ok($ad_group_ad_rotation);

    is($ad_group_ad_rotation->AdGroupId, 'ad group id', 'can get ad group id');
    is($ad_group_ad_rotation->AdRotation, 'ad rotation', 'can get ad rotation');
};

1;
