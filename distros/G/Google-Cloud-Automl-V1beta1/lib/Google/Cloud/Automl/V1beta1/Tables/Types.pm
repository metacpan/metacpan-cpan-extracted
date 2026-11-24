package Google::Cloud::Automl::V1beta1::Tables::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'TablesDatasetMetadata',
    as InstanceOf['Google::Cloud::Automl::V1beta1::Tables::TablesDatasetMetadata'];

coerce 'TablesDatasetMetadata',
    from HashRef, via { 'Google::Cloud::Automl::V1beta1::Tables::TablesDatasetMetadata'->new($_) };

declare 'RepeatedTablesDatasetMetadata',
    as ArrayRef[TablesDatasetMetadata()];

coerce 'RepeatedTablesDatasetMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Automl::V1beta1::Tables::TablesDatasetMetadata'->new($_) } @$_ ] };

declare 'MapStringTablesDatasetMetadata',
    as HashRef[TablesDatasetMetadata()];

declare 'TargetColumnCorrelationsEntry',
    as InstanceOf['Google::Cloud::Automl::V1beta1::Tables::TablesDatasetMetadata::TargetColumnCorrelationsEntry'];

coerce 'TargetColumnCorrelationsEntry',
    from HashRef, via { 'Google::Cloud::Automl::V1beta1::Tables::TablesDatasetMetadata::TargetColumnCorrelationsEntry'->new($_) };

declare 'RepeatedTargetColumnCorrelationsEntry',
    as ArrayRef[TargetColumnCorrelationsEntry()];

coerce 'RepeatedTargetColumnCorrelationsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Automl::V1beta1::Tables::TablesDatasetMetadata::TargetColumnCorrelationsEntry'->new($_) } @$_ ] };

declare 'MapStringTargetColumnCorrelationsEntry',
    as HashRef[TargetColumnCorrelationsEntry()];

declare 'TablesModelMetadata',
    as InstanceOf['Google::Cloud::Automl::V1beta1::Tables::TablesModelMetadata'];

coerce 'TablesModelMetadata',
    from HashRef, via { 'Google::Cloud::Automl::V1beta1::Tables::TablesModelMetadata'->new($_) };

declare 'RepeatedTablesModelMetadata',
    as ArrayRef[TablesModelMetadata()];

coerce 'RepeatedTablesModelMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Automl::V1beta1::Tables::TablesModelMetadata'->new($_) } @$_ ] };

declare 'MapStringTablesModelMetadata',
    as HashRef[TablesModelMetadata()];

declare 'TablesAnnotation',
    as InstanceOf['Google::Cloud::Automl::V1beta1::Tables::TablesAnnotation'];

coerce 'TablesAnnotation',
    from HashRef, via { 'Google::Cloud::Automl::V1beta1::Tables::TablesAnnotation'->new($_) };

declare 'RepeatedTablesAnnotation',
    as ArrayRef[TablesAnnotation()];

coerce 'RepeatedTablesAnnotation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Automl::V1beta1::Tables::TablesAnnotation'->new($_) } @$_ ] };

declare 'MapStringTablesAnnotation',
    as HashRef[TablesAnnotation()];

declare 'TablesModelColumnInfo',
    as InstanceOf['Google::Cloud::Automl::V1beta1::Tables::TablesModelColumnInfo'];

coerce 'TablesModelColumnInfo',
    from HashRef, via { 'Google::Cloud::Automl::V1beta1::Tables::TablesModelColumnInfo'->new($_) };

declare 'RepeatedTablesModelColumnInfo',
    as ArrayRef[TablesModelColumnInfo()];

coerce 'RepeatedTablesModelColumnInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Automl::V1beta1::Tables::TablesModelColumnInfo'->new($_) } @$_ ] };

declare 'MapStringTablesModelColumnInfo',
    as HashRef[TablesModelColumnInfo()];

1;

__END__

=head1 NAME

Google::Cloud::Automl::V1beta1::Tables::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
