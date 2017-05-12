package Microsoft::AdCenter::V6::ReportingService::Test::TrafficSourcesReportFilter;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V6::ReportingService;
use Microsoft::AdCenter::V6::ReportingService::TrafficSourcesReportFilter;

sub test_can_create_traffic_sources_report_filter_and_set_all_fields : Test(2) {
    my $traffic_sources_report_filter = Microsoft::AdCenter::V6::ReportingService::TrafficSourcesReportFilter->new
        ->GoalIds('goal ids')
    ;

    ok($traffic_sources_report_filter);

    is($traffic_sources_report_filter->GoalIds, 'goal ids', 'can get goal ids');
};

1;
