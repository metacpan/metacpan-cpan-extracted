package Microsoft::AdCenter::V8::ReportingService::Test::AdGroupReportScope;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V8::ReportingService;
use Microsoft::AdCenter::V8::ReportingService::AdGroupReportScope;

sub test_can_create_ad_group_report_scope_and_set_all_fields : Test(4) {
    my $ad_group_report_scope = Microsoft::AdCenter::V8::ReportingService::AdGroupReportScope->new
        ->AdGroupId('ad group id')
        ->ParentAccountId('parent account id')
        ->ParentCampaignId('parent campaign id')
    ;

    ok($ad_group_report_scope);

    is($ad_group_report_scope->AdGroupId, 'ad group id', 'can get ad group id');
    is($ad_group_report_scope->ParentAccountId, 'parent account id', 'can get parent account id');
    is($ad_group_report_scope->ParentCampaignId, 'parent campaign id', 'can get parent campaign id');
};

1;
