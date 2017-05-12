package Microsoft::AdCenter::V8::ReportingService::Test::AdExtensionDimensionReportRequest;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V8::ReportingService;
use Microsoft::AdCenter::V8::ReportingService::AdExtensionDimensionReportRequest;

sub test_can_create_ad_extension_dimension_report_request_and_set_all_fields : Test(3) {
    my $ad_extension_dimension_report_request = Microsoft::AdCenter::V8::ReportingService::AdExtensionDimensionReportRequest->new
        ->Columns('columns')
        ->Scope('scope')
    ;

    ok($ad_extension_dimension_report_request);

    is($ad_extension_dimension_report_request->Columns, 'columns', 'can get columns');
    is($ad_extension_dimension_report_request->Scope, 'scope', 'can get scope');
};

1;
