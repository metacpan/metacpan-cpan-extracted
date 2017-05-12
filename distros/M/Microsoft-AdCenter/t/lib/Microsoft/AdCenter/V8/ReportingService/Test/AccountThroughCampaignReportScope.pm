package Microsoft::AdCenter::V8::ReportingService::Test::AccountThroughCampaignReportScope;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V8::ReportingService;
use Microsoft::AdCenter::V8::ReportingService::AccountThroughCampaignReportScope;

sub test_can_create_account_through_campaign_report_scope_and_set_all_fields : Test(3) {
    my $account_through_campaign_report_scope = Microsoft::AdCenter::V8::ReportingService::AccountThroughCampaignReportScope->new
        ->AccountIds('account ids')
        ->Campaigns('campaigns')
    ;

    ok($account_through_campaign_report_scope);

    is($account_through_campaign_report_scope->AccountIds, 'account ids', 'can get account ids');
    is($account_through_campaign_report_scope->Campaigns, 'campaigns', 'can get campaigns');
};

1;
