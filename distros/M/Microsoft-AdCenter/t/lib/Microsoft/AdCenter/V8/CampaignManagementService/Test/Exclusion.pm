package Microsoft::AdCenter::V8::CampaignManagementService::Test::Exclusion;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V8::CampaignManagementService;
use Microsoft::AdCenter::V8::CampaignManagementService::Exclusion;

sub test_can_create_exclusion_and_set_all_fields : Test(3) {
    my $exclusion = Microsoft::AdCenter::V8::CampaignManagementService::Exclusion->new
        ->Id('id')
        ->Type('type')
    ;

    ok($exclusion);

    is($exclusion->Id, 'id', 'can get id');
    is($exclusion->Type, 'type', 'can get type');
};

1;
