package Microsoft::AdCenter::V7::ReportingService::Test::ReportTime;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V7::ReportingService;
use Microsoft::AdCenter::V7::ReportingService::ReportTime;

sub test_can_create_report_time_and_set_all_fields : Test(4) {
    my $report_time = Microsoft::AdCenter::V7::ReportingService::ReportTime->new
        ->CustomDateRangeEnd('custom date range end')
        ->CustomDateRangeStart('custom date range start')
        ->PredefinedTime('predefined time')
    ;

    ok($report_time);

    is($report_time->CustomDateRangeEnd, 'custom date range end', 'can get custom date range end');
    is($report_time->CustomDateRangeStart, 'custom date range start', 'can get custom date range start');
    is($report_time->PredefinedTime, 'predefined time', 'can get predefined time');
};

1;
