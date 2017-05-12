package Microsoft::AdCenter::V7::ReportingService::Test::AdPerformanceReportFilter;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V7::ReportingService;
use Microsoft::AdCenter::V7::ReportingService::AdPerformanceReportFilter;

sub test_can_create_ad_performance_report_filter_and_set_all_fields : Test(6) {
    my $ad_performance_report_filter = Microsoft::AdCenter::V7::ReportingService::AdPerformanceReportFilter->new
        ->AdDistribution('ad distribution')
        ->AdType('ad type')
        ->DeviceType('device type')
        ->LanguageAndRegion('language and region')
        ->LanguageCode('language code')
    ;

    ok($ad_performance_report_filter);

    is($ad_performance_report_filter->AdDistribution, 'ad distribution', 'can get ad distribution');
    is($ad_performance_report_filter->AdType, 'ad type', 'can get ad type');
    is($ad_performance_report_filter->DeviceType, 'device type', 'can get device type');
    is($ad_performance_report_filter->LanguageAndRegion, 'language and region', 'can get language and region');
    is($ad_performance_report_filter->LanguageCode, 'language code', 'can get language code');
};

1;
