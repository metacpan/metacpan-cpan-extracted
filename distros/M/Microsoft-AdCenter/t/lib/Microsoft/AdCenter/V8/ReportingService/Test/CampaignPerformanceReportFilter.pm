package Microsoft::AdCenter::V8::ReportingService::Test::CampaignPerformanceReportFilter;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V8::ReportingService;
use Microsoft::AdCenter::V8::ReportingService::CampaignPerformanceReportFilter;

sub test_can_create_campaign_performance_report_filter_and_set_all_fields : Test(4) {
    my $campaign_performance_report_filter = Microsoft::AdCenter::V8::ReportingService::CampaignPerformanceReportFilter->new
        ->AdDistribution('ad distribution')
        ->DeviceType('device type')
        ->Status('status')
    ;

    ok($campaign_performance_report_filter);

    is($campaign_performance_report_filter->AdDistribution, 'ad distribution', 'can get ad distribution');
    is($campaign_performance_report_filter->DeviceType, 'device type', 'can get device type');
    is($campaign_performance_report_filter->Status, 'status', 'can get status');
};

1;
