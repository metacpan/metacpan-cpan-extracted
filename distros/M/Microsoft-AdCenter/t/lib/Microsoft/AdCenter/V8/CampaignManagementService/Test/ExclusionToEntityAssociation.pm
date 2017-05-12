package Microsoft::AdCenter::V8::CampaignManagementService::Test::ExclusionToEntityAssociation;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V8::CampaignManagementService;
use Microsoft::AdCenter::V8::CampaignManagementService::ExclusionToEntityAssociation;

sub test_can_create_exclusion_to_entity_association_and_set_all_fields : Test(3) {
    my $exclusion_to_entity_association = Microsoft::AdCenter::V8::CampaignManagementService::ExclusionToEntityAssociation->new
        ->AssociatedEntity('associated entity')
        ->Exclusion('exclusion')
    ;

    ok($exclusion_to_entity_association);

    is($exclusion_to_entity_association->AssociatedEntity, 'associated entity', 'can get associated entity');
    is($exclusion_to_entity_association->Exclusion, 'exclusion', 'can get exclusion');
};

1;
