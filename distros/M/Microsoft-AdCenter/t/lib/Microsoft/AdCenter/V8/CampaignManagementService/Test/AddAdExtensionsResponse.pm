package Microsoft::AdCenter::V8::CampaignManagementService::Test::AddAdExtensionsResponse;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V8::CampaignManagementService;
use Microsoft::AdCenter::V8::CampaignManagementService::AddAdExtensionsResponse;

sub test_can_create_add_ad_extensions_response_and_set_all_fields : Test(2) {
    my $add_ad_extensions_response = Microsoft::AdCenter::V8::CampaignManagementService::AddAdExtensionsResponse->new
        ->AdExtensionIdentities('ad extension identities')
    ;

    ok($add_ad_extensions_response);

    is($add_ad_extensions_response->AdExtensionIdentities, 'ad extension identities', 'can get ad extension identities');
};

1;
