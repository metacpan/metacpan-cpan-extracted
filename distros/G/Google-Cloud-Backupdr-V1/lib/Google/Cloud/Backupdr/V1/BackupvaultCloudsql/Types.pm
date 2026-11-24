package Google::Cloud::Backupdr::V1::BackupvaultCloudsql::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'CloudSqlInstanceDataSourceProperties',
    as InstanceOf['Google::Cloud::Backupdr::V1::BackupvaultCloudsql::CloudSqlInstanceDataSourceProperties'];

coerce 'CloudSqlInstanceDataSourceProperties',
    from HashRef, via { 'Google::Cloud::Backupdr::V1::BackupvaultCloudsql::CloudSqlInstanceDataSourceProperties'->new($_) };

declare 'RepeatedCloudSqlInstanceDataSourceProperties',
    as ArrayRef[CloudSqlInstanceDataSourceProperties()];

coerce 'RepeatedCloudSqlInstanceDataSourceProperties',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1::BackupvaultCloudsql::CloudSqlInstanceDataSourceProperties'->new($_) } @$_ ] };

declare 'MapStringCloudSqlInstanceDataSourceProperties',
    as HashRef[CloudSqlInstanceDataSourceProperties()];

declare 'CloudSqlInstanceBackupProperties',
    as InstanceOf['Google::Cloud::Backupdr::V1::BackupvaultCloudsql::CloudSqlInstanceBackupProperties'];

coerce 'CloudSqlInstanceBackupProperties',
    from HashRef, via { 'Google::Cloud::Backupdr::V1::BackupvaultCloudsql::CloudSqlInstanceBackupProperties'->new($_) };

declare 'RepeatedCloudSqlInstanceBackupProperties',
    as ArrayRef[CloudSqlInstanceBackupProperties()];

coerce 'RepeatedCloudSqlInstanceBackupProperties',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1::BackupvaultCloudsql::CloudSqlInstanceBackupProperties'->new($_) } @$_ ] };

declare 'MapStringCloudSqlInstanceBackupProperties',
    as HashRef[CloudSqlInstanceBackupProperties()];

declare 'CloudSqlInstanceDataSourceReferenceProperties',
    as InstanceOf['Google::Cloud::Backupdr::V1::BackupvaultCloudsql::CloudSqlInstanceDataSourceReferenceProperties'];

coerce 'CloudSqlInstanceDataSourceReferenceProperties',
    from HashRef, via { 'Google::Cloud::Backupdr::V1::BackupvaultCloudsql::CloudSqlInstanceDataSourceReferenceProperties'->new($_) };

declare 'RepeatedCloudSqlInstanceDataSourceReferenceProperties',
    as ArrayRef[CloudSqlInstanceDataSourceReferenceProperties()];

coerce 'RepeatedCloudSqlInstanceDataSourceReferenceProperties',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1::BackupvaultCloudsql::CloudSqlInstanceDataSourceReferenceProperties'->new($_) } @$_ ] };

declare 'MapStringCloudSqlInstanceDataSourceReferenceProperties',
    as HashRef[CloudSqlInstanceDataSourceReferenceProperties()];

declare 'CloudSqlInstanceInitializationConfig',
    as InstanceOf['Google::Cloud::Backupdr::V1::BackupvaultCloudsql::CloudSqlInstanceInitializationConfig'];

coerce 'CloudSqlInstanceInitializationConfig',
    from HashRef, via { 'Google::Cloud::Backupdr::V1::BackupvaultCloudsql::CloudSqlInstanceInitializationConfig'->new($_) };

declare 'RepeatedCloudSqlInstanceInitializationConfig',
    as ArrayRef[CloudSqlInstanceInitializationConfig()];

coerce 'RepeatedCloudSqlInstanceInitializationConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1::BackupvaultCloudsql::CloudSqlInstanceInitializationConfig'->new($_) } @$_ ] };

declare 'MapStringCloudSqlInstanceInitializationConfig',
    as HashRef[CloudSqlInstanceInitializationConfig()];

declare 'Edition',
    as (Int | Str);

declare 'CloudSqlInstanceBackupPlanAssociationProperties',
    as InstanceOf['Google::Cloud::Backupdr::V1::BackupvaultCloudsql::CloudSqlInstanceBackupPlanAssociationProperties'];

coerce 'CloudSqlInstanceBackupPlanAssociationProperties',
    from HashRef, via { 'Google::Cloud::Backupdr::V1::BackupvaultCloudsql::CloudSqlInstanceBackupPlanAssociationProperties'->new($_) };

declare 'RepeatedCloudSqlInstanceBackupPlanAssociationProperties',
    as ArrayRef[CloudSqlInstanceBackupPlanAssociationProperties()];

coerce 'RepeatedCloudSqlInstanceBackupPlanAssociationProperties',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1::BackupvaultCloudsql::CloudSqlInstanceBackupPlanAssociationProperties'->new($_) } @$_ ] };

declare 'MapStringCloudSqlInstanceBackupPlanAssociationProperties',
    as HashRef[CloudSqlInstanceBackupPlanAssociationProperties()];

1;

__END__

=head1 NAME

Google::Cloud::Backupdr::V1::BackupvaultCloudsql::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
