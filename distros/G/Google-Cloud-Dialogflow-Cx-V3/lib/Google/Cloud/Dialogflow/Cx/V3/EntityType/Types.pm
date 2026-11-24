package Google::Cloud::Dialogflow::Cx::V3::EntityType::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'EntityType',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::EntityType::EntityType'];

coerce 'EntityType',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::EntityType::EntityType'->new($_) };

declare 'RepeatedEntityType',
    as ArrayRef[EntityType()];

coerce 'RepeatedEntityType',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::EntityType::EntityType'->new($_) } @$_ ] };

declare 'MapStringEntityType',
    as HashRef[EntityType()];

declare 'Kind',
    as (Int | Str);

declare 'AutoExpansionMode',
    as (Int | Str);

declare 'Entity',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::EntityType::EntityType::Entity'];

coerce 'Entity',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::EntityType::EntityType::Entity'->new($_) };

declare 'RepeatedEntity',
    as ArrayRef[Entity()];

coerce 'RepeatedEntity',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::EntityType::EntityType::Entity'->new($_) } @$_ ] };

declare 'MapStringEntity',
    as HashRef[Entity()];

declare 'ExcludedPhrase',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::EntityType::EntityType::ExcludedPhrase'];

coerce 'ExcludedPhrase',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::EntityType::EntityType::ExcludedPhrase'->new($_) };

declare 'RepeatedExcludedPhrase',
    as ArrayRef[ExcludedPhrase()];

coerce 'RepeatedExcludedPhrase',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::EntityType::EntityType::ExcludedPhrase'->new($_) } @$_ ] };

declare 'MapStringExcludedPhrase',
    as HashRef[ExcludedPhrase()];

declare 'ExportEntityTypesRequest',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::EntityType::ExportEntityTypesRequest'];

coerce 'ExportEntityTypesRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::EntityType::ExportEntityTypesRequest'->new($_) };

declare 'RepeatedExportEntityTypesRequest',
    as ArrayRef[ExportEntityTypesRequest()];

coerce 'RepeatedExportEntityTypesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::EntityType::ExportEntityTypesRequest'->new($_) } @$_ ] };

declare 'MapStringExportEntityTypesRequest',
    as HashRef[ExportEntityTypesRequest()];

declare 'DataFormat',
    as (Int | Str);

declare 'ExportEntityTypesResponse',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::EntityType::ExportEntityTypesResponse'];

coerce 'ExportEntityTypesResponse',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::EntityType::ExportEntityTypesResponse'->new($_) };

declare 'RepeatedExportEntityTypesResponse',
    as ArrayRef[ExportEntityTypesResponse()];

coerce 'RepeatedExportEntityTypesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::EntityType::ExportEntityTypesResponse'->new($_) } @$_ ] };

declare 'MapStringExportEntityTypesResponse',
    as HashRef[ExportEntityTypesResponse()];

declare 'ExportEntityTypesMetadata',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::EntityType::ExportEntityTypesMetadata'];

coerce 'ExportEntityTypesMetadata',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::EntityType::ExportEntityTypesMetadata'->new($_) };

declare 'RepeatedExportEntityTypesMetadata',
    as ArrayRef[ExportEntityTypesMetadata()];

coerce 'RepeatedExportEntityTypesMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::EntityType::ExportEntityTypesMetadata'->new($_) } @$_ ] };

declare 'MapStringExportEntityTypesMetadata',
    as HashRef[ExportEntityTypesMetadata()];

declare 'ImportEntityTypesRequest',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::EntityType::ImportEntityTypesRequest'];

coerce 'ImportEntityTypesRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::EntityType::ImportEntityTypesRequest'->new($_) };

declare 'RepeatedImportEntityTypesRequest',
    as ArrayRef[ImportEntityTypesRequest()];

coerce 'RepeatedImportEntityTypesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::EntityType::ImportEntityTypesRequest'->new($_) } @$_ ] };

declare 'MapStringImportEntityTypesRequest',
    as HashRef[ImportEntityTypesRequest()];

declare 'MergeOption',
    as (Int | Str);

declare 'ImportEntityTypesResponse',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::EntityType::ImportEntityTypesResponse'];

coerce 'ImportEntityTypesResponse',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::EntityType::ImportEntityTypesResponse'->new($_) };

declare 'RepeatedImportEntityTypesResponse',
    as ArrayRef[ImportEntityTypesResponse()];

coerce 'RepeatedImportEntityTypesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::EntityType::ImportEntityTypesResponse'->new($_) } @$_ ] };

declare 'MapStringImportEntityTypesResponse',
    as HashRef[ImportEntityTypesResponse()];

declare 'ConflictingResources',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::EntityType::ImportEntityTypesResponse::ConflictingResources'];

coerce 'ConflictingResources',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::EntityType::ImportEntityTypesResponse::ConflictingResources'->new($_) };

declare 'RepeatedConflictingResources',
    as ArrayRef[ConflictingResources()];

coerce 'RepeatedConflictingResources',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::EntityType::ImportEntityTypesResponse::ConflictingResources'->new($_) } @$_ ] };

declare 'MapStringConflictingResources',
    as HashRef[ConflictingResources()];

declare 'ImportEntityTypesMetadata',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::EntityType::ImportEntityTypesMetadata'];

coerce 'ImportEntityTypesMetadata',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::EntityType::ImportEntityTypesMetadata'->new($_) };

declare 'RepeatedImportEntityTypesMetadata',
    as ArrayRef[ImportEntityTypesMetadata()];

coerce 'RepeatedImportEntityTypesMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::EntityType::ImportEntityTypesMetadata'->new($_) } @$_ ] };

declare 'MapStringImportEntityTypesMetadata',
    as HashRef[ImportEntityTypesMetadata()];

declare 'ListEntityTypesRequest',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::EntityType::ListEntityTypesRequest'];

coerce 'ListEntityTypesRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::EntityType::ListEntityTypesRequest'->new($_) };

declare 'RepeatedListEntityTypesRequest',
    as ArrayRef[ListEntityTypesRequest()];

coerce 'RepeatedListEntityTypesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::EntityType::ListEntityTypesRequest'->new($_) } @$_ ] };

declare 'MapStringListEntityTypesRequest',
    as HashRef[ListEntityTypesRequest()];

declare 'ListEntityTypesResponse',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::EntityType::ListEntityTypesResponse'];

coerce 'ListEntityTypesResponse',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::EntityType::ListEntityTypesResponse'->new($_) };

declare 'RepeatedListEntityTypesResponse',
    as ArrayRef[ListEntityTypesResponse()];

coerce 'RepeatedListEntityTypesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::EntityType::ListEntityTypesResponse'->new($_) } @$_ ] };

declare 'MapStringListEntityTypesResponse',
    as HashRef[ListEntityTypesResponse()];

declare 'GetEntityTypeRequest',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::EntityType::GetEntityTypeRequest'];

coerce 'GetEntityTypeRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::EntityType::GetEntityTypeRequest'->new($_) };

declare 'RepeatedGetEntityTypeRequest',
    as ArrayRef[GetEntityTypeRequest()];

coerce 'RepeatedGetEntityTypeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::EntityType::GetEntityTypeRequest'->new($_) } @$_ ] };

declare 'MapStringGetEntityTypeRequest',
    as HashRef[GetEntityTypeRequest()];

declare 'CreateEntityTypeRequest',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::EntityType::CreateEntityTypeRequest'];

coerce 'CreateEntityTypeRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::EntityType::CreateEntityTypeRequest'->new($_) };

declare 'RepeatedCreateEntityTypeRequest',
    as ArrayRef[CreateEntityTypeRequest()];

coerce 'RepeatedCreateEntityTypeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::EntityType::CreateEntityTypeRequest'->new($_) } @$_ ] };

declare 'MapStringCreateEntityTypeRequest',
    as HashRef[CreateEntityTypeRequest()];

declare 'UpdateEntityTypeRequest',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::EntityType::UpdateEntityTypeRequest'];

coerce 'UpdateEntityTypeRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::EntityType::UpdateEntityTypeRequest'->new($_) };

declare 'RepeatedUpdateEntityTypeRequest',
    as ArrayRef[UpdateEntityTypeRequest()];

coerce 'RepeatedUpdateEntityTypeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::EntityType::UpdateEntityTypeRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateEntityTypeRequest',
    as HashRef[UpdateEntityTypeRequest()];

declare 'DeleteEntityTypeRequest',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::EntityType::DeleteEntityTypeRequest'];

coerce 'DeleteEntityTypeRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::EntityType::DeleteEntityTypeRequest'->new($_) };

declare 'RepeatedDeleteEntityTypeRequest',
    as ArrayRef[DeleteEntityTypeRequest()];

coerce 'RepeatedDeleteEntityTypeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::EntityType::DeleteEntityTypeRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteEntityTypeRequest',
    as HashRef[DeleteEntityTypeRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Dialogflow::Cx::V3::EntityType::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
