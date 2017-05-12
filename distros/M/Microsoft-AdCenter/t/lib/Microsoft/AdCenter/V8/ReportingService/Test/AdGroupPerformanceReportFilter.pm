package Microsoft::AdCenter::V8::ReportingService::Test::AdGroupPerformanceReportFilter;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V8::ReportingService;
use Microsoft::AdCenter::V8::ReportingService::AdGroupPerformanceReportFilter;

sub test_can_create_ad_group_performance_report_filter_and_set_all_fields : Test(6) {
    my $ad_group_performance_report_filter = Microsoft::AdCenter::V8::ReportingService::AdGroupPerformanceReportFilter->new
        ->AdDistribution('ad distribution')
        ->DeviceType('device type')
        ->LanguageAndRegion('language and region')
        ->LanguageCode('language code')
        ->Status('status')
    ;

    ok($ad_group_performance_report_filter);

    is($ad_group_performance_report_filter->AdDistribution, 'ad distribution', 'can get ad distribution');
    is($ad_group_performance_report_filter->DeviceType, 'device type', 'can get device type');
    is($ad_group_performance_report_filter->LanguageAndRegion, 'language and region', 'can get language and region');
    is($ad_group_performance_report_filter->LanguageCode, 'language code', 'can get language code');
    is($ad_group_performance_report_filter->Status, 'status', 'can get status');
};

1;
