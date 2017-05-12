package Microsoft::AdCenter::V8::CampaignManagementService::Test::AdExtensionIdToCampaignIdAssociation;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V8::CampaignManagementService;
use Microsoft::AdCenter::V8::CampaignManagementService::AdExtensionIdToCampaignIdAssociation;

sub test_can_create_ad_extension_id_to_campaign_id_association_and_set_all_fields : Test(3) {
    my $ad_extension_id_to_campaign_id_association = Microsoft::AdCenter::V8::CampaignManagementService::AdExtensionIdToCampaignIdAssociation->new
        ->AdExtensionId('ad extension id')
        ->CampaignId('campaign id')
    ;

    ok($ad_extension_id_to_campaign_id_association);

    is($ad_extension_id_to_campaign_id_association->AdExtensionId, 'ad extension id', 'can get ad extension id');
    is($ad_extension_id_to_campaign_id_association->CampaignId, 'campaign id', 'can get campaign id');
};

1;
