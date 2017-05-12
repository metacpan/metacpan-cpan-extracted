package Microsoft::AdCenter::V7::ReportingService::Test::RichAdComponentPerformanceReportFilter;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V7::ReportingService;
use Microsoft::AdCenter::V7::ReportingService::RichAdComponentPerformanceReportFilter;

sub test_can_create_rich_ad_component_performance_report_filter_and_set_all_fields : Test(3) {
    my $rich_ad_component_performance_report_filter = Microsoft::AdCenter::V7::ReportingService::RichAdComponentPerformanceReportFilter->new
        ->ComponentType('component type')
        ->RichAdSubType('rich ad sub type')
    ;

    ok($rich_ad_component_performance_report_filter);

    is($rich_ad_component_performance_report_filter->ComponentType, 'component type', 'can get component type');
    is($rich_ad_component_performance_report_filter->RichAdSubType, 'rich ad sub type', 'can get rich ad sub type');
};

1;
