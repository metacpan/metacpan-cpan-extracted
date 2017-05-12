package Microsoft::AdCenter::V8::ReportingService::Test::SearchCampaignChangeHistoryReportRequest;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V8::ReportingService;
use Microsoft::AdCenter::V8::ReportingService::SearchCampaignChangeHistoryReportRequest;

sub test_can_create_search_campaign_change_history_report_request_and_set_all_fields : Test(5) {
    my $search_campaign_change_history_report_request = Microsoft::AdCenter::V8::ReportingService::SearchCampaignChangeHistoryReportRequest->new
        ->Columns('columns')
        ->Filter('filter')
        ->Scope('scope')
        ->Time('time')
    ;

    ok($search_campaign_change_history_report_request);

    is($search_campaign_change_history_report_request->Columns, 'columns', 'can get columns');
    is($search_campaign_change_history_report_request->Filter, 'filter', 'can get filter');
    is($search_campaign_change_history_report_request->Scope, 'scope', 'can get scope');
    is($search_campaign_change_history_report_request->Time, 'time', 'can get time');
};

1;
