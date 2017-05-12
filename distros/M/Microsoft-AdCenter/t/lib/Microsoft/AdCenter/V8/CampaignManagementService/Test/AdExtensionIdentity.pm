package Microsoft::AdCenter::V8::CampaignManagementService::Test::AdExtensionIdentity;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V8::CampaignManagementService;
use Microsoft::AdCenter::V8::CampaignManagementService::AdExtensionIdentity;

sub test_can_create_ad_extension_identity_and_set_all_fields : Test(3) {
    my $ad_extension_identity = Microsoft::AdCenter::V8::CampaignManagementService::AdExtensionIdentity->new
        ->Id('id')
        ->Version('version')
    ;

    ok($ad_extension_identity);

    is($ad_extension_identity->Id, 'id', 'can get id');
    is($ad_extension_identity->Version, 'version', 'can get version');
};

1;
