package Microsoft::AdCenter::V8::CampaignManagementService::Test::CampaignNegativeSites;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V8::CampaignManagementService;
use Microsoft::AdCenter::V8::CampaignManagementService::CampaignNegativeSites;

sub test_can_create_campaign_negative_sites_and_set_all_fields : Test(3) {
    my $campaign_negative_sites = Microsoft::AdCenter::V8::CampaignManagementService::CampaignNegativeSites->new
        ->CampaignId('campaign id')
        ->NegativeSites('negative sites')
    ;

    ok($campaign_negative_sites);

    is($campaign_negative_sites->CampaignId, 'campaign id', 'can get campaign id');
    is($campaign_negative_sites->NegativeSites, 'negative sites', 'can get negative sites');
};

1;
