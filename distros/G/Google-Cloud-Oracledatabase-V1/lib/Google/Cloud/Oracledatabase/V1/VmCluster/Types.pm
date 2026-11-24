package Google::Cloud::Oracledatabase::V1::VmCluster::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'CloudVmCluster',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::VmCluster::CloudVmCluster'];

coerce 'CloudVmCluster',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::VmCluster::CloudVmCluster'->new($_) };

declare 'RepeatedCloudVmCluster',
    as ArrayRef[CloudVmCluster()];

coerce 'RepeatedCloudVmCluster',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::VmCluster::CloudVmCluster'->new($_) } @$_ ] };

declare 'MapStringCloudVmCluster',
    as HashRef[CloudVmCluster()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::VmCluster::CloudVmCluster::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::VmCluster::CloudVmCluster::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::VmCluster::CloudVmCluster::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'CloudVmClusterProperties',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::VmCluster::CloudVmClusterProperties'];

coerce 'CloudVmClusterProperties',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::VmCluster::CloudVmClusterProperties'->new($_) };

declare 'RepeatedCloudVmClusterProperties',
    as ArrayRef[CloudVmClusterProperties()];

coerce 'RepeatedCloudVmClusterProperties',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::VmCluster::CloudVmClusterProperties'->new($_) } @$_ ] };

declare 'MapStringCloudVmClusterProperties',
    as HashRef[CloudVmClusterProperties()];

declare 'LicenseType',
    as (Int | Str);

declare 'DiskRedundancy',
    as (Int | Str);

declare 'State',
    as (Int | Str);

declare 'StorageManagementType',
    as (Int | Str);

declare 'VmFileSystemStorageType',
    as (Int | Str);

declare 'VmBackupStorageType',
    as (Int | Str);

declare 'DataCollectionOptions',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::VmCluster::DataCollectionOptions'];

coerce 'DataCollectionOptions',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::VmCluster::DataCollectionOptions'->new($_) };

declare 'RepeatedDataCollectionOptions',
    as ArrayRef[DataCollectionOptions()];

coerce 'RepeatedDataCollectionOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::VmCluster::DataCollectionOptions'->new($_) } @$_ ] };

declare 'MapStringDataCollectionOptions',
    as HashRef[DataCollectionOptions()];

1;

__END__

=head1 NAME

Google::Cloud::Oracledatabase::V1::VmCluster::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
