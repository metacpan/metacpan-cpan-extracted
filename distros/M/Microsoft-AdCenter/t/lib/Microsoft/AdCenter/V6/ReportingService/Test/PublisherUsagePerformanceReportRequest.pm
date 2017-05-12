package Microsoft::AdCenter::V6::ReportingService::Test::PublisherUsagePerformanceReportRequest;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V6::ReportingService;
use Microsoft::AdCenter::V6::ReportingService::PublisherUsagePerformanceReportRequest;

sub test_can_create_publisher_usage_performance_report_request_and_set_all_fields : Test(6) {
    my $publisher_usage_performance_report_request = Microsoft::AdCenter::V6::ReportingService::PublisherUsagePerformanceReportRequest->new
        ->Aggregation('aggregation')
        ->Columns('columns')
        ->Filter('filter')
        ->Scope('scope')
        ->Time('time')
    ;

    ok($publisher_usage_performance_report_request);

    is($publisher_usage_performance_report_request->Aggregation, 'aggregation', 'can get aggregation');
    is($publisher_usage_performance_report_request->Columns, 'columns', 'can get columns');
    is($publisher_usage_performance_report_request->Filter, 'filter', 'can get filter');
    is($publisher_usage_performance_report_request->Scope, 'scope', 'can get scope');
    is($publisher_usage_performance_report_request->Time, 'time', 'can get time');
};

1;
