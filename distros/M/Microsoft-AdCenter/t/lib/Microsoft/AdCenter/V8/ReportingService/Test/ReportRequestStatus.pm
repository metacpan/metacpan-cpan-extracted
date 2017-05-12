package Microsoft::AdCenter::V8::ReportingService::Test::ReportRequestStatus;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V8::ReportingService;
use Microsoft::AdCenter::V8::ReportingService::ReportRequestStatus;

sub test_can_create_report_request_status_and_set_all_fields : Test(3) {
    my $report_request_status = Microsoft::AdCenter::V8::ReportingService::ReportRequestStatus->new
        ->ReportDownloadUrl('report download url')
        ->Status('status')
    ;

    ok($report_request_status);

    is($report_request_status->ReportDownloadUrl, 'report download url', 'can get report download url');
    is($report_request_status->Status, 'status', 'can get status');
};

1;
