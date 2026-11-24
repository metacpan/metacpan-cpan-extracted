package Google::Cloud::Oracledatabase::V1::ExadataInfra::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'CloudExadataInfrastructure',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::ExadataInfra::CloudExadataInfrastructure'];

coerce 'CloudExadataInfrastructure',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::ExadataInfra::CloudExadataInfrastructure'->new($_) };

declare 'RepeatedCloudExadataInfrastructure',
    as ArrayRef[CloudExadataInfrastructure()];

coerce 'RepeatedCloudExadataInfrastructure',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::ExadataInfra::CloudExadataInfrastructure'->new($_) } @$_ ] };

declare 'MapStringCloudExadataInfrastructure',
    as HashRef[CloudExadataInfrastructure()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::ExadataInfra::CloudExadataInfrastructure::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::ExadataInfra::CloudExadataInfrastructure::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::ExadataInfra::CloudExadataInfrastructure::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'CloudExadataInfrastructureProperties',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::ExadataInfra::CloudExadataInfrastructureProperties'];

coerce 'CloudExadataInfrastructureProperties',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::ExadataInfra::CloudExadataInfrastructureProperties'->new($_) };

declare 'RepeatedCloudExadataInfrastructureProperties',
    as ArrayRef[CloudExadataInfrastructureProperties()];

coerce 'RepeatedCloudExadataInfrastructureProperties',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::ExadataInfra::CloudExadataInfrastructureProperties'->new($_) } @$_ ] };

declare 'MapStringCloudExadataInfrastructureProperties',
    as HashRef[CloudExadataInfrastructureProperties()];

declare 'State',
    as (Int | Str);

declare 'ExascaleConfig',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::ExadataInfra::ExascaleConfig'];

coerce 'ExascaleConfig',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::ExadataInfra::ExascaleConfig'->new($_) };

declare 'RepeatedExascaleConfig',
    as ArrayRef[ExascaleConfig()];

coerce 'RepeatedExascaleConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::ExadataInfra::ExascaleConfig'->new($_) } @$_ ] };

declare 'MapStringExascaleConfig',
    as HashRef[ExascaleConfig()];

declare 'MaintenanceWindow',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::ExadataInfra::MaintenanceWindow'];

coerce 'MaintenanceWindow',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::ExadataInfra::MaintenanceWindow'->new($_) };

declare 'RepeatedMaintenanceWindow',
    as ArrayRef[MaintenanceWindow()];

coerce 'RepeatedMaintenanceWindow',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::ExadataInfra::MaintenanceWindow'->new($_) } @$_ ] };

declare 'MapStringMaintenanceWindow',
    as HashRef[MaintenanceWindow()];

declare 'MaintenanceWindowPreference',
    as (Int | Str);

declare 'PatchingMode',
    as (Int | Str);

declare 'ConfigureExascaleCloudExadataInfrastructureRequest',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::ExadataInfra::ConfigureExascaleCloudExadataInfrastructureRequest'];

coerce 'ConfigureExascaleCloudExadataInfrastructureRequest',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::ExadataInfra::ConfigureExascaleCloudExadataInfrastructureRequest'->new($_) };

declare 'RepeatedConfigureExascaleCloudExadataInfrastructureRequest',
    as ArrayRef[ConfigureExascaleCloudExadataInfrastructureRequest()];

coerce 'RepeatedConfigureExascaleCloudExadataInfrastructureRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::ExadataInfra::ConfigureExascaleCloudExadataInfrastructureRequest'->new($_) } @$_ ] };

declare 'MapStringConfigureExascaleCloudExadataInfrastructureRequest',
    as HashRef[ConfigureExascaleCloudExadataInfrastructureRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Oracledatabase::V1::ExadataInfra::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
