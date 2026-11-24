package Google::Cloud::Discoveryengine::V1::DataStoreService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'CreateDataStoreRequest',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::DataStoreService::CreateDataStoreRequest'];

coerce 'CreateDataStoreRequest',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::DataStoreService::CreateDataStoreRequest'->new($_) };

declare 'RepeatedCreateDataStoreRequest',
    as ArrayRef[CreateDataStoreRequest()];

coerce 'RepeatedCreateDataStoreRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::DataStoreService::CreateDataStoreRequest'->new($_) } @$_ ] };

declare 'MapStringCreateDataStoreRequest',
    as HashRef[CreateDataStoreRequest()];

declare 'GetDataStoreRequest',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::DataStoreService::GetDataStoreRequest'];

coerce 'GetDataStoreRequest',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::DataStoreService::GetDataStoreRequest'->new($_) };

declare 'RepeatedGetDataStoreRequest',
    as ArrayRef[GetDataStoreRequest()];

coerce 'RepeatedGetDataStoreRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::DataStoreService::GetDataStoreRequest'->new($_) } @$_ ] };

declare 'MapStringGetDataStoreRequest',
    as HashRef[GetDataStoreRequest()];

declare 'CreateDataStoreMetadata',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::DataStoreService::CreateDataStoreMetadata'];

coerce 'CreateDataStoreMetadata',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::DataStoreService::CreateDataStoreMetadata'->new($_) };

declare 'RepeatedCreateDataStoreMetadata',
    as ArrayRef[CreateDataStoreMetadata()];

coerce 'RepeatedCreateDataStoreMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::DataStoreService::CreateDataStoreMetadata'->new($_) } @$_ ] };

declare 'MapStringCreateDataStoreMetadata',
    as HashRef[CreateDataStoreMetadata()];

declare 'ListDataStoresRequest',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::DataStoreService::ListDataStoresRequest'];

coerce 'ListDataStoresRequest',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::DataStoreService::ListDataStoresRequest'->new($_) };

declare 'RepeatedListDataStoresRequest',
    as ArrayRef[ListDataStoresRequest()];

coerce 'RepeatedListDataStoresRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::DataStoreService::ListDataStoresRequest'->new($_) } @$_ ] };

declare 'MapStringListDataStoresRequest',
    as HashRef[ListDataStoresRequest()];

declare 'ListDataStoresResponse',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::DataStoreService::ListDataStoresResponse'];

coerce 'ListDataStoresResponse',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::DataStoreService::ListDataStoresResponse'->new($_) };

declare 'RepeatedListDataStoresResponse',
    as ArrayRef[ListDataStoresResponse()];

coerce 'RepeatedListDataStoresResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::DataStoreService::ListDataStoresResponse'->new($_) } @$_ ] };

declare 'MapStringListDataStoresResponse',
    as HashRef[ListDataStoresResponse()];

declare 'DeleteDataStoreRequest',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::DataStoreService::DeleteDataStoreRequest'];

coerce 'DeleteDataStoreRequest',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::DataStoreService::DeleteDataStoreRequest'->new($_) };

declare 'RepeatedDeleteDataStoreRequest',
    as ArrayRef[DeleteDataStoreRequest()];

coerce 'RepeatedDeleteDataStoreRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::DataStoreService::DeleteDataStoreRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteDataStoreRequest',
    as HashRef[DeleteDataStoreRequest()];

declare 'UpdateDataStoreRequest',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::DataStoreService::UpdateDataStoreRequest'];

coerce 'UpdateDataStoreRequest',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::DataStoreService::UpdateDataStoreRequest'->new($_) };

declare 'RepeatedUpdateDataStoreRequest',
    as ArrayRef[UpdateDataStoreRequest()];

coerce 'RepeatedUpdateDataStoreRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::DataStoreService::UpdateDataStoreRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateDataStoreRequest',
    as HashRef[UpdateDataStoreRequest()];

declare 'DeleteDataStoreMetadata',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::DataStoreService::DeleteDataStoreMetadata'];

coerce 'DeleteDataStoreMetadata',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::DataStoreService::DeleteDataStoreMetadata'->new($_) };

declare 'RepeatedDeleteDataStoreMetadata',
    as ArrayRef[DeleteDataStoreMetadata()];

coerce 'RepeatedDeleteDataStoreMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::DataStoreService::DeleteDataStoreMetadata'->new($_) } @$_ ] };

declare 'MapStringDeleteDataStoreMetadata',
    as HashRef[DeleteDataStoreMetadata()];

1;

__END__

=head1 NAME

Google::Cloud::Discoveryengine::V1::DataStoreService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
