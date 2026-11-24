package Google::Cloud::Backupdr::V1beta::BackupvaultAlloydb::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'AlloyDBClusterDataSourceProperties',
    as InstanceOf['Google::Cloud::Backupdr::V1beta::BackupvaultAlloydb::AlloyDBClusterDataSourceProperties'];

coerce 'AlloyDBClusterDataSourceProperties',
    from HashRef, via { 'Google::Cloud::Backupdr::V1beta::BackupvaultAlloydb::AlloyDBClusterDataSourceProperties'->new($_) };

declare 'RepeatedAlloyDBClusterDataSourceProperties',
    as ArrayRef[AlloyDBClusterDataSourceProperties()];

coerce 'RepeatedAlloyDBClusterDataSourceProperties',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1beta::BackupvaultAlloydb::AlloyDBClusterDataSourceProperties'->new($_) } @$_ ] };

declare 'MapStringAlloyDBClusterDataSourceProperties',
    as HashRef[AlloyDBClusterDataSourceProperties()];

declare 'AlloyDBClusterDataSourceReferenceProperties',
    as InstanceOf['Google::Cloud::Backupdr::V1beta::BackupvaultAlloydb::AlloyDBClusterDataSourceReferenceProperties'];

coerce 'AlloyDBClusterDataSourceReferenceProperties',
    from HashRef, via { 'Google::Cloud::Backupdr::V1beta::BackupvaultAlloydb::AlloyDBClusterDataSourceReferenceProperties'->new($_) };

declare 'RepeatedAlloyDBClusterDataSourceReferenceProperties',
    as ArrayRef[AlloyDBClusterDataSourceReferenceProperties()];

coerce 'RepeatedAlloyDBClusterDataSourceReferenceProperties',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1beta::BackupvaultAlloydb::AlloyDBClusterDataSourceReferenceProperties'->new($_) } @$_ ] };

declare 'MapStringAlloyDBClusterDataSourceReferenceProperties',
    as HashRef[AlloyDBClusterDataSourceReferenceProperties()];

declare 'AlloyDbPitrWindow',
    as InstanceOf['Google::Cloud::Backupdr::V1beta::BackupvaultAlloydb::AlloyDbPitrWindow'];

coerce 'AlloyDbPitrWindow',
    from HashRef, via { 'Google::Cloud::Backupdr::V1beta::BackupvaultAlloydb::AlloyDbPitrWindow'->new($_) };

declare 'RepeatedAlloyDbPitrWindow',
    as ArrayRef[AlloyDbPitrWindow()];

coerce 'RepeatedAlloyDbPitrWindow',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1beta::BackupvaultAlloydb::AlloyDbPitrWindow'->new($_) } @$_ ] };

declare 'MapStringAlloyDbPitrWindow',
    as HashRef[AlloyDbPitrWindow()];

declare 'AlloyDbClusterBackupProperties',
    as InstanceOf['Google::Cloud::Backupdr::V1beta::BackupvaultAlloydb::AlloyDbClusterBackupProperties'];

coerce 'AlloyDbClusterBackupProperties',
    from HashRef, via { 'Google::Cloud::Backupdr::V1beta::BackupvaultAlloydb::AlloyDbClusterBackupProperties'->new($_) };

declare 'RepeatedAlloyDbClusterBackupProperties',
    as ArrayRef[AlloyDbClusterBackupProperties()];

coerce 'RepeatedAlloyDbClusterBackupProperties',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1beta::BackupvaultAlloydb::AlloyDbClusterBackupProperties'->new($_) } @$_ ] };

declare 'MapStringAlloyDbClusterBackupProperties',
    as HashRef[AlloyDbClusterBackupProperties()];

declare 'AlloyDBClusterBackupPlanAssociationProperties',
    as InstanceOf['Google::Cloud::Backupdr::V1beta::BackupvaultAlloydb::AlloyDBClusterBackupPlanAssociationProperties'];

coerce 'AlloyDBClusterBackupPlanAssociationProperties',
    from HashRef, via { 'Google::Cloud::Backupdr::V1beta::BackupvaultAlloydb::AlloyDBClusterBackupPlanAssociationProperties'->new($_) };

declare 'RepeatedAlloyDBClusterBackupPlanAssociationProperties',
    as ArrayRef[AlloyDBClusterBackupPlanAssociationProperties()];

coerce 'RepeatedAlloyDBClusterBackupPlanAssociationProperties',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1beta::BackupvaultAlloydb::AlloyDBClusterBackupPlanAssociationProperties'->new($_) } @$_ ] };

declare 'MapStringAlloyDBClusterBackupPlanAssociationProperties',
    as HashRef[AlloyDBClusterBackupPlanAssociationProperties()];

1;

__END__

=head1 NAME

Google::Cloud::Backupdr::V1beta::BackupvaultAlloydb::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
