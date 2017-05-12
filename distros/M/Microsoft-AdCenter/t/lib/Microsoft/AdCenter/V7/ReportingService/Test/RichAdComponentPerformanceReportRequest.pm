package Microsoft::AdCenter::V7::ReportingService::Test::RichAdComponentPerformanceReportRequest;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V7::ReportingService;
use Microsoft::AdCenter::V7::ReportingService::RichAdComponentPerformanceReportRequest;

sub test_can_create_rich_ad_component_performance_report_request_and_set_all_fields : Test(6) {
    my $rich_ad_component_performance_report_request = Microsoft::AdCenter::V7::ReportingService::RichAdComponentPerformanceReportRequest->new
        ->Aggregation('aggregation')
        ->Columns('columns')
        ->Filter('filter')
        ->Scope('scope')
        ->Time('time')
    ;

    ok($rich_ad_component_performance_report_request);

    is($rich_ad_component_performance_report_request->Aggregation, 'aggregation', 'can get aggregation');
    is($rich_ad_component_performance_report_request->Columns, 'columns', 'can get columns');
    is($rich_ad_component_performance_report_request->Filter, 'filter', 'can get filter');
    is($rich_ad_component_performance_report_request->Scope, 'scope', 'can get scope');
    is($rich_ad_component_performance_report_request->Time, 'time', 'can get time');
};

1;
