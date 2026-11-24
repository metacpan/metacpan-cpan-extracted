package Google::Cloud::Netapp::V1::StoragePool::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Mode',
    as (Int | Str);

declare 'GetStoragePoolRequest',
    as InstanceOf['Google::Cloud::Netapp::V1::StoragePool::GetStoragePoolRequest'];

coerce 'GetStoragePoolRequest',
    from HashRef, via { 'Google::Cloud::Netapp::V1::StoragePool::GetStoragePoolRequest'->new($_) };

declare 'RepeatedGetStoragePoolRequest',
    as ArrayRef[GetStoragePoolRequest()];

coerce 'RepeatedGetStoragePoolRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Netapp::V1::StoragePool::GetStoragePoolRequest'->new($_) } @$_ ] };

declare 'MapStringGetStoragePoolRequest',
    as HashRef[GetStoragePoolRequest()];

declare 'ListStoragePoolsRequest',
    as InstanceOf['Google::Cloud::Netapp::V1::StoragePool::ListStoragePoolsRequest'];

coerce 'ListStoragePoolsRequest',
    from HashRef, via { 'Google::Cloud::Netapp::V1::StoragePool::ListStoragePoolsRequest'->new($_) };

declare 'RepeatedListStoragePoolsRequest',
    as ArrayRef[ListStoragePoolsRequest()];

coerce 'RepeatedListStoragePoolsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Netapp::V1::StoragePool::ListStoragePoolsRequest'->new($_) } @$_ ] };

declare 'MapStringListStoragePoolsRequest',
    as HashRef[ListStoragePoolsRequest()];

declare 'ListStoragePoolsResponse',
    as InstanceOf['Google::Cloud::Netapp::V1::StoragePool::ListStoragePoolsResponse'];

coerce 'ListStoragePoolsResponse',
    from HashRef, via { 'Google::Cloud::Netapp::V1::StoragePool::ListStoragePoolsResponse'->new($_) };

declare 'RepeatedListStoragePoolsResponse',
    as ArrayRef[ListStoragePoolsResponse()];

coerce 'RepeatedListStoragePoolsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Netapp::V1::StoragePool::ListStoragePoolsResponse'->new($_) } @$_ ] };

declare 'MapStringListStoragePoolsResponse',
    as HashRef[ListStoragePoolsResponse()];

declare 'CreateStoragePoolRequest',
    as InstanceOf['Google::Cloud::Netapp::V1::StoragePool::CreateStoragePoolRequest'];

coerce 'CreateStoragePoolRequest',
    from HashRef, via { 'Google::Cloud::Netapp::V1::StoragePool::CreateStoragePoolRequest'->new($_) };

declare 'RepeatedCreateStoragePoolRequest',
    as ArrayRef[CreateStoragePoolRequest()];

coerce 'RepeatedCreateStoragePoolRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Netapp::V1::StoragePool::CreateStoragePoolRequest'->new($_) } @$_ ] };

declare 'MapStringCreateStoragePoolRequest',
    as HashRef[CreateStoragePoolRequest()];

declare 'UpdateStoragePoolRequest',
    as InstanceOf['Google::Cloud::Netapp::V1::StoragePool::UpdateStoragePoolRequest'];

coerce 'UpdateStoragePoolRequest',
    from HashRef, via { 'Google::Cloud::Netapp::V1::StoragePool::UpdateStoragePoolRequest'->new($_) };

declare 'RepeatedUpdateStoragePoolRequest',
    as ArrayRef[UpdateStoragePoolRequest()];

coerce 'RepeatedUpdateStoragePoolRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Netapp::V1::StoragePool::UpdateStoragePoolRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateStoragePoolRequest',
    as HashRef[UpdateStoragePoolRequest()];

declare 'DeleteStoragePoolRequest',
    as InstanceOf['Google::Cloud::Netapp::V1::StoragePool::DeleteStoragePoolRequest'];

coerce 'DeleteStoragePoolRequest',
    from HashRef, via { 'Google::Cloud::Netapp::V1::StoragePool::DeleteStoragePoolRequest'->new($_) };

declare 'RepeatedDeleteStoragePoolRequest',
    as ArrayRef[DeleteStoragePoolRequest()];

coerce 'RepeatedDeleteStoragePoolRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Netapp::V1::StoragePool::DeleteStoragePoolRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteStoragePoolRequest',
    as HashRef[DeleteStoragePoolRequest()];

declare 'SwitchActiveReplicaZoneRequest',
    as InstanceOf['Google::Cloud::Netapp::V1::StoragePool::SwitchActiveReplicaZoneRequest'];

coerce 'SwitchActiveReplicaZoneRequest',
    from HashRef, via { 'Google::Cloud::Netapp::V1::StoragePool::SwitchActiveReplicaZoneRequest'->new($_) };

declare 'RepeatedSwitchActiveReplicaZoneRequest',
    as ArrayRef[SwitchActiveReplicaZoneRequest()];

coerce 'RepeatedSwitchActiveReplicaZoneRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Netapp::V1::StoragePool::SwitchActiveReplicaZoneRequest'->new($_) } @$_ ] };

declare 'MapStringSwitchActiveReplicaZoneRequest',
    as HashRef[SwitchActiveReplicaZoneRequest()];

declare 'StoragePool',
    as InstanceOf['Google::Cloud::Netapp::V1::StoragePool::StoragePool'];

coerce 'StoragePool',
    from HashRef, via { 'Google::Cloud::Netapp::V1::StoragePool::StoragePool'->new($_) };

declare 'RepeatedStoragePool',
    as ArrayRef[StoragePool()];

coerce 'RepeatedStoragePool',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Netapp::V1::StoragePool::StoragePool'->new($_) } @$_ ] };

declare 'MapStringStoragePool',
    as HashRef[StoragePool()];

declare 'State',
    as (Int | Str);

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Netapp::V1::StoragePool::StoragePool::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Netapp::V1::StoragePool::StoragePool::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Netapp::V1::StoragePool::StoragePool::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'ValidateDirectoryServiceRequest',
    as InstanceOf['Google::Cloud::Netapp::V1::StoragePool::ValidateDirectoryServiceRequest'];

coerce 'ValidateDirectoryServiceRequest',
    from HashRef, via { 'Google::Cloud::Netapp::V1::StoragePool::ValidateDirectoryServiceRequest'->new($_) };

declare 'RepeatedValidateDirectoryServiceRequest',
    as ArrayRef[ValidateDirectoryServiceRequest()];

coerce 'RepeatedValidateDirectoryServiceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Netapp::V1::StoragePool::ValidateDirectoryServiceRequest'->new($_) } @$_ ] };

declare 'MapStringValidateDirectoryServiceRequest',
    as HashRef[ValidateDirectoryServiceRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Netapp::V1::StoragePool::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
