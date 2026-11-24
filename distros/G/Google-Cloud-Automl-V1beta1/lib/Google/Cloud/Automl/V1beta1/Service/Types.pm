package Google::Cloud::Automl::V1beta1::Service::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'CreateDatasetRequest',
    as InstanceOf['Google::Cloud::Automl::V1beta1::Service::CreateDatasetRequest'];

coerce 'CreateDatasetRequest',
    from HashRef, via { 'Google::Cloud::Automl::V1beta1::Service::CreateDatasetRequest'->new($_) };

declare 'RepeatedCreateDatasetRequest',
    as ArrayRef[CreateDatasetRequest()];

coerce 'RepeatedCreateDatasetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Automl::V1beta1::Service::CreateDatasetRequest'->new($_) } @$_ ] };

declare 'MapStringCreateDatasetRequest',
    as HashRef[CreateDatasetRequest()];

declare 'GetDatasetRequest',
    as InstanceOf['Google::Cloud::Automl::V1beta1::Service::GetDatasetRequest'];

coerce 'GetDatasetRequest',
    from HashRef, via { 'Google::Cloud::Automl::V1beta1::Service::GetDatasetRequest'->new($_) };

declare 'RepeatedGetDatasetRequest',
    as ArrayRef[GetDatasetRequest()];

coerce 'RepeatedGetDatasetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Automl::V1beta1::Service::GetDatasetRequest'->new($_) } @$_ ] };

declare 'MapStringGetDatasetRequest',
    as HashRef[GetDatasetRequest()];

declare 'ListDatasetsRequest',
    as InstanceOf['Google::Cloud::Automl::V1beta1::Service::ListDatasetsRequest'];

coerce 'ListDatasetsRequest',
    from HashRef, via { 'Google::Cloud::Automl::V1beta1::Service::ListDatasetsRequest'->new($_) };

declare 'RepeatedListDatasetsRequest',
    as ArrayRef[ListDatasetsRequest()];

coerce 'RepeatedListDatasetsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Automl::V1beta1::Service::ListDatasetsRequest'->new($_) } @$_ ] };

declare 'MapStringListDatasetsRequest',
    as HashRef[ListDatasetsRequest()];

declare 'ListDatasetsResponse',
    as InstanceOf['Google::Cloud::Automl::V1beta1::Service::ListDatasetsResponse'];

coerce 'ListDatasetsResponse',
    from HashRef, via { 'Google::Cloud::Automl::V1beta1::Service::ListDatasetsResponse'->new($_) };

declare 'RepeatedListDatasetsResponse',
    as ArrayRef[ListDatasetsResponse()];

coerce 'RepeatedListDatasetsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Automl::V1beta1::Service::ListDatasetsResponse'->new($_) } @$_ ] };

declare 'MapStringListDatasetsResponse',
    as HashRef[ListDatasetsResponse()];

declare 'UpdateDatasetRequest',
    as InstanceOf['Google::Cloud::Automl::V1beta1::Service::UpdateDatasetRequest'];

coerce 'UpdateDatasetRequest',
    from HashRef, via { 'Google::Cloud::Automl::V1beta1::Service::UpdateDatasetRequest'->new($_) };

declare 'RepeatedUpdateDatasetRequest',
    as ArrayRef[UpdateDatasetRequest()];

coerce 'RepeatedUpdateDatasetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Automl::V1beta1::Service::UpdateDatasetRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateDatasetRequest',
    as HashRef[UpdateDatasetRequest()];

declare 'DeleteDatasetRequest',
    as InstanceOf['Google::Cloud::Automl::V1beta1::Service::DeleteDatasetRequest'];

coerce 'DeleteDatasetRequest',
    from HashRef, via { 'Google::Cloud::Automl::V1beta1::Service::DeleteDatasetRequest'->new($_) };

declare 'RepeatedDeleteDatasetRequest',
    as ArrayRef[DeleteDatasetRequest()];

coerce 'RepeatedDeleteDatasetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Automl::V1beta1::Service::DeleteDatasetRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteDatasetRequest',
    as HashRef[DeleteDatasetRequest()];

declare 'ImportDataRequest',
    as InstanceOf['Google::Cloud::Automl::V1beta1::Service::ImportDataRequest'];

coerce 'ImportDataRequest',
    from HashRef, via { 'Google::Cloud::Automl::V1beta1::Service::ImportDataRequest'->new($_) };

declare 'RepeatedImportDataRequest',
    as ArrayRef[ImportDataRequest()];

coerce 'RepeatedImportDataRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Automl::V1beta1::Service::ImportDataRequest'->new($_) } @$_ ] };

declare 'MapStringImportDataRequest',
    as HashRef[ImportDataRequest()];

declare 'ExportDataRequest',
    as InstanceOf['Google::Cloud::Automl::V1beta1::Service::ExportDataRequest'];

coerce 'ExportDataRequest',
    from HashRef, via { 'Google::Cloud::Automl::V1beta1::Service::ExportDataRequest'->new($_) };

declare 'RepeatedExportDataRequest',
    as ArrayRef[ExportDataRequest()];

coerce 'RepeatedExportDataRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Automl::V1beta1::Service::ExportDataRequest'->new($_) } @$_ ] };

declare 'MapStringExportDataRequest',
    as HashRef[ExportDataRequest()];

declare 'GetAnnotationSpecRequest',
    as InstanceOf['Google::Cloud::Automl::V1beta1::Service::GetAnnotationSpecRequest'];

coerce 'GetAnnotationSpecRequest',
    from HashRef, via { 'Google::Cloud::Automl::V1beta1::Service::GetAnnotationSpecRequest'->new($_) };

declare 'RepeatedGetAnnotationSpecRequest',
    as ArrayRef[GetAnnotationSpecRequest()];

coerce 'RepeatedGetAnnotationSpecRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Automl::V1beta1::Service::GetAnnotationSpecRequest'->new($_) } @$_ ] };

declare 'MapStringGetAnnotationSpecRequest',
    as HashRef[GetAnnotationSpecRequest()];

declare 'GetTableSpecRequest',
    as InstanceOf['Google::Cloud::Automl::V1beta1::Service::GetTableSpecRequest'];

coerce 'GetTableSpecRequest',
    from HashRef, via { 'Google::Cloud::Automl::V1beta1::Service::GetTableSpecRequest'->new($_) };

declare 'RepeatedGetTableSpecRequest',
    as ArrayRef[GetTableSpecRequest()];

coerce 'RepeatedGetTableSpecRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Automl::V1beta1::Service::GetTableSpecRequest'->new($_) } @$_ ] };

declare 'MapStringGetTableSpecRequest',
    as HashRef[GetTableSpecRequest()];

declare 'ListTableSpecsRequest',
    as InstanceOf['Google::Cloud::Automl::V1beta1::Service::ListTableSpecsRequest'];

coerce 'ListTableSpecsRequest',
    from HashRef, via { 'Google::Cloud::Automl::V1beta1::Service::ListTableSpecsRequest'->new($_) };

declare 'RepeatedListTableSpecsRequest',
    as ArrayRef[ListTableSpecsRequest()];

coerce 'RepeatedListTableSpecsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Automl::V1beta1::Service::ListTableSpecsRequest'->new($_) } @$_ ] };

declare 'MapStringListTableSpecsRequest',
    as HashRef[ListTableSpecsRequest()];

declare 'ListTableSpecsResponse',
    as InstanceOf['Google::Cloud::Automl::V1beta1::Service::ListTableSpecsResponse'];

coerce 'ListTableSpecsResponse',
    from HashRef, via { 'Google::Cloud::Automl::V1beta1::Service::ListTableSpecsResponse'->new($_) };

declare 'RepeatedListTableSpecsResponse',
    as ArrayRef[ListTableSpecsResponse()];

coerce 'RepeatedListTableSpecsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Automl::V1beta1::Service::ListTableSpecsResponse'->new($_) } @$_ ] };

declare 'MapStringListTableSpecsResponse',
    as HashRef[ListTableSpecsResponse()];

declare 'UpdateTableSpecRequest',
    as InstanceOf['Google::Cloud::Automl::V1beta1::Service::UpdateTableSpecRequest'];

coerce 'UpdateTableSpecRequest',
    from HashRef, via { 'Google::Cloud::Automl::V1beta1::Service::UpdateTableSpecRequest'->new($_) };

declare 'RepeatedUpdateTableSpecRequest',
    as ArrayRef[UpdateTableSpecRequest()];

coerce 'RepeatedUpdateTableSpecRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Automl::V1beta1::Service::UpdateTableSpecRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateTableSpecRequest',
    as HashRef[UpdateTableSpecRequest()];

declare 'GetColumnSpecRequest',
    as InstanceOf['Google::Cloud::Automl::V1beta1::Service::GetColumnSpecRequest'];

coerce 'GetColumnSpecRequest',
    from HashRef, via { 'Google::Cloud::Automl::V1beta1::Service::GetColumnSpecRequest'->new($_) };

declare 'RepeatedGetColumnSpecRequest',
    as ArrayRef[GetColumnSpecRequest()];

coerce 'RepeatedGetColumnSpecRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Automl::V1beta1::Service::GetColumnSpecRequest'->new($_) } @$_ ] };

declare 'MapStringGetColumnSpecRequest',
    as HashRef[GetColumnSpecRequest()];

declare 'ListColumnSpecsRequest',
    as InstanceOf['Google::Cloud::Automl::V1beta1::Service::ListColumnSpecsRequest'];

coerce 'ListColumnSpecsRequest',
    from HashRef, via { 'Google::Cloud::Automl::V1beta1::Service::ListColumnSpecsRequest'->new($_) };

declare 'RepeatedListColumnSpecsRequest',
    as ArrayRef[ListColumnSpecsRequest()];

coerce 'RepeatedListColumnSpecsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Automl::V1beta1::Service::ListColumnSpecsRequest'->new($_) } @$_ ] };

declare 'MapStringListColumnSpecsRequest',
    as HashRef[ListColumnSpecsRequest()];

declare 'ListColumnSpecsResponse',
    as InstanceOf['Google::Cloud::Automl::V1beta1::Service::ListColumnSpecsResponse'];

coerce 'ListColumnSpecsResponse',
    from HashRef, via { 'Google::Cloud::Automl::V1beta1::Service::ListColumnSpecsResponse'->new($_) };

declare 'RepeatedListColumnSpecsResponse',
    as ArrayRef[ListColumnSpecsResponse()];

coerce 'RepeatedListColumnSpecsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Automl::V1beta1::Service::ListColumnSpecsResponse'->new($_) } @$_ ] };

declare 'MapStringListColumnSpecsResponse',
    as HashRef[ListColumnSpecsResponse()];

declare 'UpdateColumnSpecRequest',
    as InstanceOf['Google::Cloud::Automl::V1beta1::Service::UpdateColumnSpecRequest'];

coerce 'UpdateColumnSpecRequest',
    from HashRef, via { 'Google::Cloud::Automl::V1beta1::Service::UpdateColumnSpecRequest'->new($_) };

declare 'RepeatedUpdateColumnSpecRequest',
    as ArrayRef[UpdateColumnSpecRequest()];

coerce 'RepeatedUpdateColumnSpecRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Automl::V1beta1::Service::UpdateColumnSpecRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateColumnSpecRequest',
    as HashRef[UpdateColumnSpecRequest()];

declare 'CreateModelRequest',
    as InstanceOf['Google::Cloud::Automl::V1beta1::Service::CreateModelRequest'];

coerce 'CreateModelRequest',
    from HashRef, via { 'Google::Cloud::Automl::V1beta1::Service::CreateModelRequest'->new($_) };

declare 'RepeatedCreateModelRequest',
    as ArrayRef[CreateModelRequest()];

coerce 'RepeatedCreateModelRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Automl::V1beta1::Service::CreateModelRequest'->new($_) } @$_ ] };

declare 'MapStringCreateModelRequest',
    as HashRef[CreateModelRequest()];

declare 'GetModelRequest',
    as InstanceOf['Google::Cloud::Automl::V1beta1::Service::GetModelRequest'];

coerce 'GetModelRequest',
    from HashRef, via { 'Google::Cloud::Automl::V1beta1::Service::GetModelRequest'->new($_) };

declare 'RepeatedGetModelRequest',
    as ArrayRef[GetModelRequest()];

coerce 'RepeatedGetModelRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Automl::V1beta1::Service::GetModelRequest'->new($_) } @$_ ] };

declare 'MapStringGetModelRequest',
    as HashRef[GetModelRequest()];

declare 'ListModelsRequest',
    as InstanceOf['Google::Cloud::Automl::V1beta1::Service::ListModelsRequest'];

coerce 'ListModelsRequest',
    from HashRef, via { 'Google::Cloud::Automl::V1beta1::Service::ListModelsRequest'->new($_) };

declare 'RepeatedListModelsRequest',
    as ArrayRef[ListModelsRequest()];

coerce 'RepeatedListModelsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Automl::V1beta1::Service::ListModelsRequest'->new($_) } @$_ ] };

declare 'MapStringListModelsRequest',
    as HashRef[ListModelsRequest()];

declare 'ListModelsResponse',
    as InstanceOf['Google::Cloud::Automl::V1beta1::Service::ListModelsResponse'];

coerce 'ListModelsResponse',
    from HashRef, via { 'Google::Cloud::Automl::V1beta1::Service::ListModelsResponse'->new($_) };

declare 'RepeatedListModelsResponse',
    as ArrayRef[ListModelsResponse()];

coerce 'RepeatedListModelsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Automl::V1beta1::Service::ListModelsResponse'->new($_) } @$_ ] };

declare 'MapStringListModelsResponse',
    as HashRef[ListModelsResponse()];

declare 'DeleteModelRequest',
    as InstanceOf['Google::Cloud::Automl::V1beta1::Service::DeleteModelRequest'];

coerce 'DeleteModelRequest',
    from HashRef, via { 'Google::Cloud::Automl::V1beta1::Service::DeleteModelRequest'->new($_) };

declare 'RepeatedDeleteModelRequest',
    as ArrayRef[DeleteModelRequest()];

coerce 'RepeatedDeleteModelRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Automl::V1beta1::Service::DeleteModelRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteModelRequest',
    as HashRef[DeleteModelRequest()];

declare 'DeployModelRequest',
    as InstanceOf['Google::Cloud::Automl::V1beta1::Service::DeployModelRequest'];

coerce 'DeployModelRequest',
    from HashRef, via { 'Google::Cloud::Automl::V1beta1::Service::DeployModelRequest'->new($_) };

declare 'RepeatedDeployModelRequest',
    as ArrayRef[DeployModelRequest()];

coerce 'RepeatedDeployModelRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Automl::V1beta1::Service::DeployModelRequest'->new($_) } @$_ ] };

declare 'MapStringDeployModelRequest',
    as HashRef[DeployModelRequest()];

declare 'UndeployModelRequest',
    as InstanceOf['Google::Cloud::Automl::V1beta1::Service::UndeployModelRequest'];

coerce 'UndeployModelRequest',
    from HashRef, via { 'Google::Cloud::Automl::V1beta1::Service::UndeployModelRequest'->new($_) };

declare 'RepeatedUndeployModelRequest',
    as ArrayRef[UndeployModelRequest()];

coerce 'RepeatedUndeployModelRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Automl::V1beta1::Service::UndeployModelRequest'->new($_) } @$_ ] };

declare 'MapStringUndeployModelRequest',
    as HashRef[UndeployModelRequest()];

declare 'ExportModelRequest',
    as InstanceOf['Google::Cloud::Automl::V1beta1::Service::ExportModelRequest'];

coerce 'ExportModelRequest',
    from HashRef, via { 'Google::Cloud::Automl::V1beta1::Service::ExportModelRequest'->new($_) };

declare 'RepeatedExportModelRequest',
    as ArrayRef[ExportModelRequest()];

coerce 'RepeatedExportModelRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Automl::V1beta1::Service::ExportModelRequest'->new($_) } @$_ ] };

declare 'MapStringExportModelRequest',
    as HashRef[ExportModelRequest()];

declare 'ExportEvaluatedExamplesRequest',
    as InstanceOf['Google::Cloud::Automl::V1beta1::Service::ExportEvaluatedExamplesRequest'];

coerce 'ExportEvaluatedExamplesRequest',
    from HashRef, via { 'Google::Cloud::Automl::V1beta1::Service::ExportEvaluatedExamplesRequest'->new($_) };

declare 'RepeatedExportEvaluatedExamplesRequest',
    as ArrayRef[ExportEvaluatedExamplesRequest()];

coerce 'RepeatedExportEvaluatedExamplesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Automl::V1beta1::Service::ExportEvaluatedExamplesRequest'->new($_) } @$_ ] };

declare 'MapStringExportEvaluatedExamplesRequest',
    as HashRef[ExportEvaluatedExamplesRequest()];

declare 'GetModelEvaluationRequest',
    as InstanceOf['Google::Cloud::Automl::V1beta1::Service::GetModelEvaluationRequest'];

coerce 'GetModelEvaluationRequest',
    from HashRef, via { 'Google::Cloud::Automl::V1beta1::Service::GetModelEvaluationRequest'->new($_) };

declare 'RepeatedGetModelEvaluationRequest',
    as ArrayRef[GetModelEvaluationRequest()];

coerce 'RepeatedGetModelEvaluationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Automl::V1beta1::Service::GetModelEvaluationRequest'->new($_) } @$_ ] };

declare 'MapStringGetModelEvaluationRequest',
    as HashRef[GetModelEvaluationRequest()];

declare 'ListModelEvaluationsRequest',
    as InstanceOf['Google::Cloud::Automl::V1beta1::Service::ListModelEvaluationsRequest'];

coerce 'ListModelEvaluationsRequest',
    from HashRef, via { 'Google::Cloud::Automl::V1beta1::Service::ListModelEvaluationsRequest'->new($_) };

declare 'RepeatedListModelEvaluationsRequest',
    as ArrayRef[ListModelEvaluationsRequest()];

coerce 'RepeatedListModelEvaluationsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Automl::V1beta1::Service::ListModelEvaluationsRequest'->new($_) } @$_ ] };

declare 'MapStringListModelEvaluationsRequest',
    as HashRef[ListModelEvaluationsRequest()];

declare 'ListModelEvaluationsResponse',
    as InstanceOf['Google::Cloud::Automl::V1beta1::Service::ListModelEvaluationsResponse'];

coerce 'ListModelEvaluationsResponse',
    from HashRef, via { 'Google::Cloud::Automl::V1beta1::Service::ListModelEvaluationsResponse'->new($_) };

declare 'RepeatedListModelEvaluationsResponse',
    as ArrayRef[ListModelEvaluationsResponse()];

coerce 'RepeatedListModelEvaluationsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Automl::V1beta1::Service::ListModelEvaluationsResponse'->new($_) } @$_ ] };

declare 'MapStringListModelEvaluationsResponse',
    as HashRef[ListModelEvaluationsResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Automl::V1beta1::Service::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
