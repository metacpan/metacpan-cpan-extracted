package Microsoft::AdCenter::V8::CampaignManagementService::Test::CampaignAdExtension;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V8::CampaignManagementService;
use Microsoft::AdCenter::V8::CampaignManagementService::CampaignAdExtension;

sub test_can_create_campaign_ad_extension_and_set_all_fields : Test(4) {
    my $campaign_ad_extension = Microsoft::AdCenter::V8::CampaignManagementService::CampaignAdExtension->new
        ->AdExtension('ad extension')
        ->CampaignId('campaign id')
        ->EditorialStatus('editorial status')
    ;

    ok($campaign_ad_extension);

    is($campaign_ad_extension->AdExtension, 'ad extension', 'can get ad extension');
    is($campaign_ad_extension->CampaignId, 'campaign id', 'can get campaign id');
    is($campaign_ad_extension->EditorialStatus, 'editorial status', 'can get editorial status');
};

1;
