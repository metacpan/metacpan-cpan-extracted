package Microsoft::AdCenter::V8::CampaignManagementService::Test::AdGroupNegativeSites;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V8::CampaignManagementService;
use Microsoft::AdCenter::V8::CampaignManagementService::AdGroupNegativeSites;

sub test_can_create_ad_group_negative_sites_and_set_all_fields : Test(3) {
    my $ad_group_negative_sites = Microsoft::AdCenter::V8::CampaignManagementService::AdGroupNegativeSites->new
        ->AdGroupId('ad group id')
        ->NegativeSites('negative sites')
    ;

    ok($ad_group_negative_sites);

    is($ad_group_negative_sites->AdGroupId, 'ad group id', 'can get ad group id');
    is($ad_group_negative_sites->NegativeSites, 'negative sites', 'can get negative sites');
};

1;
