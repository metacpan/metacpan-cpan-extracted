package Microsoft::AdCenter::V8::CampaignManagementService::Test::AdGroupNegativeKeywords;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V8::CampaignManagementService;
use Microsoft::AdCenter::V8::CampaignManagementService::AdGroupNegativeKeywords;

sub test_can_create_ad_group_negative_keywords_and_set_all_fields : Test(3) {
    my $ad_group_negative_keywords = Microsoft::AdCenter::V8::CampaignManagementService::AdGroupNegativeKeywords->new
        ->AdGroupId('ad group id')
        ->NegativeKeywords('negative keywords')
    ;

    ok($ad_group_negative_keywords);

    is($ad_group_negative_keywords->AdGroupId, 'ad group id', 'can get ad group id');
    is($ad_group_negative_keywords->NegativeKeywords, 'negative keywords', 'can get negative keywords');
};

1;
