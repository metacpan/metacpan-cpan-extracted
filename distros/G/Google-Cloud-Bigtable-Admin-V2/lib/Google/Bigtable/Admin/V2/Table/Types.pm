package Google::Bigtable::Admin::V2::Table::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'RestoreSourceType',
    as (Int | Str);

declare 'RestoreInfo',
    as InstanceOf['Google::Bigtable::Admin::V2::Table::RestoreInfo'];

coerce 'RestoreInfo',
    from HashRef, via { 'Google::Bigtable::Admin::V2::Table::RestoreInfo'->new($_) };

declare 'RepeatedRestoreInfo',
    as ArrayRef[RestoreInfo()];

coerce 'RepeatedRestoreInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::Table::RestoreInfo'->new($_) } @$_ ] };

declare 'MapStringRestoreInfo',
    as HashRef[RestoreInfo()];

declare 'ChangeStreamConfig',
    as InstanceOf['Google::Bigtable::Admin::V2::Table::ChangeStreamConfig'];

coerce 'ChangeStreamConfig',
    from HashRef, via { 'Google::Bigtable::Admin::V2::Table::ChangeStreamConfig'->new($_) };

declare 'RepeatedChangeStreamConfig',
    as ArrayRef[ChangeStreamConfig()];

coerce 'RepeatedChangeStreamConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::Table::ChangeStreamConfig'->new($_) } @$_ ] };

declare 'MapStringChangeStreamConfig',
    as HashRef[ChangeStreamConfig()];

declare 'Table',
    as InstanceOf['Google::Bigtable::Admin::V2::Table::Table'];

coerce 'Table',
    from HashRef, via { 'Google::Bigtable::Admin::V2::Table::Table'->new($_) };

declare 'RepeatedTable',
    as ArrayRef[Table()];

coerce 'RepeatedTable',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::Table::Table'->new($_) } @$_ ] };

declare 'MapStringTable',
    as HashRef[Table()];

declare 'TimestampGranularity',
    as (Int | Str);

declare 'View',
    as (Int | Str);

declare 'ClusterState',
    as InstanceOf['Google::Bigtable::Admin::V2::Table::Table::ClusterState'];

coerce 'ClusterState',
    from HashRef, via { 'Google::Bigtable::Admin::V2::Table::Table::ClusterState'->new($_) };

declare 'RepeatedClusterState',
    as ArrayRef[ClusterState()];

coerce 'RepeatedClusterState',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::Table::Table::ClusterState'->new($_) } @$_ ] };

declare 'MapStringClusterState',
    as HashRef[ClusterState()];

declare 'ReplicationState',
    as (Int | Str);

declare 'AutomatedBackupPolicy',
    as InstanceOf['Google::Bigtable::Admin::V2::Table::Table::AutomatedBackupPolicy'];

coerce 'AutomatedBackupPolicy',
    from HashRef, via { 'Google::Bigtable::Admin::V2::Table::Table::AutomatedBackupPolicy'->new($_) };

declare 'RepeatedAutomatedBackupPolicy',
    as ArrayRef[AutomatedBackupPolicy()];

coerce 'RepeatedAutomatedBackupPolicy',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::Table::Table::AutomatedBackupPolicy'->new($_) } @$_ ] };

declare 'MapStringAutomatedBackupPolicy',
    as HashRef[AutomatedBackupPolicy()];

declare 'ClusterStatesEntry',
    as InstanceOf['Google::Bigtable::Admin::V2::Table::Table::ClusterStatesEntry'];

coerce 'ClusterStatesEntry',
    from HashRef, via { 'Google::Bigtable::Admin::V2::Table::Table::ClusterStatesEntry'->new($_) };

declare 'RepeatedClusterStatesEntry',
    as ArrayRef[ClusterStatesEntry()];

coerce 'RepeatedClusterStatesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::Table::Table::ClusterStatesEntry'->new($_) } @$_ ] };

declare 'MapStringClusterStatesEntry',
    as HashRef[ClusterStatesEntry()];

declare 'ColumnFamiliesEntry',
    as InstanceOf['Google::Bigtable::Admin::V2::Table::Table::ColumnFamiliesEntry'];

coerce 'ColumnFamiliesEntry',
    from HashRef, via { 'Google::Bigtable::Admin::V2::Table::Table::ColumnFamiliesEntry'->new($_) };

declare 'RepeatedColumnFamiliesEntry',
    as ArrayRef[ColumnFamiliesEntry()];

coerce 'RepeatedColumnFamiliesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::Table::Table::ColumnFamiliesEntry'->new($_) } @$_ ] };

declare 'MapStringColumnFamiliesEntry',
    as HashRef[ColumnFamiliesEntry()];

declare 'AuthorizedView',
    as InstanceOf['Google::Bigtable::Admin::V2::Table::AuthorizedView'];

coerce 'AuthorizedView',
    from HashRef, via { 'Google::Bigtable::Admin::V2::Table::AuthorizedView'->new($_) };

declare 'RepeatedAuthorizedView',
    as ArrayRef[AuthorizedView()];

coerce 'RepeatedAuthorizedView',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::Table::AuthorizedView'->new($_) } @$_ ] };

declare 'MapStringAuthorizedView',
    as HashRef[AuthorizedView()];

declare 'ResponseView',
    as (Int | Str);

declare 'FamilySubsets',
    as InstanceOf['Google::Bigtable::Admin::V2::Table::AuthorizedView::FamilySubsets'];

coerce 'FamilySubsets',
    from HashRef, via { 'Google::Bigtable::Admin::V2::Table::AuthorizedView::FamilySubsets'->new($_) };

declare 'RepeatedFamilySubsets',
    as ArrayRef[FamilySubsets()];

coerce 'RepeatedFamilySubsets',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::Table::AuthorizedView::FamilySubsets'->new($_) } @$_ ] };

declare 'MapStringFamilySubsets',
    as HashRef[FamilySubsets()];

declare 'SubsetView',
    as InstanceOf['Google::Bigtable::Admin::V2::Table::AuthorizedView::SubsetView'];

coerce 'SubsetView',
    from HashRef, via { 'Google::Bigtable::Admin::V2::Table::AuthorizedView::SubsetView'->new($_) };

declare 'RepeatedSubsetView',
    as ArrayRef[SubsetView()];

coerce 'RepeatedSubsetView',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::Table::AuthorizedView::SubsetView'->new($_) } @$_ ] };

declare 'MapStringSubsetView',
    as HashRef[SubsetView()];

declare 'FamilySubsetsEntry',
    as InstanceOf['Google::Bigtable::Admin::V2::Table::AuthorizedView::SubsetView::FamilySubsetsEntry'];

coerce 'FamilySubsetsEntry',
    from HashRef, via { 'Google::Bigtable::Admin::V2::Table::AuthorizedView::SubsetView::FamilySubsetsEntry'->new($_) };

declare 'RepeatedFamilySubsetsEntry',
    as ArrayRef[FamilySubsetsEntry()];

coerce 'RepeatedFamilySubsetsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::Table::AuthorizedView::SubsetView::FamilySubsetsEntry'->new($_) } @$_ ] };

declare 'MapStringFamilySubsetsEntry',
    as HashRef[FamilySubsetsEntry()];

declare 'ColumnFamily',
    as InstanceOf['Google::Bigtable::Admin::V2::Table::ColumnFamily'];

coerce 'ColumnFamily',
    from HashRef, via { 'Google::Bigtable::Admin::V2::Table::ColumnFamily'->new($_) };

declare 'RepeatedColumnFamily',
    as ArrayRef[ColumnFamily()];

coerce 'RepeatedColumnFamily',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::Table::ColumnFamily'->new($_) } @$_ ] };

declare 'MapStringColumnFamily',
    as HashRef[ColumnFamily()];

declare 'GcRule',
    as InstanceOf['Google::Bigtable::Admin::V2::Table::GcRule'];

coerce 'GcRule',
    from HashRef, via { 'Google::Bigtable::Admin::V2::Table::GcRule'->new($_) };

declare 'RepeatedGcRule',
    as ArrayRef[GcRule()];

coerce 'RepeatedGcRule',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::Table::GcRule'->new($_) } @$_ ] };

declare 'MapStringGcRule',
    as HashRef[GcRule()];

declare 'Intersection',
    as InstanceOf['Google::Bigtable::Admin::V2::Table::GcRule::Intersection'];

coerce 'Intersection',
    from HashRef, via { 'Google::Bigtable::Admin::V2::Table::GcRule::Intersection'->new($_) };

declare 'RepeatedIntersection',
    as ArrayRef[Intersection()];

coerce 'RepeatedIntersection',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::Table::GcRule::Intersection'->new($_) } @$_ ] };

declare 'MapStringIntersection',
    as HashRef[Intersection()];

declare 'Union',
    as InstanceOf['Google::Bigtable::Admin::V2::Table::GcRule::Union'];

coerce 'Union',
    from HashRef, via { 'Google::Bigtable::Admin::V2::Table::GcRule::Union'->new($_) };

declare 'RepeatedUnion',
    as ArrayRef[Union()];

coerce 'RepeatedUnion',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::Table::GcRule::Union'->new($_) } @$_ ] };

declare 'MapStringUnion',
    as HashRef[Union()];

declare 'EncryptionInfo',
    as InstanceOf['Google::Bigtable::Admin::V2::Table::EncryptionInfo'];

coerce 'EncryptionInfo',
    from HashRef, via { 'Google::Bigtable::Admin::V2::Table::EncryptionInfo'->new($_) };

declare 'RepeatedEncryptionInfo',
    as ArrayRef[EncryptionInfo()];

coerce 'RepeatedEncryptionInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::Table::EncryptionInfo'->new($_) } @$_ ] };

declare 'MapStringEncryptionInfo',
    as HashRef[EncryptionInfo()];

declare 'EncryptionType',
    as (Int | Str);

declare 'Snapshot',
    as InstanceOf['Google::Bigtable::Admin::V2::Table::Snapshot'];

coerce 'Snapshot',
    from HashRef, via { 'Google::Bigtable::Admin::V2::Table::Snapshot'->new($_) };

declare 'RepeatedSnapshot',
    as ArrayRef[Snapshot()];

coerce 'RepeatedSnapshot',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::Table::Snapshot'->new($_) } @$_ ] };

declare 'MapStringSnapshot',
    as HashRef[Snapshot()];

declare 'State',
    as (Int | Str);

declare 'Backup',
    as InstanceOf['Google::Bigtable::Admin::V2::Table::Backup'];

coerce 'Backup',
    from HashRef, via { 'Google::Bigtable::Admin::V2::Table::Backup'->new($_) };

declare 'RepeatedBackup',
    as ArrayRef[Backup()];

coerce 'RepeatedBackup',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::Table::Backup'->new($_) } @$_ ] };

declare 'MapStringBackup',
    as HashRef[Backup()];

declare 'State',
    as (Int | Str);

declare 'BackupType',
    as (Int | Str);

declare 'BackupInfo',
    as InstanceOf['Google::Bigtable::Admin::V2::Table::BackupInfo'];

coerce 'BackupInfo',
    from HashRef, via { 'Google::Bigtable::Admin::V2::Table::BackupInfo'->new($_) };

declare 'RepeatedBackupInfo',
    as ArrayRef[BackupInfo()];

coerce 'RepeatedBackupInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::Table::BackupInfo'->new($_) } @$_ ] };

declare 'MapStringBackupInfo',
    as HashRef[BackupInfo()];

declare 'TieredStorageConfig',
    as InstanceOf['Google::Bigtable::Admin::V2::Table::TieredStorageConfig'];

coerce 'TieredStorageConfig',
    from HashRef, via { 'Google::Bigtable::Admin::V2::Table::TieredStorageConfig'->new($_) };

declare 'RepeatedTieredStorageConfig',
    as ArrayRef[TieredStorageConfig()];

coerce 'RepeatedTieredStorageConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::Table::TieredStorageConfig'->new($_) } @$_ ] };

declare 'MapStringTieredStorageConfig',
    as HashRef[TieredStorageConfig()];

declare 'TieredStorageRule',
    as InstanceOf['Google::Bigtable::Admin::V2::Table::TieredStorageRule'];

coerce 'TieredStorageRule',
    from HashRef, via { 'Google::Bigtable::Admin::V2::Table::TieredStorageRule'->new($_) };

declare 'RepeatedTieredStorageRule',
    as ArrayRef[TieredStorageRule()];

coerce 'RepeatedTieredStorageRule',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::Table::TieredStorageRule'->new($_) } @$_ ] };

declare 'MapStringTieredStorageRule',
    as HashRef[TieredStorageRule()];

declare 'ProtoSchema',
    as InstanceOf['Google::Bigtable::Admin::V2::Table::ProtoSchema'];

coerce 'ProtoSchema',
    from HashRef, via { 'Google::Bigtable::Admin::V2::Table::ProtoSchema'->new($_) };

declare 'RepeatedProtoSchema',
    as ArrayRef[ProtoSchema()];

coerce 'RepeatedProtoSchema',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::Table::ProtoSchema'->new($_) } @$_ ] };

declare 'MapStringProtoSchema',
    as HashRef[ProtoSchema()];

declare 'AvroSchema',
    as InstanceOf['Google::Bigtable::Admin::V2::Table::AvroSchema'];

coerce 'AvroSchema',
    from HashRef, via { 'Google::Bigtable::Admin::V2::Table::AvroSchema'->new($_) };

declare 'RepeatedAvroSchema',
    as ArrayRef[AvroSchema()];

coerce 'RepeatedAvroSchema',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::Table::AvroSchema'->new($_) } @$_ ] };

declare 'MapStringAvroSchema',
    as HashRef[AvroSchema()];

declare 'SchemaBundle',
    as InstanceOf['Google::Bigtable::Admin::V2::Table::SchemaBundle'];

coerce 'SchemaBundle',
    from HashRef, via { 'Google::Bigtable::Admin::V2::Table::SchemaBundle'->new($_) };

declare 'RepeatedSchemaBundle',
    as ArrayRef[SchemaBundle()];

coerce 'RepeatedSchemaBundle',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::Admin::V2::Table::SchemaBundle'->new($_) } @$_ ] };

declare 'MapStringSchemaBundle',
    as HashRef[SchemaBundle()];

1;

__END__

=head1 NAME

Google::Bigtable::Admin::V2::Table::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
