package Microsoft::AdCenter::V8::CampaignManagementService::Test::TargetAssociation;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V8::CampaignManagementService;
use Microsoft::AdCenter::V8::CampaignManagementService::TargetAssociation;

sub test_can_create_target_association_and_set_all_fields : Test(3) {
    my $target_association = Microsoft::AdCenter::V8::CampaignManagementService::TargetAssociation->new
        ->DeviceOSTarget('device ostarget')
        ->Id('id')
    ;

    ok($target_association);

    is($target_association->DeviceOSTarget, 'device ostarget', 'can get device ostarget');
    is($target_association->Id, 'id', 'can get id');
};

1;
