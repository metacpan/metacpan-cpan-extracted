package Microsoft::AdCenter::V8::CampaignManagementService::Test::TargetInfo;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V8::CampaignManagementService;
use Microsoft::AdCenter::V8::CampaignManagementService::TargetInfo;

sub test_can_create_target_info_and_set_all_fields : Test(3) {
    my $target_info = Microsoft::AdCenter::V8::CampaignManagementService::TargetInfo->new
        ->Id('id')
        ->Name('name')
    ;

    ok($target_info);

    is($target_info->Id, 'id', 'can get id');
    is($target_info->Name, 'name', 'can get name');
};

1;
