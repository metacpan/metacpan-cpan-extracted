package Microsoft::AdCenter::V8::ReportingService::Test::GoalsAndFunnelsReportRequest;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V8::ReportingService;
use Microsoft::AdCenter::V8::ReportingService::GoalsAndFunnelsReportRequest;

sub test_can_create_goals_and_funnels_report_request_and_set_all_fields : Test(6) {
    my $goals_and_funnels_report_request = Microsoft::AdCenter::V8::ReportingService::GoalsAndFunnelsReportRequest->new
        ->Aggregation('aggregation')
        ->Columns('columns')
        ->Filter('filter')
        ->Scope('scope')
        ->Time('time')
    ;

    ok($goals_and_funnels_report_request);

    is($goals_and_funnels_report_request->Aggregation, 'aggregation', 'can get aggregation');
    is($goals_and_funnels_report_request->Columns, 'columns', 'can get columns');
    is($goals_and_funnels_report_request->Filter, 'filter', 'can get filter');
    is($goals_and_funnels_report_request->Scope, 'scope', 'can get scope');
    is($goals_and_funnels_report_request->Time, 'time', 'can get time');
};

1;
