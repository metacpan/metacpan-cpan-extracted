package Google::Cloud::Oracledatabase::V1::DbSystem::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'DbSystem',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::DbSystem::DbSystem'];

coerce 'DbSystem',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::DbSystem::DbSystem'->new($_) };

declare 'RepeatedDbSystem',
    as ArrayRef[DbSystem()];

coerce 'RepeatedDbSystem',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::DbSystem::DbSystem'->new($_) } @$_ ] };

declare 'MapStringDbSystem',
    as HashRef[DbSystem()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::DbSystem::DbSystem::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::DbSystem::DbSystem::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::DbSystem::DbSystem::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'DbSystemProperties',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::DbSystem::DbSystemProperties'];

coerce 'DbSystemProperties',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::DbSystem::DbSystemProperties'->new($_) };

declare 'RepeatedDbSystemProperties',
    as ArrayRef[DbSystemProperties()];

coerce 'RepeatedDbSystemProperties',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::DbSystem::DbSystemProperties'->new($_) } @$_ ] };

declare 'MapStringDbSystemProperties',
    as HashRef[DbSystemProperties()];

declare 'DbSystemDatabaseEdition',
    as (Int | Str);

declare 'LicenseModel',
    as (Int | Str);

declare 'DbSystemLifecycleState',
    as (Int | Str);

declare 'ComputeModel',
    as (Int | Str);

declare 'DataCollectionOptionsDbSystem',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::DbSystem::DataCollectionOptionsDbSystem'];

coerce 'DataCollectionOptionsDbSystem',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::DbSystem::DataCollectionOptionsDbSystem'->new($_) };

declare 'RepeatedDataCollectionOptionsDbSystem',
    as ArrayRef[DataCollectionOptionsDbSystem()];

coerce 'RepeatedDataCollectionOptionsDbSystem',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::DbSystem::DataCollectionOptionsDbSystem'->new($_) } @$_ ] };

declare 'MapStringDataCollectionOptionsDbSystem',
    as HashRef[DataCollectionOptionsDbSystem()];

declare 'DbSystemOptions',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::DbSystem::DbSystemOptions'];

coerce 'DbSystemOptions',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::DbSystem::DbSystemOptions'->new($_) };

declare 'RepeatedDbSystemOptions',
    as ArrayRef[DbSystemOptions()];

coerce 'RepeatedDbSystemOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::DbSystem::DbSystemOptions'->new($_) } @$_ ] };

declare 'MapStringDbSystemOptions',
    as HashRef[DbSystemOptions()];

declare 'StorageManagement',
    as (Int | Str);

declare 'DbHome',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::DbSystem::DbHome'];

coerce 'DbHome',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::DbSystem::DbHome'->new($_) };

declare 'RepeatedDbHome',
    as ArrayRef[DbHome()];

coerce 'RepeatedDbHome',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::DbSystem::DbHome'->new($_) } @$_ ] };

declare 'MapStringDbHome',
    as HashRef[DbHome()];

declare 'CreateDbSystemRequest',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::DbSystem::CreateDbSystemRequest'];

coerce 'CreateDbSystemRequest',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::DbSystem::CreateDbSystemRequest'->new($_) };

declare 'RepeatedCreateDbSystemRequest',
    as ArrayRef[CreateDbSystemRequest()];

coerce 'RepeatedCreateDbSystemRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::DbSystem::CreateDbSystemRequest'->new($_) } @$_ ] };

declare 'MapStringCreateDbSystemRequest',
    as HashRef[CreateDbSystemRequest()];

declare 'DeleteDbSystemRequest',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::DbSystem::DeleteDbSystemRequest'];

coerce 'DeleteDbSystemRequest',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::DbSystem::DeleteDbSystemRequest'->new($_) };

declare 'RepeatedDeleteDbSystemRequest',
    as ArrayRef[DeleteDbSystemRequest()];

coerce 'RepeatedDeleteDbSystemRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::DbSystem::DeleteDbSystemRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteDbSystemRequest',
    as HashRef[DeleteDbSystemRequest()];

declare 'UpdateDbSystemRequest',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::DbSystem::UpdateDbSystemRequest'];

coerce 'UpdateDbSystemRequest',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::DbSystem::UpdateDbSystemRequest'->new($_) };

declare 'RepeatedUpdateDbSystemRequest',
    as ArrayRef[UpdateDbSystemRequest()];

coerce 'RepeatedUpdateDbSystemRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::DbSystem::UpdateDbSystemRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateDbSystemRequest',
    as HashRef[UpdateDbSystemRequest()];

declare 'GetDbSystemRequest',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::DbSystem::GetDbSystemRequest'];

coerce 'GetDbSystemRequest',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::DbSystem::GetDbSystemRequest'->new($_) };

declare 'RepeatedGetDbSystemRequest',
    as ArrayRef[GetDbSystemRequest()];

coerce 'RepeatedGetDbSystemRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::DbSystem::GetDbSystemRequest'->new($_) } @$_ ] };

declare 'MapStringGetDbSystemRequest',
    as HashRef[GetDbSystemRequest()];

declare 'ListDbSystemsRequest',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::DbSystem::ListDbSystemsRequest'];

coerce 'ListDbSystemsRequest',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::DbSystem::ListDbSystemsRequest'->new($_) };

declare 'RepeatedListDbSystemsRequest',
    as ArrayRef[ListDbSystemsRequest()];

coerce 'RepeatedListDbSystemsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::DbSystem::ListDbSystemsRequest'->new($_) } @$_ ] };

declare 'MapStringListDbSystemsRequest',
    as HashRef[ListDbSystemsRequest()];

declare 'ListDbSystemsResponse',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::DbSystem::ListDbSystemsResponse'];

coerce 'ListDbSystemsResponse',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::DbSystem::ListDbSystemsResponse'->new($_) };

declare 'RepeatedListDbSystemsResponse',
    as ArrayRef[ListDbSystemsResponse()];

coerce 'RepeatedListDbSystemsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::DbSystem::ListDbSystemsResponse'->new($_) } @$_ ] };

declare 'MapStringListDbSystemsResponse',
    as HashRef[ListDbSystemsResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Oracledatabase::V1::DbSystem::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
