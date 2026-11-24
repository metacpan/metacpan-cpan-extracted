package Google::Cloud::Oracledatabase::V1::ExadbVmCluster::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ExadbVmCluster',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::ExadbVmCluster::ExadbVmCluster'];

coerce 'ExadbVmCluster',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::ExadbVmCluster::ExadbVmCluster'->new($_) };

declare 'RepeatedExadbVmCluster',
    as ArrayRef[ExadbVmCluster()];

coerce 'RepeatedExadbVmCluster',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::ExadbVmCluster::ExadbVmCluster'->new($_) } @$_ ] };

declare 'MapStringExadbVmCluster',
    as HashRef[ExadbVmCluster()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::ExadbVmCluster::ExadbVmCluster::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::ExadbVmCluster::ExadbVmCluster::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::ExadbVmCluster::ExadbVmCluster::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'ExadbVmClusterStorageDetails',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::ExadbVmCluster::ExadbVmClusterStorageDetails'];

coerce 'ExadbVmClusterStorageDetails',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::ExadbVmCluster::ExadbVmClusterStorageDetails'->new($_) };

declare 'RepeatedExadbVmClusterStorageDetails',
    as ArrayRef[ExadbVmClusterStorageDetails()];

coerce 'RepeatedExadbVmClusterStorageDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::ExadbVmCluster::ExadbVmClusterStorageDetails'->new($_) } @$_ ] };

declare 'MapStringExadbVmClusterStorageDetails',
    as HashRef[ExadbVmClusterStorageDetails()];

declare 'ExadbVmClusterProperties',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::ExadbVmCluster::ExadbVmClusterProperties'];

coerce 'ExadbVmClusterProperties',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::ExadbVmCluster::ExadbVmClusterProperties'->new($_) };

declare 'RepeatedExadbVmClusterProperties',
    as ArrayRef[ExadbVmClusterProperties()];

coerce 'RepeatedExadbVmClusterProperties',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::ExadbVmCluster::ExadbVmClusterProperties'->new($_) } @$_ ] };

declare 'MapStringExadbVmClusterProperties',
    as HashRef[ExadbVmClusterProperties()];

declare 'LicenseModel',
    as (Int | Str);

declare 'ExadbVmClusterLifecycleState',
    as (Int | Str);

declare 'ShapeAttribute',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Oracledatabase::V1::ExadbVmCluster::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
