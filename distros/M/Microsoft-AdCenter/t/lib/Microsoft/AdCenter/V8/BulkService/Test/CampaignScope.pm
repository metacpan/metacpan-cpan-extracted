package Microsoft::AdCenter::V8::BulkService::Test::CampaignScope;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V8::BulkService;
use Microsoft::AdCenter::V8::BulkService::CampaignScope;

sub test_can_create_campaign_scope_and_set_all_fields : Test(3) {
    my $campaign_scope = Microsoft::AdCenter::V8::BulkService::CampaignScope->new
        ->CampaignId('campaign id')
        ->ParentAccountId('parent account id')
    ;

    ok($campaign_scope);

    is($campaign_scope->CampaignId, 'campaign id', 'can get campaign id');
    is($campaign_scope->ParentAccountId, 'parent account id', 'can get parent account id');
};

1;
