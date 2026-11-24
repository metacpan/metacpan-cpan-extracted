package Google::Cloud::Oracledatabase::V1::ExascaleDbStorageVault::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ExascaleDbStorageVault',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::ExascaleDbStorageVault::ExascaleDbStorageVault'];

coerce 'ExascaleDbStorageVault',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::ExascaleDbStorageVault::ExascaleDbStorageVault'->new($_) };

declare 'RepeatedExascaleDbStorageVault',
    as ArrayRef[ExascaleDbStorageVault()];

coerce 'RepeatedExascaleDbStorageVault',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::ExascaleDbStorageVault::ExascaleDbStorageVault'->new($_) } @$_ ] };

declare 'MapStringExascaleDbStorageVault',
    as HashRef[ExascaleDbStorageVault()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::ExascaleDbStorageVault::ExascaleDbStorageVault::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::ExascaleDbStorageVault::ExascaleDbStorageVault::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::ExascaleDbStorageVault::ExascaleDbStorageVault::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'ExascaleDbStorageVaultProperties',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::ExascaleDbStorageVault::ExascaleDbStorageVaultProperties'];

coerce 'ExascaleDbStorageVaultProperties',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::ExascaleDbStorageVault::ExascaleDbStorageVaultProperties'->new($_) };

declare 'RepeatedExascaleDbStorageVaultProperties',
    as ArrayRef[ExascaleDbStorageVaultProperties()];

coerce 'RepeatedExascaleDbStorageVaultProperties',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::ExascaleDbStorageVault::ExascaleDbStorageVaultProperties'->new($_) } @$_ ] };

declare 'MapStringExascaleDbStorageVaultProperties',
    as HashRef[ExascaleDbStorageVaultProperties()];

declare 'State',
    as (Int | Str);

declare 'ShapeAttribute',
    as (Int | Str);

declare 'ExascaleDbStorageDetails',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::ExascaleDbStorageVault::ExascaleDbStorageDetails'];

coerce 'ExascaleDbStorageDetails',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::ExascaleDbStorageVault::ExascaleDbStorageDetails'->new($_) };

declare 'RepeatedExascaleDbStorageDetails',
    as ArrayRef[ExascaleDbStorageDetails()];

coerce 'RepeatedExascaleDbStorageDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::ExascaleDbStorageVault::ExascaleDbStorageDetails'->new($_) } @$_ ] };

declare 'MapStringExascaleDbStorageDetails',
    as HashRef[ExascaleDbStorageDetails()];

declare 'UpdateExascaleDbStorageVaultRequest',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::ExascaleDbStorageVault::UpdateExascaleDbStorageVaultRequest'];

coerce 'UpdateExascaleDbStorageVaultRequest',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::ExascaleDbStorageVault::UpdateExascaleDbStorageVaultRequest'->new($_) };

declare 'RepeatedUpdateExascaleDbStorageVaultRequest',
    as ArrayRef[UpdateExascaleDbStorageVaultRequest()];

coerce 'RepeatedUpdateExascaleDbStorageVaultRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::ExascaleDbStorageVault::UpdateExascaleDbStorageVaultRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateExascaleDbStorageVaultRequest',
    as HashRef[UpdateExascaleDbStorageVaultRequest()];

declare 'GetExascaleDbStorageVaultRequest',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::ExascaleDbStorageVault::GetExascaleDbStorageVaultRequest'];

coerce 'GetExascaleDbStorageVaultRequest',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::ExascaleDbStorageVault::GetExascaleDbStorageVaultRequest'->new($_) };

declare 'RepeatedGetExascaleDbStorageVaultRequest',
    as ArrayRef[GetExascaleDbStorageVaultRequest()];

coerce 'RepeatedGetExascaleDbStorageVaultRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::ExascaleDbStorageVault::GetExascaleDbStorageVaultRequest'->new($_) } @$_ ] };

declare 'MapStringGetExascaleDbStorageVaultRequest',
    as HashRef[GetExascaleDbStorageVaultRequest()];

declare 'ListExascaleDbStorageVaultsRequest',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::ExascaleDbStorageVault::ListExascaleDbStorageVaultsRequest'];

coerce 'ListExascaleDbStorageVaultsRequest',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::ExascaleDbStorageVault::ListExascaleDbStorageVaultsRequest'->new($_) };

declare 'RepeatedListExascaleDbStorageVaultsRequest',
    as ArrayRef[ListExascaleDbStorageVaultsRequest()];

coerce 'RepeatedListExascaleDbStorageVaultsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::ExascaleDbStorageVault::ListExascaleDbStorageVaultsRequest'->new($_) } @$_ ] };

declare 'MapStringListExascaleDbStorageVaultsRequest',
    as HashRef[ListExascaleDbStorageVaultsRequest()];

declare 'ListExascaleDbStorageVaultsResponse',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::ExascaleDbStorageVault::ListExascaleDbStorageVaultsResponse'];

coerce 'ListExascaleDbStorageVaultsResponse',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::ExascaleDbStorageVault::ListExascaleDbStorageVaultsResponse'->new($_) };

declare 'RepeatedListExascaleDbStorageVaultsResponse',
    as ArrayRef[ListExascaleDbStorageVaultsResponse()];

coerce 'RepeatedListExascaleDbStorageVaultsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::ExascaleDbStorageVault::ListExascaleDbStorageVaultsResponse'->new($_) } @$_ ] };

declare 'MapStringListExascaleDbStorageVaultsResponse',
    as HashRef[ListExascaleDbStorageVaultsResponse()];

declare 'CreateExascaleDbStorageVaultRequest',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::ExascaleDbStorageVault::CreateExascaleDbStorageVaultRequest'];

coerce 'CreateExascaleDbStorageVaultRequest',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::ExascaleDbStorageVault::CreateExascaleDbStorageVaultRequest'->new($_) };

declare 'RepeatedCreateExascaleDbStorageVaultRequest',
    as ArrayRef[CreateExascaleDbStorageVaultRequest()];

coerce 'RepeatedCreateExascaleDbStorageVaultRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::ExascaleDbStorageVault::CreateExascaleDbStorageVaultRequest'->new($_) } @$_ ] };

declare 'MapStringCreateExascaleDbStorageVaultRequest',
    as HashRef[CreateExascaleDbStorageVaultRequest()];

declare 'DeleteExascaleDbStorageVaultRequest',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::ExascaleDbStorageVault::DeleteExascaleDbStorageVaultRequest'];

coerce 'DeleteExascaleDbStorageVaultRequest',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::ExascaleDbStorageVault::DeleteExascaleDbStorageVaultRequest'->new($_) };

declare 'RepeatedDeleteExascaleDbStorageVaultRequest',
    as ArrayRef[DeleteExascaleDbStorageVaultRequest()];

coerce 'RepeatedDeleteExascaleDbStorageVaultRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::ExascaleDbStorageVault::DeleteExascaleDbStorageVaultRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteExascaleDbStorageVaultRequest',
    as HashRef[DeleteExascaleDbStorageVaultRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Oracledatabase::V1::ExascaleDbStorageVault::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
