package Microsoft::AdCenter::V8::ReportingService::Test::AdExtensionByAdsReportRequest;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V8::ReportingService;
use Microsoft::AdCenter::V8::ReportingService::AdExtensionByAdsReportRequest;

sub test_can_create_ad_extension_by_ads_report_request_and_set_all_fields : Test(5) {
    my $ad_extension_by_ads_report_request = Microsoft::AdCenter::V8::ReportingService::AdExtensionByAdsReportRequest->new
        ->Aggregation('aggregation')
        ->Columns('columns')
        ->Scope('scope')
        ->Time('time')
    ;

    ok($ad_extension_by_ads_report_request);

    is($ad_extension_by_ads_report_request->Aggregation, 'aggregation', 'can get aggregation');
    is($ad_extension_by_ads_report_request->Columns, 'columns', 'can get columns');
    is($ad_extension_by_ads_report_request->Scope, 'scope', 'can get scope');
    is($ad_extension_by_ads_report_request->Time, 'time', 'can get time');
};

1;
