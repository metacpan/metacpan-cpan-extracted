package Microsoft::AdCenter::V6::ReportingService::Test::DestinationUrlPerformanceReportFilter;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V6::ReportingService;
use Microsoft::AdCenter::V6::ReportingService::DestinationUrlPerformanceReportFilter;

sub test_can_create_destination_url_performance_report_filter_and_set_all_fields : Test(3) {
    my $destination_url_performance_report_filter = Microsoft::AdCenter::V6::ReportingService::DestinationUrlPerformanceReportFilter->new
        ->AdDistribution('ad distribution')
        ->LanguageAndRegion('language and region')
    ;

    ok($destination_url_performance_report_filter);

    is($destination_url_performance_report_filter->AdDistribution, 'ad distribution', 'can get ad distribution');
    is($destination_url_performance_report_filter->LanguageAndRegion, 'language and region', 'can get language and region');
};

1;
