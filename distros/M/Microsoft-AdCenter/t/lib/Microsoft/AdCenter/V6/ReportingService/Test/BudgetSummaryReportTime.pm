package Microsoft::AdCenter::V6::ReportingService::Test::BudgetSummaryReportTime;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V6::ReportingService;
use Microsoft::AdCenter::V6::ReportingService::BudgetSummaryReportTime;

sub test_can_create_budget_summary_report_time_and_set_all_fields : Test(5) {
    my $budget_summary_report_time = Microsoft::AdCenter::V6::ReportingService::BudgetSummaryReportTime->new
        ->CustomDateRangeEnd('custom date range end')
        ->CustomDateRangeStart('custom date range start')
        ->CustomDates('custom dates')
        ->PredefinedTime('predefined time')
    ;

    ok($budget_summary_report_time);

    is($budget_summary_report_time->CustomDateRangeEnd, 'custom date range end', 'can get custom date range end');
    is($budget_summary_report_time->CustomDateRangeStart, 'custom date range start', 'can get custom date range start');
    is($budget_summary_report_time->CustomDates, 'custom dates', 'can get custom dates');
    is($budget_summary_report_time->PredefinedTime, 'predefined time', 'can get predefined time');
};

1;
