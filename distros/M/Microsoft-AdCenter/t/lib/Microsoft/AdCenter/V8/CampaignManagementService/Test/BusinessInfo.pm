package Microsoft::AdCenter::V8::CampaignManagementService::Test::BusinessInfo;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V8::CampaignManagementService;
use Microsoft::AdCenter::V8::CampaignManagementService::BusinessInfo;

sub test_can_create_business_info_and_set_all_fields : Test(3) {
    my $business_info = Microsoft::AdCenter::V8::CampaignManagementService::BusinessInfo->new
        ->Id('id')
        ->Name('name')
    ;

    ok($business_info);

    is($business_info->Id, 'id', 'can get id');
    is($business_info->Name, 'name', 'can get name');
};

1;
