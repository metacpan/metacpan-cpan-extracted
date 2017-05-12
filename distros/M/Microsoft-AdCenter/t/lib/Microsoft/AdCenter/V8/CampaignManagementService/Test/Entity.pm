package Microsoft::AdCenter::V8::CampaignManagementService::Test::Entity;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V8::CampaignManagementService;
use Microsoft::AdCenter::V8::CampaignManagementService::Entity;

sub test_can_create_entity_and_set_all_fields : Test(3) {
    my $entity = Microsoft::AdCenter::V8::CampaignManagementService::Entity->new
        ->EntityType('entity type')
        ->Id('id')
    ;

    ok($entity);

    is($entity->EntityType, 'entity type', 'can get entity type');
    is($entity->Id, 'id', 'can get id');
};

1;
