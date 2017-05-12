package Microsoft::AdCenter::V8::BulkService::Test::GetDownloadStatusResponse;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V8::BulkService;
use Microsoft::AdCenter::V8::BulkService::GetDownloadStatusResponse;

sub test_can_create_get_download_status_response_and_set_all_fields : Test(3) {
    my $get_download_status_response = Microsoft::AdCenter::V8::BulkService::GetDownloadStatusResponse->new
        ->DownloadUrl('download url')
        ->Status('status')
    ;

    ok($get_download_status_response);

    is($get_download_status_response->DownloadUrl, 'download url', 'can get download url');
    is($get_download_status_response->Status, 'status', 'can get status');
};

1;
