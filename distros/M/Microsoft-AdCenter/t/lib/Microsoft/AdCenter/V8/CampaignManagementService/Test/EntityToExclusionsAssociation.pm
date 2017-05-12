package Microsoft::AdCenter::V8::CampaignManagementService::Test::EntityToExclusionsAssociation;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V8::CampaignManagementService;
use Microsoft::AdCenter::V8::CampaignManagementService::EntityToExclusionsAssociation;

sub test_can_create_entity_to_exclusions_association_and_set_all_fields : Test(3) {
    my $entity_to_exclusions_association = Microsoft::AdCenter::V8::CampaignManagementService::EntityToExclusionsAssociation->new
        ->AssociatedEntity('associated entity')
        ->Exclusions('exclusions')
    ;

    ok($entity_to_exclusions_association);

    is($entity_to_exclusions_association->AssociatedEntity, 'associated entity', 'can get associated entity');
    is($entity_to_exclusions_association->Exclusions, 'exclusions', 'can get exclusions');
};

1;
