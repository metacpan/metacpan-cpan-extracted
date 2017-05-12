package Microsoft::AdCenter::V7::ReportingService::Test::SearchQueryPerformanceReportRequest;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V7::ReportingService;
use Microsoft::AdCenter::V7::ReportingService::SearchQueryPerformanceReportRequest;

sub test_can_create_search_query_performance_report_request_and_set_all_fields : Test(6) {
    my $search_query_performance_report_request = Microsoft::AdCenter::V7::ReportingService::SearchQueryPerformanceReportRequest->new
        ->Aggregation('aggregation')
        ->Columns('columns')
        ->Filter('filter')
        ->Scope('scope')
        ->Time('time')
    ;

    ok($search_query_performance_report_request);

    is($search_query_performance_report_request->Aggregation, 'aggregation', 'can get aggregation');
    is($search_query_performance_report_request->Columns, 'columns', 'can get columns');
    is($search_query_performance_report_request->Filter, 'filter', 'can get filter');
    is($search_query_performance_report_request->Scope, 'scope', 'can get scope');
    is($search_query_performance_report_request->Time, 'time', 'can get time');
};

1;
