package Google::Cloud::Automl::V1::Operations::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'OperationMetadata',
    as InstanceOf['Google::Cloud::Automl::V1::Operations::OperationMetadata'];

coerce 'OperationMetadata',
    from HashRef, via { 'Google::Cloud::Automl::V1::Operations::OperationMetadata'->new($_) };

declare 'RepeatedOperationMetadata',
    as ArrayRef[OperationMetadata()];

coerce 'RepeatedOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Automl::V1::Operations::OperationMetadata'->new($_) } @$_ ] };

declare 'MapStringOperationMetadata',
    as HashRef[OperationMetadata()];

declare 'DeleteOperationMetadata',
    as InstanceOf['Google::Cloud::Automl::V1::Operations::DeleteOperationMetadata'];

coerce 'DeleteOperationMetadata',
    from HashRef, via { 'Google::Cloud::Automl::V1::Operations::DeleteOperationMetadata'->new($_) };

declare 'RepeatedDeleteOperationMetadata',
    as ArrayRef[DeleteOperationMetadata()];

coerce 'RepeatedDeleteOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Automl::V1::Operations::DeleteOperationMetadata'->new($_) } @$_ ] };

declare 'MapStringDeleteOperationMetadata',
    as HashRef[DeleteOperationMetadata()];

declare 'DeployModelOperationMetadata',
    as InstanceOf['Google::Cloud::Automl::V1::Operations::DeployModelOperationMetadata'];

coerce 'DeployModelOperationMetadata',
    from HashRef, via { 'Google::Cloud::Automl::V1::Operations::DeployModelOperationMetadata'->new($_) };

declare 'RepeatedDeployModelOperationMetadata',
    as ArrayRef[DeployModelOperationMetadata()];

coerce 'RepeatedDeployModelOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Automl::V1::Operations::DeployModelOperationMetadata'->new($_) } @$_ ] };

declare 'MapStringDeployModelOperationMetadata',
    as HashRef[DeployModelOperationMetadata()];

declare 'UndeployModelOperationMetadata',
    as InstanceOf['Google::Cloud::Automl::V1::Operations::UndeployModelOperationMetadata'];

coerce 'UndeployModelOperationMetadata',
    from HashRef, via { 'Google::Cloud::Automl::V1::Operations::UndeployModelOperationMetadata'->new($_) };

declare 'RepeatedUndeployModelOperationMetadata',
    as ArrayRef[UndeployModelOperationMetadata()];

coerce 'RepeatedUndeployModelOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Automl::V1::Operations::UndeployModelOperationMetadata'->new($_) } @$_ ] };

declare 'MapStringUndeployModelOperationMetadata',
    as HashRef[UndeployModelOperationMetadata()];

declare 'CreateDatasetOperationMetadata',
    as InstanceOf['Google::Cloud::Automl::V1::Operations::CreateDatasetOperationMetadata'];

coerce 'CreateDatasetOperationMetadata',
    from HashRef, via { 'Google::Cloud::Automl::V1::Operations::CreateDatasetOperationMetadata'->new($_) };

declare 'RepeatedCreateDatasetOperationMetadata',
    as ArrayRef[CreateDatasetOperationMetadata()];

coerce 'RepeatedCreateDatasetOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Automl::V1::Operations::CreateDatasetOperationMetadata'->new($_) } @$_ ] };

declare 'MapStringCreateDatasetOperationMetadata',
    as HashRef[CreateDatasetOperationMetadata()];

declare 'CreateModelOperationMetadata',
    as InstanceOf['Google::Cloud::Automl::V1::Operations::CreateModelOperationMetadata'];

coerce 'CreateModelOperationMetadata',
    from HashRef, via { 'Google::Cloud::Automl::V1::Operations::CreateModelOperationMetadata'->new($_) };

declare 'RepeatedCreateModelOperationMetadata',
    as ArrayRef[CreateModelOperationMetadata()];

coerce 'RepeatedCreateModelOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Automl::V1::Operations::CreateModelOperationMetadata'->new($_) } @$_ ] };

declare 'MapStringCreateModelOperationMetadata',
    as HashRef[CreateModelOperationMetadata()];

declare 'ImportDataOperationMetadata',
    as InstanceOf['Google::Cloud::Automl::V1::Operations::ImportDataOperationMetadata'];

coerce 'ImportDataOperationMetadata',
    from HashRef, via { 'Google::Cloud::Automl::V1::Operations::ImportDataOperationMetadata'->new($_) };

declare 'RepeatedImportDataOperationMetadata',
    as ArrayRef[ImportDataOperationMetadata()];

coerce 'RepeatedImportDataOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Automl::V1::Operations::ImportDataOperationMetadata'->new($_) } @$_ ] };

declare 'MapStringImportDataOperationMetadata',
    as HashRef[ImportDataOperationMetadata()];

declare 'ExportDataOperationMetadata',
    as InstanceOf['Google::Cloud::Automl::V1::Operations::ExportDataOperationMetadata'];

coerce 'ExportDataOperationMetadata',
    from HashRef, via { 'Google::Cloud::Automl::V1::Operations::ExportDataOperationMetadata'->new($_) };

declare 'RepeatedExportDataOperationMetadata',
    as ArrayRef[ExportDataOperationMetadata()];

coerce 'RepeatedExportDataOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Automl::V1::Operations::ExportDataOperationMetadata'->new($_) } @$_ ] };

declare 'MapStringExportDataOperationMetadata',
    as HashRef[ExportDataOperationMetadata()];

declare 'ExportDataOutputInfo',
    as InstanceOf['Google::Cloud::Automl::V1::Operations::ExportDataOperationMetadata::ExportDataOutputInfo'];

coerce 'ExportDataOutputInfo',
    from HashRef, via { 'Google::Cloud::Automl::V1::Operations::ExportDataOperationMetadata::ExportDataOutputInfo'->new($_) };

declare 'RepeatedExportDataOutputInfo',
    as ArrayRef[ExportDataOutputInfo()];

coerce 'RepeatedExportDataOutputInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Automl::V1::Operations::ExportDataOperationMetadata::ExportDataOutputInfo'->new($_) } @$_ ] };

declare 'MapStringExportDataOutputInfo',
    as HashRef[ExportDataOutputInfo()];

declare 'BatchPredictOperationMetadata',
    as InstanceOf['Google::Cloud::Automl::V1::Operations::BatchPredictOperationMetadata'];

coerce 'BatchPredictOperationMetadata',
    from HashRef, via { 'Google::Cloud::Automl::V1::Operations::BatchPredictOperationMetadata'->new($_) };

declare 'RepeatedBatchPredictOperationMetadata',
    as ArrayRef[BatchPredictOperationMetadata()];

coerce 'RepeatedBatchPredictOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Automl::V1::Operations::BatchPredictOperationMetadata'->new($_) } @$_ ] };

declare 'MapStringBatchPredictOperationMetadata',
    as HashRef[BatchPredictOperationMetadata()];

declare 'BatchPredictOutputInfo',
    as InstanceOf['Google::Cloud::Automl::V1::Operations::BatchPredictOperationMetadata::BatchPredictOutputInfo'];

coerce 'BatchPredictOutputInfo',
    from HashRef, via { 'Google::Cloud::Automl::V1::Operations::BatchPredictOperationMetadata::BatchPredictOutputInfo'->new($_) };

declare 'RepeatedBatchPredictOutputInfo',
    as ArrayRef[BatchPredictOutputInfo()];

coerce 'RepeatedBatchPredictOutputInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Automl::V1::Operations::BatchPredictOperationMetadata::BatchPredictOutputInfo'->new($_) } @$_ ] };

declare 'MapStringBatchPredictOutputInfo',
    as HashRef[BatchPredictOutputInfo()];

declare 'ExportModelOperationMetadata',
    as InstanceOf['Google::Cloud::Automl::V1::Operations::ExportModelOperationMetadata'];

coerce 'ExportModelOperationMetadata',
    from HashRef, via { 'Google::Cloud::Automl::V1::Operations::ExportModelOperationMetadata'->new($_) };

declare 'RepeatedExportModelOperationMetadata',
    as ArrayRef[ExportModelOperationMetadata()];

coerce 'RepeatedExportModelOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Automl::V1::Operations::ExportModelOperationMetadata'->new($_) } @$_ ] };

declare 'MapStringExportModelOperationMetadata',
    as HashRef[ExportModelOperationMetadata()];

declare 'ExportModelOutputInfo',
    as InstanceOf['Google::Cloud::Automl::V1::Operations::ExportModelOperationMetadata::ExportModelOutputInfo'];

coerce 'ExportModelOutputInfo',
    from HashRef, via { 'Google::Cloud::Automl::V1::Operations::ExportModelOperationMetadata::ExportModelOutputInfo'->new($_) };

declare 'RepeatedExportModelOutputInfo',
    as ArrayRef[ExportModelOutputInfo()];

coerce 'RepeatedExportModelOutputInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Automl::V1::Operations::ExportModelOperationMetadata::ExportModelOutputInfo'->new($_) } @$_ ] };

declare 'MapStringExportModelOutputInfo',
    as HashRef[ExportModelOutputInfo()];

1;

__END__

=head1 NAME

Google::Cloud::Automl::V1::Operations::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
