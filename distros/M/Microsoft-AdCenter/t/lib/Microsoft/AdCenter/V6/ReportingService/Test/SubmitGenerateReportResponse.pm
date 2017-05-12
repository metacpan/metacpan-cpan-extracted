package Microsoft::AdCenter::V6::ReportingService::Test::SubmitGenerateReportResponse;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V6::ReportingService;
use Microsoft::AdCenter::V6::ReportingService::SubmitGenerateReportResponse;

sub test_can_create_submit_generate_report_response_and_set_all_fields : Test(2) {
    my $submit_generate_report_response = Microsoft::AdCenter::V6::ReportingService::SubmitGenerateReportResponse->new
        ->ReportRequestId('report request id')
    ;

    ok($submit_generate_report_response);

    is($submit_generate_report_response->ReportRequestId, 'report request id', 'can get report request id');
};

1;
