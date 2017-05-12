package Microsoft::AdCenter::V6::ReportingService::Test::ReportRequest;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V6::ReportingService;
use Microsoft::AdCenter::V6::ReportingService::ReportRequest;

sub test_can_create_report_request_and_set_all_fields : Test(5) {
    my $report_request = Microsoft::AdCenter::V6::ReportingService::ReportRequest->new
        ->Format('format')
        ->Language('language')
        ->ReportName('report name')
        ->ReturnOnlyCompleteData('return only complete data')
    ;

    ok($report_request);

    is($report_request->Format, 'format', 'can get format');
    is($report_request->Language, 'language', 'can get language');
    is($report_request->ReportName, 'report name', 'can get report name');
    is($report_request->ReturnOnlyCompleteData, 'return only complete data', 'can get return only complete data');
};

1;
