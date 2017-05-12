package Microsoft::AdCenter::V8::CampaignManagementService::Test::DownloadCampaignHierarchyResponse;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V8::CampaignManagementService;
use Microsoft::AdCenter::V8::CampaignManagementService::DownloadCampaignHierarchyResponse;

sub test_can_create_download_campaign_hierarchy_response_and_set_all_fields : Test(2) {
    my $download_campaign_hierarchy_response = Microsoft::AdCenter::V8::CampaignManagementService::DownloadCampaignHierarchyResponse->new
        ->DownloadRequestId('download request id')
    ;

    ok($download_campaign_hierarchy_response);

    is($download_campaign_hierarchy_response->DownloadRequestId, 'download request id', 'can get download request id');
};

1;
