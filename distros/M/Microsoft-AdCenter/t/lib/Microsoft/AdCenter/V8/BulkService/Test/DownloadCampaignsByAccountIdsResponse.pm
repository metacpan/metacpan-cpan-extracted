package Microsoft::AdCenter::V8::BulkService::Test::DownloadCampaignsByAccountIdsResponse;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V8::BulkService;
use Microsoft::AdCenter::V8::BulkService::DownloadCampaignsByAccountIdsResponse;

sub test_can_create_download_campaigns_by_account_ids_response_and_set_all_fields : Test(2) {
    my $download_campaigns_by_account_ids_response = Microsoft::AdCenter::V8::BulkService::DownloadCampaignsByAccountIdsResponse->new
        ->DownloadRequestId('download request id')
    ;

    ok($download_campaigns_by_account_ids_response);

    is($download_campaigns_by_account_ids_response->DownloadRequestId, 'download request id', 'can get download request id');
};

1;
