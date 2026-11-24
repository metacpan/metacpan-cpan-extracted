package Google::Cloud::Discoveryengine::V1::IdentityMappingStoreService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'CreateIdentityMappingStoreRequest',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::IdentityMappingStoreService::CreateIdentityMappingStoreRequest'];

coerce 'CreateIdentityMappingStoreRequest',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::IdentityMappingStoreService::CreateIdentityMappingStoreRequest'->new($_) };

declare 'RepeatedCreateIdentityMappingStoreRequest',
    as ArrayRef[CreateIdentityMappingStoreRequest()];

coerce 'RepeatedCreateIdentityMappingStoreRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::IdentityMappingStoreService::CreateIdentityMappingStoreRequest'->new($_) } @$_ ] };

declare 'MapStringCreateIdentityMappingStoreRequest',
    as HashRef[CreateIdentityMappingStoreRequest()];

declare 'GetIdentityMappingStoreRequest',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::IdentityMappingStoreService::GetIdentityMappingStoreRequest'];

coerce 'GetIdentityMappingStoreRequest',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::IdentityMappingStoreService::GetIdentityMappingStoreRequest'->new($_) };

declare 'RepeatedGetIdentityMappingStoreRequest',
    as ArrayRef[GetIdentityMappingStoreRequest()];

coerce 'RepeatedGetIdentityMappingStoreRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::IdentityMappingStoreService::GetIdentityMappingStoreRequest'->new($_) } @$_ ] };

declare 'MapStringGetIdentityMappingStoreRequest',
    as HashRef[GetIdentityMappingStoreRequest()];

declare 'DeleteIdentityMappingStoreRequest',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::IdentityMappingStoreService::DeleteIdentityMappingStoreRequest'];

coerce 'DeleteIdentityMappingStoreRequest',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::IdentityMappingStoreService::DeleteIdentityMappingStoreRequest'->new($_) };

declare 'RepeatedDeleteIdentityMappingStoreRequest',
    as ArrayRef[DeleteIdentityMappingStoreRequest()];

coerce 'RepeatedDeleteIdentityMappingStoreRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::IdentityMappingStoreService::DeleteIdentityMappingStoreRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteIdentityMappingStoreRequest',
    as HashRef[DeleteIdentityMappingStoreRequest()];

declare 'ImportIdentityMappingsRequest',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::IdentityMappingStoreService::ImportIdentityMappingsRequest'];

coerce 'ImportIdentityMappingsRequest',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::IdentityMappingStoreService::ImportIdentityMappingsRequest'->new($_) };

declare 'RepeatedImportIdentityMappingsRequest',
    as ArrayRef[ImportIdentityMappingsRequest()];

coerce 'RepeatedImportIdentityMappingsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::IdentityMappingStoreService::ImportIdentityMappingsRequest'->new($_) } @$_ ] };

declare 'MapStringImportIdentityMappingsRequest',
    as HashRef[ImportIdentityMappingsRequest()];

declare 'InlineSource',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::IdentityMappingStoreService::ImportIdentityMappingsRequest::InlineSource'];

coerce 'InlineSource',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::IdentityMappingStoreService::ImportIdentityMappingsRequest::InlineSource'->new($_) };

declare 'RepeatedInlineSource',
    as ArrayRef[InlineSource()];

coerce 'RepeatedInlineSource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::IdentityMappingStoreService::ImportIdentityMappingsRequest::InlineSource'->new($_) } @$_ ] };

declare 'MapStringInlineSource',
    as HashRef[InlineSource()];

declare 'ImportIdentityMappingsResponse',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::IdentityMappingStoreService::ImportIdentityMappingsResponse'];

coerce 'ImportIdentityMappingsResponse',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::IdentityMappingStoreService::ImportIdentityMappingsResponse'->new($_) };

declare 'RepeatedImportIdentityMappingsResponse',
    as ArrayRef[ImportIdentityMappingsResponse()];

coerce 'RepeatedImportIdentityMappingsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::IdentityMappingStoreService::ImportIdentityMappingsResponse'->new($_) } @$_ ] };

declare 'MapStringImportIdentityMappingsResponse',
    as HashRef[ImportIdentityMappingsResponse()];

declare 'PurgeIdentityMappingsRequest',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::IdentityMappingStoreService::PurgeIdentityMappingsRequest'];

coerce 'PurgeIdentityMappingsRequest',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::IdentityMappingStoreService::PurgeIdentityMappingsRequest'->new($_) };

declare 'RepeatedPurgeIdentityMappingsRequest',
    as ArrayRef[PurgeIdentityMappingsRequest()];

coerce 'RepeatedPurgeIdentityMappingsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::IdentityMappingStoreService::PurgeIdentityMappingsRequest'->new($_) } @$_ ] };

declare 'MapStringPurgeIdentityMappingsRequest',
    as HashRef[PurgeIdentityMappingsRequest()];

declare 'InlineSource',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::IdentityMappingStoreService::PurgeIdentityMappingsRequest::InlineSource'];

coerce 'InlineSource',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::IdentityMappingStoreService::PurgeIdentityMappingsRequest::InlineSource'->new($_) };

declare 'RepeatedInlineSource',
    as ArrayRef[InlineSource()];

coerce 'RepeatedInlineSource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::IdentityMappingStoreService::PurgeIdentityMappingsRequest::InlineSource'->new($_) } @$_ ] };

declare 'MapStringInlineSource',
    as HashRef[InlineSource()];

declare 'ListIdentityMappingsRequest',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::IdentityMappingStoreService::ListIdentityMappingsRequest'];

coerce 'ListIdentityMappingsRequest',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::IdentityMappingStoreService::ListIdentityMappingsRequest'->new($_) };

declare 'RepeatedListIdentityMappingsRequest',
    as ArrayRef[ListIdentityMappingsRequest()];

coerce 'RepeatedListIdentityMappingsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::IdentityMappingStoreService::ListIdentityMappingsRequest'->new($_) } @$_ ] };

declare 'MapStringListIdentityMappingsRequest',
    as HashRef[ListIdentityMappingsRequest()];

declare 'ListIdentityMappingsResponse',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::IdentityMappingStoreService::ListIdentityMappingsResponse'];

coerce 'ListIdentityMappingsResponse',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::IdentityMappingStoreService::ListIdentityMappingsResponse'->new($_) };

declare 'RepeatedListIdentityMappingsResponse',
    as ArrayRef[ListIdentityMappingsResponse()];

coerce 'RepeatedListIdentityMappingsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::IdentityMappingStoreService::ListIdentityMappingsResponse'->new($_) } @$_ ] };

declare 'MapStringListIdentityMappingsResponse',
    as HashRef[ListIdentityMappingsResponse()];

declare 'ListIdentityMappingStoresRequest',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::IdentityMappingStoreService::ListIdentityMappingStoresRequest'];

coerce 'ListIdentityMappingStoresRequest',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::IdentityMappingStoreService::ListIdentityMappingStoresRequest'->new($_) };

declare 'RepeatedListIdentityMappingStoresRequest',
    as ArrayRef[ListIdentityMappingStoresRequest()];

coerce 'RepeatedListIdentityMappingStoresRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::IdentityMappingStoreService::ListIdentityMappingStoresRequest'->new($_) } @$_ ] };

declare 'MapStringListIdentityMappingStoresRequest',
    as HashRef[ListIdentityMappingStoresRequest()];

declare 'ListIdentityMappingStoresResponse',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::IdentityMappingStoreService::ListIdentityMappingStoresResponse'];

coerce 'ListIdentityMappingStoresResponse',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::IdentityMappingStoreService::ListIdentityMappingStoresResponse'->new($_) };

declare 'RepeatedListIdentityMappingStoresResponse',
    as ArrayRef[ListIdentityMappingStoresResponse()];

coerce 'RepeatedListIdentityMappingStoresResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::IdentityMappingStoreService::ListIdentityMappingStoresResponse'->new($_) } @$_ ] };

declare 'MapStringListIdentityMappingStoresResponse',
    as HashRef[ListIdentityMappingStoresResponse()];

declare 'IdentityMappingEntryOperationMetadata',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::IdentityMappingStoreService::IdentityMappingEntryOperationMetadata'];

coerce 'IdentityMappingEntryOperationMetadata',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::IdentityMappingStoreService::IdentityMappingEntryOperationMetadata'->new($_) };

declare 'RepeatedIdentityMappingEntryOperationMetadata',
    as ArrayRef[IdentityMappingEntryOperationMetadata()];

coerce 'RepeatedIdentityMappingEntryOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::IdentityMappingStoreService::IdentityMappingEntryOperationMetadata'->new($_) } @$_ ] };

declare 'MapStringIdentityMappingEntryOperationMetadata',
    as HashRef[IdentityMappingEntryOperationMetadata()];

declare 'DeleteIdentityMappingStoreMetadata',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::IdentityMappingStoreService::DeleteIdentityMappingStoreMetadata'];

coerce 'DeleteIdentityMappingStoreMetadata',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::IdentityMappingStoreService::DeleteIdentityMappingStoreMetadata'->new($_) };

declare 'RepeatedDeleteIdentityMappingStoreMetadata',
    as ArrayRef[DeleteIdentityMappingStoreMetadata()];

coerce 'RepeatedDeleteIdentityMappingStoreMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::IdentityMappingStoreService::DeleteIdentityMappingStoreMetadata'->new($_) } @$_ ] };

declare 'MapStringDeleteIdentityMappingStoreMetadata',
    as HashRef[DeleteIdentityMappingStoreMetadata()];

1;

__END__

=head1 NAME

Google::Cloud::Discoveryengine::V1::IdentityMappingStoreService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
