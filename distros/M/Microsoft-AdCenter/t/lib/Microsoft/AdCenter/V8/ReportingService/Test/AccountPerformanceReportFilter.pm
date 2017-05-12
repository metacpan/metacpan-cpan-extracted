package Microsoft::AdCenter::V8::ReportingService::Test::AccountPerformanceReportFilter;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V8::ReportingService;
use Microsoft::AdCenter::V8::ReportingService::AccountPerformanceReportFilter;

sub test_can_create_account_performance_report_filter_and_set_all_fields : Test(3) {
    my $account_performance_report_filter = Microsoft::AdCenter::V8::ReportingService::AccountPerformanceReportFilter->new
        ->AdDistribution('ad distribution')
        ->DeviceType('device type')
    ;

    ok($account_performance_report_filter);

    is($account_performance_report_filter->AdDistribution, 'ad distribution', 'can get ad distribution');
    is($account_performance_report_filter->DeviceType, 'device type', 'can get device type');
};

1;
