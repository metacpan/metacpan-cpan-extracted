package Microsoft::AdCenter::V7::ReportingService::Test::BehavioralTargetReportFilter;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V7::ReportingService;
use Microsoft::AdCenter::V7::ReportingService::BehavioralTargetReportFilter;

sub test_can_create_behavioral_target_report_filter_and_set_all_fields : Test(4) {
    my $behavioral_target_report_filter = Microsoft::AdCenter::V7::ReportingService::BehavioralTargetReportFilter->new
        ->AdDistribution('ad distribution')
        ->BehavioralIds('behavioral ids')
        ->LanguageAndRegion('language and region')
    ;

    ok($behavioral_target_report_filter);

    is($behavioral_target_report_filter->AdDistribution, 'ad distribution', 'can get ad distribution');
    is($behavioral_target_report_filter->BehavioralIds, 'behavioral ids', 'can get behavioral ids');
    is($behavioral_target_report_filter->LanguageAndRegion, 'language and region', 'can get language and region');
};

1;
