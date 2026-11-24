package Google::Cloud::Netapp::V1::BackupVault::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'BackupVault',
    as InstanceOf['Google::Cloud::Netapp::V1::BackupVault::BackupVault'];

coerce 'BackupVault',
    from HashRef, via { 'Google::Cloud::Netapp::V1::BackupVault::BackupVault'->new($_) };

declare 'RepeatedBackupVault',
    as ArrayRef[BackupVault()];

coerce 'RepeatedBackupVault',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Netapp::V1::BackupVault::BackupVault'->new($_) } @$_ ] };

declare 'MapStringBackupVault',
    as HashRef[BackupVault()];

declare 'State',
    as (Int | Str);

declare 'BackupVaultType',
    as (Int | Str);

declare 'EncryptionState',
    as (Int | Str);

declare 'BackupRetentionPolicy',
    as InstanceOf['Google::Cloud::Netapp::V1::BackupVault::BackupVault::BackupRetentionPolicy'];

coerce 'BackupRetentionPolicy',
    from HashRef, via { 'Google::Cloud::Netapp::V1::BackupVault::BackupVault::BackupRetentionPolicy'->new($_) };

declare 'RepeatedBackupRetentionPolicy',
    as ArrayRef[BackupRetentionPolicy()];

coerce 'RepeatedBackupRetentionPolicy',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Netapp::V1::BackupVault::BackupVault::BackupRetentionPolicy'->new($_) } @$_ ] };

declare 'MapStringBackupRetentionPolicy',
    as HashRef[BackupRetentionPolicy()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Netapp::V1::BackupVault::BackupVault::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Netapp::V1::BackupVault::BackupVault::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Netapp::V1::BackupVault::BackupVault::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'GetBackupVaultRequest',
    as InstanceOf['Google::Cloud::Netapp::V1::BackupVault::GetBackupVaultRequest'];

coerce 'GetBackupVaultRequest',
    from HashRef, via { 'Google::Cloud::Netapp::V1::BackupVault::GetBackupVaultRequest'->new($_) };

declare 'RepeatedGetBackupVaultRequest',
    as ArrayRef[GetBackupVaultRequest()];

coerce 'RepeatedGetBackupVaultRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Netapp::V1::BackupVault::GetBackupVaultRequest'->new($_) } @$_ ] };

declare 'MapStringGetBackupVaultRequest',
    as HashRef[GetBackupVaultRequest()];

declare 'ListBackupVaultsRequest',
    as InstanceOf['Google::Cloud::Netapp::V1::BackupVault::ListBackupVaultsRequest'];

coerce 'ListBackupVaultsRequest',
    from HashRef, via { 'Google::Cloud::Netapp::V1::BackupVault::ListBackupVaultsRequest'->new($_) };

declare 'RepeatedListBackupVaultsRequest',
    as ArrayRef[ListBackupVaultsRequest()];

coerce 'RepeatedListBackupVaultsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Netapp::V1::BackupVault::ListBackupVaultsRequest'->new($_) } @$_ ] };

declare 'MapStringListBackupVaultsRequest',
    as HashRef[ListBackupVaultsRequest()];

declare 'ListBackupVaultsResponse',
    as InstanceOf['Google::Cloud::Netapp::V1::BackupVault::ListBackupVaultsResponse'];

coerce 'ListBackupVaultsResponse',
    from HashRef, via { 'Google::Cloud::Netapp::V1::BackupVault::ListBackupVaultsResponse'->new($_) };

declare 'RepeatedListBackupVaultsResponse',
    as ArrayRef[ListBackupVaultsResponse()];

coerce 'RepeatedListBackupVaultsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Netapp::V1::BackupVault::ListBackupVaultsResponse'->new($_) } @$_ ] };

declare 'MapStringListBackupVaultsResponse',
    as HashRef[ListBackupVaultsResponse()];

declare 'CreateBackupVaultRequest',
    as InstanceOf['Google::Cloud::Netapp::V1::BackupVault::CreateBackupVaultRequest'];

coerce 'CreateBackupVaultRequest',
    from HashRef, via { 'Google::Cloud::Netapp::V1::BackupVault::CreateBackupVaultRequest'->new($_) };

declare 'RepeatedCreateBackupVaultRequest',
    as ArrayRef[CreateBackupVaultRequest()];

coerce 'RepeatedCreateBackupVaultRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Netapp::V1::BackupVault::CreateBackupVaultRequest'->new($_) } @$_ ] };

declare 'MapStringCreateBackupVaultRequest',
    as HashRef[CreateBackupVaultRequest()];

declare 'DeleteBackupVaultRequest',
    as InstanceOf['Google::Cloud::Netapp::V1::BackupVault::DeleteBackupVaultRequest'];

coerce 'DeleteBackupVaultRequest',
    from HashRef, via { 'Google::Cloud::Netapp::V1::BackupVault::DeleteBackupVaultRequest'->new($_) };

declare 'RepeatedDeleteBackupVaultRequest',
    as ArrayRef[DeleteBackupVaultRequest()];

coerce 'RepeatedDeleteBackupVaultRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Netapp::V1::BackupVault::DeleteBackupVaultRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteBackupVaultRequest',
    as HashRef[DeleteBackupVaultRequest()];

declare 'UpdateBackupVaultRequest',
    as InstanceOf['Google::Cloud::Netapp::V1::BackupVault::UpdateBackupVaultRequest'];

coerce 'UpdateBackupVaultRequest',
    from HashRef, via { 'Google::Cloud::Netapp::V1::BackupVault::UpdateBackupVaultRequest'->new($_) };

declare 'RepeatedUpdateBackupVaultRequest',
    as ArrayRef[UpdateBackupVaultRequest()];

coerce 'RepeatedUpdateBackupVaultRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Netapp::V1::BackupVault::UpdateBackupVaultRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateBackupVaultRequest',
    as HashRef[UpdateBackupVaultRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Netapp::V1::BackupVault::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
