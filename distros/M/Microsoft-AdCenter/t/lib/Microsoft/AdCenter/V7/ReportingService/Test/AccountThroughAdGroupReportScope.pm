package Microsoft::AdCenter::V7::ReportingService::Test::AccountThroughAdGroupReportScope;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V7::ReportingService;
use Microsoft::AdCenter::V7::ReportingService::AccountThroughAdGroupReportScope;

sub test_can_create_account_through_ad_group_report_scope_and_set_all_fields : Test(4) {
    my $account_through_ad_group_report_scope = Microsoft::AdCenter::V7::ReportingService::AccountThroughAdGroupReportScope->new
        ->AccountIds('account ids')
        ->AdGroups('ad groups')
        ->Campaigns('campaigns')
    ;

    ok($account_through_ad_group_report_scope);

    is($account_through_ad_group_report_scope->AccountIds, 'account ids', 'can get account ids');
    is($account_through_ad_group_report_scope->AdGroups, 'ad groups', 'can get ad groups');
    is($account_through_ad_group_report_scope->Campaigns, 'campaigns', 'can get campaigns');
};

1;
