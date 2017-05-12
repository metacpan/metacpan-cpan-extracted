package Microsoft::AdCenter::V7::ReportingService::Test::PublisherUsagePerformanceReportFilter;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V7::ReportingService;
use Microsoft::AdCenter::V7::ReportingService::PublisherUsagePerformanceReportFilter;

sub test_can_create_publisher_usage_performance_report_filter_and_set_all_fields : Test(4) {
    my $publisher_usage_performance_report_filter = Microsoft::AdCenter::V7::ReportingService::PublisherUsagePerformanceReportFilter->new
        ->AdDistribution('ad distribution')
        ->LanguageAndRegion('language and region')
        ->LanguageCode('language code')
    ;

    ok($publisher_usage_performance_report_filter);

    is($publisher_usage_performance_report_filter->AdDistribution, 'ad distribution', 'can get ad distribution');
    is($publisher_usage_performance_report_filter->LanguageAndRegion, 'language and region', 'can get language and region');
    is($publisher_usage_performance_report_filter->LanguageCode, 'language code', 'can get language code');
};

1;
