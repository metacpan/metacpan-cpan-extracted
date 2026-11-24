package Google::Cloud::Dialogflow::V2beta1::EntityType::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'EntityType',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::EntityType::EntityType'];

coerce 'EntityType',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::EntityType::EntityType'->new($_) };

declare 'RepeatedEntityType',
    as ArrayRef[EntityType()];

coerce 'RepeatedEntityType',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::EntityType::EntityType'->new($_) } @$_ ] };

declare 'MapStringEntityType',
    as HashRef[EntityType()];

declare 'Kind',
    as (Int | Str);

declare 'AutoExpansionMode',
    as (Int | Str);

declare 'Entity',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::EntityType::EntityType::Entity'];

coerce 'Entity',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::EntityType::EntityType::Entity'->new($_) };

declare 'RepeatedEntity',
    as ArrayRef[Entity()];

coerce 'RepeatedEntity',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::EntityType::EntityType::Entity'->new($_) } @$_ ] };

declare 'MapStringEntity',
    as HashRef[Entity()];

declare 'ListEntityTypesRequest',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::EntityType::ListEntityTypesRequest'];

coerce 'ListEntityTypesRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::EntityType::ListEntityTypesRequest'->new($_) };

declare 'RepeatedListEntityTypesRequest',
    as ArrayRef[ListEntityTypesRequest()];

coerce 'RepeatedListEntityTypesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::EntityType::ListEntityTypesRequest'->new($_) } @$_ ] };

declare 'MapStringListEntityTypesRequest',
    as HashRef[ListEntityTypesRequest()];

declare 'ListEntityTypesResponse',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::EntityType::ListEntityTypesResponse'];

coerce 'ListEntityTypesResponse',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::EntityType::ListEntityTypesResponse'->new($_) };

declare 'RepeatedListEntityTypesResponse',
    as ArrayRef[ListEntityTypesResponse()];

coerce 'RepeatedListEntityTypesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::EntityType::ListEntityTypesResponse'->new($_) } @$_ ] };

declare 'MapStringListEntityTypesResponse',
    as HashRef[ListEntityTypesResponse()];

declare 'GetEntityTypeRequest',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::EntityType::GetEntityTypeRequest'];

coerce 'GetEntityTypeRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::EntityType::GetEntityTypeRequest'->new($_) };

declare 'RepeatedGetEntityTypeRequest',
    as ArrayRef[GetEntityTypeRequest()];

coerce 'RepeatedGetEntityTypeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::EntityType::GetEntityTypeRequest'->new($_) } @$_ ] };

declare 'MapStringGetEntityTypeRequest',
    as HashRef[GetEntityTypeRequest()];

declare 'CreateEntityTypeRequest',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::EntityType::CreateEntityTypeRequest'];

coerce 'CreateEntityTypeRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::EntityType::CreateEntityTypeRequest'->new($_) };

declare 'RepeatedCreateEntityTypeRequest',
    as ArrayRef[CreateEntityTypeRequest()];

coerce 'RepeatedCreateEntityTypeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::EntityType::CreateEntityTypeRequest'->new($_) } @$_ ] };

declare 'MapStringCreateEntityTypeRequest',
    as HashRef[CreateEntityTypeRequest()];

declare 'UpdateEntityTypeRequest',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::EntityType::UpdateEntityTypeRequest'];

coerce 'UpdateEntityTypeRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::EntityType::UpdateEntityTypeRequest'->new($_) };

declare 'RepeatedUpdateEntityTypeRequest',
    as ArrayRef[UpdateEntityTypeRequest()];

coerce 'RepeatedUpdateEntityTypeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::EntityType::UpdateEntityTypeRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateEntityTypeRequest',
    as HashRef[UpdateEntityTypeRequest()];

declare 'DeleteEntityTypeRequest',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::EntityType::DeleteEntityTypeRequest'];

coerce 'DeleteEntityTypeRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::EntityType::DeleteEntityTypeRequest'->new($_) };

declare 'RepeatedDeleteEntityTypeRequest',
    as ArrayRef[DeleteEntityTypeRequest()];

coerce 'RepeatedDeleteEntityTypeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::EntityType::DeleteEntityTypeRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteEntityTypeRequest',
    as HashRef[DeleteEntityTypeRequest()];

declare 'BatchUpdateEntityTypesRequest',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::EntityType::BatchUpdateEntityTypesRequest'];

coerce 'BatchUpdateEntityTypesRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::EntityType::BatchUpdateEntityTypesRequest'->new($_) };

declare 'RepeatedBatchUpdateEntityTypesRequest',
    as ArrayRef[BatchUpdateEntityTypesRequest()];

coerce 'RepeatedBatchUpdateEntityTypesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::EntityType::BatchUpdateEntityTypesRequest'->new($_) } @$_ ] };

declare 'MapStringBatchUpdateEntityTypesRequest',
    as HashRef[BatchUpdateEntityTypesRequest()];

declare 'BatchUpdateEntityTypesResponse',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::EntityType::BatchUpdateEntityTypesResponse'];

coerce 'BatchUpdateEntityTypesResponse',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::EntityType::BatchUpdateEntityTypesResponse'->new($_) };

declare 'RepeatedBatchUpdateEntityTypesResponse',
    as ArrayRef[BatchUpdateEntityTypesResponse()];

coerce 'RepeatedBatchUpdateEntityTypesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::EntityType::BatchUpdateEntityTypesResponse'->new($_) } @$_ ] };

declare 'MapStringBatchUpdateEntityTypesResponse',
    as HashRef[BatchUpdateEntityTypesResponse()];

declare 'BatchDeleteEntityTypesRequest',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::EntityType::BatchDeleteEntityTypesRequest'];

coerce 'BatchDeleteEntityTypesRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::EntityType::BatchDeleteEntityTypesRequest'->new($_) };

declare 'RepeatedBatchDeleteEntityTypesRequest',
    as ArrayRef[BatchDeleteEntityTypesRequest()];

coerce 'RepeatedBatchDeleteEntityTypesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::EntityType::BatchDeleteEntityTypesRequest'->new($_) } @$_ ] };

declare 'MapStringBatchDeleteEntityTypesRequest',
    as HashRef[BatchDeleteEntityTypesRequest()];

declare 'BatchCreateEntitiesRequest',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::EntityType::BatchCreateEntitiesRequest'];

coerce 'BatchCreateEntitiesRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::EntityType::BatchCreateEntitiesRequest'->new($_) };

declare 'RepeatedBatchCreateEntitiesRequest',
    as ArrayRef[BatchCreateEntitiesRequest()];

coerce 'RepeatedBatchCreateEntitiesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::EntityType::BatchCreateEntitiesRequest'->new($_) } @$_ ] };

declare 'MapStringBatchCreateEntitiesRequest',
    as HashRef[BatchCreateEntitiesRequest()];

declare 'BatchUpdateEntitiesRequest',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::EntityType::BatchUpdateEntitiesRequest'];

coerce 'BatchUpdateEntitiesRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::EntityType::BatchUpdateEntitiesRequest'->new($_) };

declare 'RepeatedBatchUpdateEntitiesRequest',
    as ArrayRef[BatchUpdateEntitiesRequest()];

coerce 'RepeatedBatchUpdateEntitiesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::EntityType::BatchUpdateEntitiesRequest'->new($_) } @$_ ] };

declare 'MapStringBatchUpdateEntitiesRequest',
    as HashRef[BatchUpdateEntitiesRequest()];

declare 'BatchDeleteEntitiesRequest',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::EntityType::BatchDeleteEntitiesRequest'];

coerce 'BatchDeleteEntitiesRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::EntityType::BatchDeleteEntitiesRequest'->new($_) };

declare 'RepeatedBatchDeleteEntitiesRequest',
    as ArrayRef[BatchDeleteEntitiesRequest()];

coerce 'RepeatedBatchDeleteEntitiesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::EntityType::BatchDeleteEntitiesRequest'->new($_) } @$_ ] };

declare 'MapStringBatchDeleteEntitiesRequest',
    as HashRef[BatchDeleteEntitiesRequest()];

declare 'EntityTypeBatch',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::EntityType::EntityTypeBatch'];

coerce 'EntityTypeBatch',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::EntityType::EntityTypeBatch'->new($_) };

declare 'RepeatedEntityTypeBatch',
    as ArrayRef[EntityTypeBatch()];

coerce 'RepeatedEntityTypeBatch',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::EntityType::EntityTypeBatch'->new($_) } @$_ ] };

declare 'MapStringEntityTypeBatch',
    as HashRef[EntityTypeBatch()];

1;

__END__

=head1 NAME

Google::Cloud::Dialogflow::V2beta1::EntityType::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
