package Microsoft::AdCenter::V8::ReportingService::Test::SitePerformanceReportFilter;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V8::ReportingService;
use Microsoft::AdCenter::V8::ReportingService::SitePerformanceReportFilter;

sub test_can_create_site_performance_report_filter_and_set_all_fields : Test(7) {
    my $site_performance_report_filter = Microsoft::AdCenter::V8::ReportingService::SitePerformanceReportFilter->new
        ->AdDistribution('ad distribution')
        ->AdType('ad type')
        ->DeliveredMatchType('delivered match type')
        ->DeviceType('device type')
        ->LanguageAndRegion('language and region')
        ->SiteIds('site ids')
    ;

    ok($site_performance_report_filter);

    is($site_performance_report_filter->AdDistribution, 'ad distribution', 'can get ad distribution');
    is($site_performance_report_filter->AdType, 'ad type', 'can get ad type');
    is($site_performance_report_filter->DeliveredMatchType, 'delivered match type', 'can get delivered match type');
    is($site_performance_report_filter->DeviceType, 'device type', 'can get device type');
    is($site_performance_report_filter->LanguageAndRegion, 'language and region', 'can get language and region');
    is($site_performance_report_filter->SiteIds, 'site ids', 'can get site ids');
};

1;
