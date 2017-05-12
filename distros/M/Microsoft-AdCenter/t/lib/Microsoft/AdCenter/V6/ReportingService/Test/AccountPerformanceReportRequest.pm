package Microsoft::AdCenter::V6::ReportingService::Test::AccountPerformanceReportRequest;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V6::ReportingService;
use Microsoft::AdCenter::V6::ReportingService::AccountPerformanceReportRequest;

sub test_can_create_account_performance_report_request_and_set_all_fields : Test(6) {
    my $account_performance_report_request = Microsoft::AdCenter::V6::ReportingService::AccountPerformanceReportRequest->new
        ->Aggregation('aggregation')
        ->Columns('columns')
        ->Filter('filter')
        ->Scope('scope')
        ->Time('time')
    ;

    ok($account_performance_report_request);

    is($account_performance_report_request->Aggregation, 'aggregation', 'can get aggregation');
    is($account_performance_report_request->Columns, 'columns', 'can get columns');
    is($account_performance_report_request->Filter, 'filter', 'can get filter');
    is($account_performance_report_request->Scope, 'scope', 'can get scope');
    is($account_performance_report_request->Time, 'time', 'can get time');
};

1;
