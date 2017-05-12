package Microsoft::AdCenter::V8::CampaignManagementService::Test::CampaignAdExtensionCollection;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V8::CampaignManagementService;
use Microsoft::AdCenter::V8::CampaignManagementService::CampaignAdExtensionCollection;

sub test_can_create_campaign_ad_extension_collection_and_set_all_fields : Test(2) {
    my $campaign_ad_extension_collection = Microsoft::AdCenter::V8::CampaignManagementService::CampaignAdExtensionCollection->new
        ->CampaignAdExtensions('campaign ad extensions')
    ;

    ok($campaign_ad_extension_collection);

    is($campaign_ad_extension_collection->CampaignAdExtensions, 'campaign ad extensions', 'can get campaign ad extensions');
};

1;
