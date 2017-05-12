package Microsoft::AdCenter::V6::ReportingService::Test::MetroAreaDemographicReportFilter;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V6::ReportingService;
use Microsoft::AdCenter::V6::ReportingService::MetroAreaDemographicReportFilter;

sub test_can_create_metro_area_demographic_report_filter_and_set_all_fields : Test(4) {
    my $metro_area_demographic_report_filter = Microsoft::AdCenter::V6::ReportingService::MetroAreaDemographicReportFilter->new
        ->AdDistribution('ad distribution')
        ->Country('country')
        ->LanguageAndRegion('language and region')
    ;

    ok($metro_area_demographic_report_filter);

    is($metro_area_demographic_report_filter->AdDistribution, 'ad distribution', 'can get ad distribution');
    is($metro_area_demographic_report_filter->Country, 'country', 'can get country');
    is($metro_area_demographic_report_filter->LanguageAndRegion, 'language and region', 'can get language and region');
};

1;
