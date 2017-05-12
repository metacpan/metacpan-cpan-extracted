package Microsoft::AdCenter::V7::ReportingService::Test::BehavioralPerformanceReportFilter;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V7::ReportingService;
use Microsoft::AdCenter::V7::ReportingService::BehavioralPerformanceReportFilter;

sub test_can_create_behavioral_performance_report_filter_and_set_all_fields : Test(6) {
    my $behavioral_performance_report_filter = Microsoft::AdCenter::V7::ReportingService::BehavioralPerformanceReportFilter->new
        ->AdDistribution('ad distribution')
        ->AdType('ad type')
        ->BehavioralIds('behavioral ids')
        ->DeliveredMatchType('delivered match type')
        ->LanguageAndRegion('language and region')
    ;

    ok($behavioral_performance_report_filter);

    is($behavioral_performance_report_filter->AdDistribution, 'ad distribution', 'can get ad distribution');
    is($behavioral_performance_report_filter->AdType, 'ad type', 'can get ad type');
    is($behavioral_performance_report_filter->BehavioralIds, 'behavioral ids', 'can get behavioral ids');
    is($behavioral_performance_report_filter->DeliveredMatchType, 'delivered match type', 'can get delivered match type');
    is($behavioral_performance_report_filter->LanguageAndRegion, 'language and region', 'can get language and region');
};

1;
