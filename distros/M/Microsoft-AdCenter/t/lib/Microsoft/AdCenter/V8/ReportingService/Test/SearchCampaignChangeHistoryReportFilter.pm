package Microsoft::AdCenter::V8::ReportingService::Test::SearchCampaignChangeHistoryReportFilter;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V8::ReportingService;
use Microsoft::AdCenter::V8::ReportingService::SearchCampaignChangeHistoryReportFilter;

sub test_can_create_search_campaign_change_history_report_filter_and_set_all_fields : Test(3) {
    my $search_campaign_change_history_report_filter = Microsoft::AdCenter::V8::ReportingService::SearchCampaignChangeHistoryReportFilter->new
        ->HowChanged('how changed')
        ->ItemChanged('item changed')
    ;

    ok($search_campaign_change_history_report_filter);

    is($search_campaign_change_history_report_filter->HowChanged, 'how changed', 'can get how changed');
    is($search_campaign_change_history_report_filter->ItemChanged, 'item changed', 'can get item changed');
};

1;
