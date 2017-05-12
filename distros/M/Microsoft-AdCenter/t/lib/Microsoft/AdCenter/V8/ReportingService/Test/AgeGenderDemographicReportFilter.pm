package Microsoft::AdCenter::V8::ReportingService::Test::AgeGenderDemographicReportFilter;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V8::ReportingService;
use Microsoft::AdCenter::V8::ReportingService::AgeGenderDemographicReportFilter;

sub test_can_create_age_gender_demographic_report_filter_and_set_all_fields : Test(4) {
    my $age_gender_demographic_report_filter = Microsoft::AdCenter::V8::ReportingService::AgeGenderDemographicReportFilter->new
        ->AdDistribution('ad distribution')
        ->LanguageAndRegion('language and region')
        ->LanguageCode('language code')
    ;

    ok($age_gender_demographic_report_filter);

    is($age_gender_demographic_report_filter->AdDistribution, 'ad distribution', 'can get ad distribution');
    is($age_gender_demographic_report_filter->LanguageAndRegion, 'language and region', 'can get language and region');
    is($age_gender_demographic_report_filter->LanguageCode, 'language code', 'can get language code');
};

1;
