package Microsoft::AdCenter::V6::ReportingService::Test::AgeGenderDemographicReportRequest;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V6::ReportingService;
use Microsoft::AdCenter::V6::ReportingService::AgeGenderDemographicReportRequest;

sub test_can_create_age_gender_demographic_report_request_and_set_all_fields : Test(6) {
    my $age_gender_demographic_report_request = Microsoft::AdCenter::V6::ReportingService::AgeGenderDemographicReportRequest->new
        ->Aggregation('aggregation')
        ->Columns('columns')
        ->Filter('filter')
        ->Scope('scope')
        ->Time('time')
    ;

    ok($age_gender_demographic_report_request);

    is($age_gender_demographic_report_request->Aggregation, 'aggregation', 'can get aggregation');
    is($age_gender_demographic_report_request->Columns, 'columns', 'can get columns');
    is($age_gender_demographic_report_request->Filter, 'filter', 'can get filter');
    is($age_gender_demographic_report_request->Scope, 'scope', 'can get scope');
    is($age_gender_demographic_report_request->Time, 'time', 'can get time');
};

1;
