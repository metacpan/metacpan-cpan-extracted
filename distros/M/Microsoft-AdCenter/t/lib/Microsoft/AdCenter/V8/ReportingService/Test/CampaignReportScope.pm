package Microsoft::AdCenter::V8::ReportingService::Test::CampaignReportScope;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V8::ReportingService;
use Microsoft::AdCenter::V8::ReportingService::CampaignReportScope;

sub test_can_create_campaign_report_scope_and_set_all_fields : Test(3) {
    my $campaign_report_scope = Microsoft::AdCenter::V8::ReportingService::CampaignReportScope->new
        ->CampaignId('campaign id')
        ->ParentAccountId('parent account id')
    ;

    ok($campaign_report_scope);

    is($campaign_report_scope->CampaignId, 'campaign id', 'can get campaign id');
    is($campaign_report_scope->ParentAccountId, 'parent account id', 'can get parent account id');
};

1;
