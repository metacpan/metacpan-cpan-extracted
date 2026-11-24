package Google::Cloud::Automl::V1::Service::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'CreateDatasetRequest',
    as InstanceOf['Google::Cloud::Automl::V1::Service::CreateDatasetRequest'];

coerce 'CreateDatasetRequest',
    from HashRef, via { 'Google::Cloud::Automl::V1::Service::CreateDatasetRequest'->new($_) };

declare 'RepeatedCreateDatasetRequest',
    as ArrayRef[CreateDatasetRequest()];

coerce 'RepeatedCreateDatasetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Automl::V1::Service::CreateDatasetRequest'->new($_) } @$_ ] };

declare 'MapStringCreateDatasetRequest',
    as HashRef[CreateDatasetRequest()];

declare 'GetDatasetRequest',
    as InstanceOf['Google::Cloud::Automl::V1::Service::GetDatasetRequest'];

coerce 'GetDatasetRequest',
    from HashRef, via { 'Google::Cloud::Automl::V1::Service::GetDatasetRequest'->new($_) };

declare 'RepeatedGetDatasetRequest',
    as ArrayRef[GetDatasetRequest()];

coerce 'RepeatedGetDatasetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Automl::V1::Service::GetDatasetRequest'->new($_) } @$_ ] };

declare 'MapStringGetDatasetRequest',
    as HashRef[GetDatasetRequest()];

declare 'ListDatasetsRequest',
    as InstanceOf['Google::Cloud::Automl::V1::Service::ListDatasetsRequest'];

coerce 'ListDatasetsRequest',
    from HashRef, via { 'Google::Cloud::Automl::V1::Service::ListDatasetsRequest'->new($_) };

declare 'RepeatedListDatasetsRequest',
    as ArrayRef[ListDatasetsRequest()];

coerce 'RepeatedListDatasetsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Automl::V1::Service::ListDatasetsRequest'->new($_) } @$_ ] };

declare 'MapStringListDatasetsRequest',
    as HashRef[ListDatasetsRequest()];

declare 'ListDatasetsResponse',
    as InstanceOf['Google::Cloud::Automl::V1::Service::ListDatasetsResponse'];

coerce 'ListDatasetsResponse',
    from HashRef, via { 'Google::Cloud::Automl::V1::Service::ListDatasetsResponse'->new($_) };

declare 'RepeatedListDatasetsResponse',
    as ArrayRef[ListDatasetsResponse()];

coerce 'RepeatedListDatasetsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Automl::V1::Service::ListDatasetsResponse'->new($_) } @$_ ] };

declare 'MapStringListDatasetsResponse',
    as HashRef[ListDatasetsResponse()];

declare 'UpdateDatasetRequest',
    as InstanceOf['Google::Cloud::Automl::V1::Service::UpdateDatasetRequest'];

coerce 'UpdateDatasetRequest',
    from HashRef, via { 'Google::Cloud::Automl::V1::Service::UpdateDatasetRequest'->new($_) };

declare 'RepeatedUpdateDatasetRequest',
    as ArrayRef[UpdateDatasetRequest()];

coerce 'RepeatedUpdateDatasetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Automl::V1::Service::UpdateDatasetRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateDatasetRequest',
    as HashRef[UpdateDatasetRequest()];

declare 'DeleteDatasetRequest',
    as InstanceOf['Google::Cloud::Automl::V1::Service::DeleteDatasetRequest'];

coerce 'DeleteDatasetRequest',
    from HashRef, via { 'Google::Cloud::Automl::V1::Service::DeleteDatasetRequest'->new($_) };

declare 'RepeatedDeleteDatasetRequest',
    as ArrayRef[DeleteDatasetRequest()];

coerce 'RepeatedDeleteDatasetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Automl::V1::Service::DeleteDatasetRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteDatasetRequest',
    as HashRef[DeleteDatasetRequest()];

declare 'ImportDataRequest',
    as InstanceOf['Google::Cloud::Automl::V1::Service::ImportDataRequest'];

coerce 'ImportDataRequest',
    from HashRef, via { 'Google::Cloud::Automl::V1::Service::ImportDataRequest'->new($_) };

declare 'RepeatedImportDataRequest',
    as ArrayRef[ImportDataRequest()];

coerce 'RepeatedImportDataRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Automl::V1::Service::ImportDataRequest'->new($_) } @$_ ] };

declare 'MapStringImportDataRequest',
    as HashRef[ImportDataRequest()];

declare 'ExportDataRequest',
    as InstanceOf['Google::Cloud::Automl::V1::Service::ExportDataRequest'];

coerce 'ExportDataRequest',
    from HashRef, via { 'Google::Cloud::Automl::V1::Service::ExportDataRequest'->new($_) };

declare 'RepeatedExportDataRequest',
    as ArrayRef[ExportDataRequest()];

coerce 'RepeatedExportDataRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Automl::V1::Service::ExportDataRequest'->new($_) } @$_ ] };

declare 'MapStringExportDataRequest',
    as HashRef[ExportDataRequest()];

declare 'GetAnnotationSpecRequest',
    as InstanceOf['Google::Cloud::Automl::V1::Service::GetAnnotationSpecRequest'];

coerce 'GetAnnotationSpecRequest',
    from HashRef, via { 'Google::Cloud::Automl::V1::Service::GetAnnotationSpecRequest'->new($_) };

declare 'RepeatedGetAnnotationSpecRequest',
    as ArrayRef[GetAnnotationSpecRequest()];

coerce 'RepeatedGetAnnotationSpecRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Automl::V1::Service::GetAnnotationSpecRequest'->new($_) } @$_ ] };

declare 'MapStringGetAnnotationSpecRequest',
    as HashRef[GetAnnotationSpecRequest()];

declare 'CreateModelRequest',
    as InstanceOf['Google::Cloud::Automl::V1::Service::CreateModelRequest'];

coerce 'CreateModelRequest',
    from HashRef, via { 'Google::Cloud::Automl::V1::Service::CreateModelRequest'->new($_) };

declare 'RepeatedCreateModelRequest',
    as ArrayRef[CreateModelRequest()];

coerce 'RepeatedCreateModelRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Automl::V1::Service::CreateModelRequest'->new($_) } @$_ ] };

declare 'MapStringCreateModelRequest',
    as HashRef[CreateModelRequest()];

declare 'GetModelRequest',
    as InstanceOf['Google::Cloud::Automl::V1::Service::GetModelRequest'];

coerce 'GetModelRequest',
    from HashRef, via { 'Google::Cloud::Automl::V1::Service::GetModelRequest'->new($_) };

declare 'RepeatedGetModelRequest',
    as ArrayRef[GetModelRequest()];

coerce 'RepeatedGetModelRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Automl::V1::Service::GetModelRequest'->new($_) } @$_ ] };

declare 'MapStringGetModelRequest',
    as HashRef[GetModelRequest()];

declare 'ListModelsRequest',
    as InstanceOf['Google::Cloud::Automl::V1::Service::ListModelsRequest'];

coerce 'ListModelsRequest',
    from HashRef, via { 'Google::Cloud::Automl::V1::Service::ListModelsRequest'->new($_) };

declare 'RepeatedListModelsRequest',
    as ArrayRef[ListModelsRequest()];

coerce 'RepeatedListModelsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Automl::V1::Service::ListModelsRequest'->new($_) } @$_ ] };

declare 'MapStringListModelsRequest',
    as HashRef[ListModelsRequest()];

declare 'ListModelsResponse',
    as InstanceOf['Google::Cloud::Automl::V1::Service::ListModelsResponse'];

coerce 'ListModelsResponse',
    from HashRef, via { 'Google::Cloud::Automl::V1::Service::ListModelsResponse'->new($_) };

declare 'RepeatedListModelsResponse',
    as ArrayRef[ListModelsResponse()];

coerce 'RepeatedListModelsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Automl::V1::Service::ListModelsResponse'->new($_) } @$_ ] };

declare 'MapStringListModelsResponse',
    as HashRef[ListModelsResponse()];

declare 'DeleteModelRequest',
    as InstanceOf['Google::Cloud::Automl::V1::Service::DeleteModelRequest'];

coerce 'DeleteModelRequest',
    from HashRef, via { 'Google::Cloud::Automl::V1::Service::DeleteModelRequest'->new($_) };

declare 'RepeatedDeleteModelRequest',
    as ArrayRef[DeleteModelRequest()];

coerce 'RepeatedDeleteModelRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Automl::V1::Service::DeleteModelRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteModelRequest',
    as HashRef[DeleteModelRequest()];

declare 'UpdateModelRequest',
    as InstanceOf['Google::Cloud::Automl::V1::Service::UpdateModelRequest'];

coerce 'UpdateModelRequest',
    from HashRef, via { 'Google::Cloud::Automl::V1::Service::UpdateModelRequest'->new($_) };

declare 'RepeatedUpdateModelRequest',
    as ArrayRef[UpdateModelRequest()];

coerce 'RepeatedUpdateModelRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Automl::V1::Service::UpdateModelRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateModelRequest',
    as HashRef[UpdateModelRequest()];

declare 'DeployModelRequest',
    as InstanceOf['Google::Cloud::Automl::V1::Service::DeployModelRequest'];

coerce 'DeployModelRequest',
    from HashRef, via { 'Google::Cloud::Automl::V1::Service::DeployModelRequest'->new($_) };

declare 'RepeatedDeployModelRequest',
    as ArrayRef[DeployModelRequest()];

coerce 'RepeatedDeployModelRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Automl::V1::Service::DeployModelRequest'->new($_) } @$_ ] };

declare 'MapStringDeployModelRequest',
    as HashRef[DeployModelRequest()];

declare 'UndeployModelRequest',
    as InstanceOf['Google::Cloud::Automl::V1::Service::UndeployModelRequest'];

coerce 'UndeployModelRequest',
    from HashRef, via { 'Google::Cloud::Automl::V1::Service::UndeployModelRequest'->new($_) };

declare 'RepeatedUndeployModelRequest',
    as ArrayRef[UndeployModelRequest()];

coerce 'RepeatedUndeployModelRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Automl::V1::Service::UndeployModelRequest'->new($_) } @$_ ] };

declare 'MapStringUndeployModelRequest',
    as HashRef[UndeployModelRequest()];

declare 'ExportModelRequest',
    as InstanceOf['Google::Cloud::Automl::V1::Service::ExportModelRequest'];

coerce 'ExportModelRequest',
    from HashRef, via { 'Google::Cloud::Automl::V1::Service::ExportModelRequest'->new($_) };

declare 'RepeatedExportModelRequest',
    as ArrayRef[ExportModelRequest()];

coerce 'RepeatedExportModelRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Automl::V1::Service::ExportModelRequest'->new($_) } @$_ ] };

declare 'MapStringExportModelRequest',
    as HashRef[ExportModelRequest()];

declare 'GetModelEvaluationRequest',
    as InstanceOf['Google::Cloud::Automl::V1::Service::GetModelEvaluationRequest'];

coerce 'GetModelEvaluationRequest',
    from HashRef, via { 'Google::Cloud::Automl::V1::Service::GetModelEvaluationRequest'->new($_) };

declare 'RepeatedGetModelEvaluationRequest',
    as ArrayRef[GetModelEvaluationRequest()];

coerce 'RepeatedGetModelEvaluationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Automl::V1::Service::GetModelEvaluationRequest'->new($_) } @$_ ] };

declare 'MapStringGetModelEvaluationRequest',
    as HashRef[GetModelEvaluationRequest()];

declare 'ListModelEvaluationsRequest',
    as InstanceOf['Google::Cloud::Automl::V1::Service::ListModelEvaluationsRequest'];

coerce 'ListModelEvaluationsRequest',
    from HashRef, via { 'Google::Cloud::Automl::V1::Service::ListModelEvaluationsRequest'->new($_) };

declare 'RepeatedListModelEvaluationsRequest',
    as ArrayRef[ListModelEvaluationsRequest()];

coerce 'RepeatedListModelEvaluationsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Automl::V1::Service::ListModelEvaluationsRequest'->new($_) } @$_ ] };

declare 'MapStringListModelEvaluationsRequest',
    as HashRef[ListModelEvaluationsRequest()];

declare 'ListModelEvaluationsResponse',
    as InstanceOf['Google::Cloud::Automl::V1::Service::ListModelEvaluationsResponse'];

coerce 'ListModelEvaluationsResponse',
    from HashRef, via { 'Google::Cloud::Automl::V1::Service::ListModelEvaluationsResponse'->new($_) };

declare 'RepeatedListModelEvaluationsResponse',
    as ArrayRef[ListModelEvaluationsResponse()];

coerce 'RepeatedListModelEvaluationsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Automl::V1::Service::ListModelEvaluationsResponse'->new($_) } @$_ ] };

declare 'MapStringListModelEvaluationsResponse',
    as HashRef[ListModelEvaluationsResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Automl::V1::Service::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
