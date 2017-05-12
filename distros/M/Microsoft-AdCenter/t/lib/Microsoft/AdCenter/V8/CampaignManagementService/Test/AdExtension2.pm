package Microsoft::AdCenter::V8::CampaignManagementService::Test::AdExtension2;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V8::CampaignManagementService;
use Microsoft::AdCenter::V8::CampaignManagementService::AdExtension2;

sub test_can_create_ad_extension2_and_set_all_fields : Test(5) {
    my $ad_extension2 = Microsoft::AdCenter::V8::CampaignManagementService::AdExtension2->new
        ->Id('id')
        ->Status('status')
        ->Type('type')
        ->Version('version')
    ;

    ok($ad_extension2);

    is($ad_extension2->Id, 'id', 'can get id');
    is($ad_extension2->Status, 'status', 'can get status');
    is($ad_extension2->Type, 'type', 'can get type');
    is($ad_extension2->Version, 'version', 'can get version');
};

1;
