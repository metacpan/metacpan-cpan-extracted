package Microsoft::AdCenter::V8::ReportingService::Test::DestinationUrlPerformanceReportFilter;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V8::ReportingService;
use Microsoft::AdCenter::V8::ReportingService::DestinationUrlPerformanceReportFilter;

sub test_can_create_destination_url_performance_report_filter_and_set_all_fields : Test(5) {
    my $destination_url_performance_report_filter = Microsoft::AdCenter::V8::ReportingService::DestinationUrlPerformanceReportFilter->new
        ->AdDistribution('ad distribution')
        ->DeviceType('device type')
        ->LanguageAndRegion('language and region')
        ->LanguageCode('language code')
    ;

    ok($destination_url_performance_report_filter);

    is($destination_url_performance_report_filter->AdDistribution, 'ad distribution', 'can get ad distribution');
    is($destination_url_performance_report_filter->DeviceType, 'device type', 'can get device type');
    is($destination_url_performance_report_filter->LanguageAndRegion, 'language and region', 'can get language and region');
    is($destination_url_performance_report_filter->LanguageCode, 'language code', 'can get language code');
};

1;
