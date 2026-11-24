package Google::Cloud::Oracledatabase::V1::DbSystemInitialStorageSize::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'DbSystemInitialStorageSize',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::DbSystemInitialStorageSize::DbSystemInitialStorageSize'];

coerce 'DbSystemInitialStorageSize',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::DbSystemInitialStorageSize::DbSystemInitialStorageSize'->new($_) };

declare 'RepeatedDbSystemInitialStorageSize',
    as ArrayRef[DbSystemInitialStorageSize()];

coerce 'RepeatedDbSystemInitialStorageSize',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::DbSystemInitialStorageSize::DbSystemInitialStorageSize'->new($_) } @$_ ] };

declare 'MapStringDbSystemInitialStorageSize',
    as HashRef[DbSystemInitialStorageSize()];

declare 'DbSystemInitialStorageSizeProperties',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::DbSystemInitialStorageSize::DbSystemInitialStorageSizeProperties'];

coerce 'DbSystemInitialStorageSizeProperties',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::DbSystemInitialStorageSize::DbSystemInitialStorageSizeProperties'->new($_) };

declare 'RepeatedDbSystemInitialStorageSizeProperties',
    as ArrayRef[DbSystemInitialStorageSizeProperties()];

coerce 'RepeatedDbSystemInitialStorageSizeProperties',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::DbSystemInitialStorageSize::DbSystemInitialStorageSizeProperties'->new($_) } @$_ ] };

declare 'MapStringDbSystemInitialStorageSizeProperties',
    as HashRef[DbSystemInitialStorageSizeProperties()];

declare 'StorageManagement',
    as (Int | Str);

declare 'ShapeType',
    as (Int | Str);

declare 'StorageSizeDetails',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::DbSystemInitialStorageSize::StorageSizeDetails'];

coerce 'StorageSizeDetails',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::DbSystemInitialStorageSize::StorageSizeDetails'->new($_) };

declare 'RepeatedStorageSizeDetails',
    as ArrayRef[StorageSizeDetails()];

coerce 'RepeatedStorageSizeDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::DbSystemInitialStorageSize::StorageSizeDetails'->new($_) } @$_ ] };

declare 'MapStringStorageSizeDetails',
    as HashRef[StorageSizeDetails()];

declare 'ListDbSystemInitialStorageSizesRequest',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::DbSystemInitialStorageSize::ListDbSystemInitialStorageSizesRequest'];

coerce 'ListDbSystemInitialStorageSizesRequest',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::DbSystemInitialStorageSize::ListDbSystemInitialStorageSizesRequest'->new($_) };

declare 'RepeatedListDbSystemInitialStorageSizesRequest',
    as ArrayRef[ListDbSystemInitialStorageSizesRequest()];

coerce 'RepeatedListDbSystemInitialStorageSizesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::DbSystemInitialStorageSize::ListDbSystemInitialStorageSizesRequest'->new($_) } @$_ ] };

declare 'MapStringListDbSystemInitialStorageSizesRequest',
    as HashRef[ListDbSystemInitialStorageSizesRequest()];

declare 'ListDbSystemInitialStorageSizesResponse',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::DbSystemInitialStorageSize::ListDbSystemInitialStorageSizesResponse'];

coerce 'ListDbSystemInitialStorageSizesResponse',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::DbSystemInitialStorageSize::ListDbSystemInitialStorageSizesResponse'->new($_) };

declare 'RepeatedListDbSystemInitialStorageSizesResponse',
    as ArrayRef[ListDbSystemInitialStorageSizesResponse()];

coerce 'RepeatedListDbSystemInitialStorageSizesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::DbSystemInitialStorageSize::ListDbSystemInitialStorageSizesResponse'->new($_) } @$_ ] };

declare 'MapStringListDbSystemInitialStorageSizesResponse',
    as HashRef[ListDbSystemInitialStorageSizesResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Oracledatabase::V1::DbSystemInitialStorageSize::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
