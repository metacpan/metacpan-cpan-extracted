package Google::Cloud::Datalabeling::V1beta1::DataLabelingService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'CreateDatasetRequest',
    as InstanceOf['Google::Cloud::Datalabeling::V1beta1::DataLabelingService::CreateDatasetRequest'];

coerce 'CreateDatasetRequest',
    from HashRef, via { 'Google::Cloud::Datalabeling::V1beta1::DataLabelingService::CreateDatasetRequest'->new($_) };

declare 'RepeatedCreateDatasetRequest',
    as ArrayRef[CreateDatasetRequest()];

coerce 'RepeatedCreateDatasetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datalabeling::V1beta1::DataLabelingService::CreateDatasetRequest'->new($_) } @$_ ] };

declare 'MapStringCreateDatasetRequest',
    as HashRef[CreateDatasetRequest()];

declare 'GetDatasetRequest',
    as InstanceOf['Google::Cloud::Datalabeling::V1beta1::DataLabelingService::GetDatasetRequest'];

coerce 'GetDatasetRequest',
    from HashRef, via { 'Google::Cloud::Datalabeling::V1beta1::DataLabelingService::GetDatasetRequest'->new($_) };

declare 'RepeatedGetDatasetRequest',
    as ArrayRef[GetDatasetRequest()];

coerce 'RepeatedGetDatasetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datalabeling::V1beta1::DataLabelingService::GetDatasetRequest'->new($_) } @$_ ] };

declare 'MapStringGetDatasetRequest',
    as HashRef[GetDatasetRequest()];

declare 'ListDatasetsRequest',
    as InstanceOf['Google::Cloud::Datalabeling::V1beta1::DataLabelingService::ListDatasetsRequest'];

coerce 'ListDatasetsRequest',
    from HashRef, via { 'Google::Cloud::Datalabeling::V1beta1::DataLabelingService::ListDatasetsRequest'->new($_) };

declare 'RepeatedListDatasetsRequest',
    as ArrayRef[ListDatasetsRequest()];

coerce 'RepeatedListDatasetsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datalabeling::V1beta1::DataLabelingService::ListDatasetsRequest'->new($_) } @$_ ] };

declare 'MapStringListDatasetsRequest',
    as HashRef[ListDatasetsRequest()];

declare 'ListDatasetsResponse',
    as InstanceOf['Google::Cloud::Datalabeling::V1beta1::DataLabelingService::ListDatasetsResponse'];

coerce 'ListDatasetsResponse',
    from HashRef, via { 'Google::Cloud::Datalabeling::V1beta1::DataLabelingService::ListDatasetsResponse'->new($_) };

declare 'RepeatedListDatasetsResponse',
    as ArrayRef[ListDatasetsResponse()];

coerce 'RepeatedListDatasetsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datalabeling::V1beta1::DataLabelingService::ListDatasetsResponse'->new($_) } @$_ ] };

declare 'MapStringListDatasetsResponse',
    as HashRef[ListDatasetsResponse()];

declare 'DeleteDatasetRequest',
    as InstanceOf['Google::Cloud::Datalabeling::V1beta1::DataLabelingService::DeleteDatasetRequest'];

coerce 'DeleteDatasetRequest',
    from HashRef, via { 'Google::Cloud::Datalabeling::V1beta1::DataLabelingService::DeleteDatasetRequest'->new($_) };

declare 'RepeatedDeleteDatasetRequest',
    as ArrayRef[DeleteDatasetRequest()];

coerce 'RepeatedDeleteDatasetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datalabeling::V1beta1::DataLabelingService::DeleteDatasetRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteDatasetRequest',
    as HashRef[DeleteDatasetRequest()];

declare 'ImportDataRequest',
    as InstanceOf['Google::Cloud::Datalabeling::V1beta1::DataLabelingService::ImportDataRequest'];

coerce 'ImportDataRequest',
    from HashRef, via { 'Google::Cloud::Datalabeling::V1beta1::DataLabelingService::ImportDataRequest'->new($_) };

declare 'RepeatedImportDataRequest',
    as ArrayRef[ImportDataRequest()];

coerce 'RepeatedImportDataRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datalabeling::V1beta1::DataLabelingService::ImportDataRequest'->new($_) } @$_ ] };

declare 'MapStringImportDataRequest',
    as HashRef[ImportDataRequest()];

declare 'ExportDataRequest',
    as InstanceOf['Google::Cloud::Datalabeling::V1beta1::DataLabelingService::ExportDataRequest'];

coerce 'ExportDataRequest',
    from HashRef, via { 'Google::Cloud::Datalabeling::V1beta1::DataLabelingService::ExportDataRequest'->new($_) };

declare 'RepeatedExportDataRequest',
    as ArrayRef[ExportDataRequest()];

coerce 'RepeatedExportDataRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datalabeling::V1beta1::DataLabelingService::ExportDataRequest'->new($_) } @$_ ] };

declare 'MapStringExportDataRequest',
    as HashRef[ExportDataRequest()];

declare 'GetDataItemRequest',
    as InstanceOf['Google::Cloud::Datalabeling::V1beta1::DataLabelingService::GetDataItemRequest'];

coerce 'GetDataItemRequest',
    from HashRef, via { 'Google::Cloud::Datalabeling::V1beta1::DataLabelingService::GetDataItemRequest'->new($_) };

declare 'RepeatedGetDataItemRequest',
    as ArrayRef[GetDataItemRequest()];

coerce 'RepeatedGetDataItemRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datalabeling::V1beta1::DataLabelingService::GetDataItemRequest'->new($_) } @$_ ] };

declare 'MapStringGetDataItemRequest',
    as HashRef[GetDataItemRequest()];

declare 'ListDataItemsRequest',
    as InstanceOf['Google::Cloud::Datalabeling::V1beta1::DataLabelingService::ListDataItemsRequest'];

coerce 'ListDataItemsRequest',
    from HashRef, via { 'Google::Cloud::Datalabeling::V1beta1::DataLabelingService::ListDataItemsRequest'->new($_) };

declare 'RepeatedListDataItemsRequest',
    as ArrayRef[ListDataItemsRequest()];

coerce 'RepeatedListDataItemsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datalabeling::V1beta1::DataLabelingService::ListDataItemsRequest'->new($_) } @$_ ] };

declare 'MapStringListDataItemsRequest',
    as HashRef[ListDataItemsRequest()];

declare 'ListDataItemsResponse',
    as InstanceOf['Google::Cloud::Datalabeling::V1beta1::DataLabelingService::ListDataItemsResponse'];

coerce 'ListDataItemsResponse',
    from HashRef, via { 'Google::Cloud::Datalabeling::V1beta1::DataLabelingService::ListDataItemsResponse'->new($_) };

declare 'RepeatedListDataItemsResponse',
    as ArrayRef[ListDataItemsResponse()];

coerce 'RepeatedListDataItemsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datalabeling::V1beta1::DataLabelingService::ListDataItemsResponse'->new($_) } @$_ ] };

declare 'MapStringListDataItemsResponse',
    as HashRef[ListDataItemsResponse()];

declare 'GetAnnotatedDatasetRequest',
    as InstanceOf['Google::Cloud::Datalabeling::V1beta1::DataLabelingService::GetAnnotatedDatasetRequest'];

coerce 'GetAnnotatedDatasetRequest',
    from HashRef, via { 'Google::Cloud::Datalabeling::V1beta1::DataLabelingService::GetAnnotatedDatasetRequest'->new($_) };

declare 'RepeatedGetAnnotatedDatasetRequest',
    as ArrayRef[GetAnnotatedDatasetRequest()];

coerce 'RepeatedGetAnnotatedDatasetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datalabeling::V1beta1::DataLabelingService::GetAnnotatedDatasetRequest'->new($_) } @$_ ] };

declare 'MapStringGetAnnotatedDatasetRequest',
    as HashRef[GetAnnotatedDatasetRequest()];

declare 'ListAnnotatedDatasetsRequest',
    as InstanceOf['Google::Cloud::Datalabeling::V1beta1::DataLabelingService::ListAnnotatedDatasetsRequest'];

coerce 'ListAnnotatedDatasetsRequest',
    from HashRef, via { 'Google::Cloud::Datalabeling::V1beta1::DataLabelingService::ListAnnotatedDatasetsRequest'->new($_) };

declare 'RepeatedListAnnotatedDatasetsRequest',
    as ArrayRef[ListAnnotatedDatasetsRequest()];

coerce 'RepeatedListAnnotatedDatasetsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datalabeling::V1beta1::DataLabelingService::ListAnnotatedDatasetsRequest'->new($_) } @$_ ] };

declare 'MapStringListAnnotatedDatasetsRequest',
    as HashRef[ListAnnotatedDatasetsRequest()];

declare 'ListAnnotatedDatasetsResponse',
    as InstanceOf['Google::Cloud::Datalabeling::V1beta1::DataLabelingService::ListAnnotatedDatasetsResponse'];

coerce 'ListAnnotatedDatasetsResponse',
    from HashRef, via { 'Google::Cloud::Datalabeling::V1beta1::DataLabelingService::ListAnnotatedDatasetsResponse'->new($_) };

declare 'RepeatedListAnnotatedDatasetsResponse',
    as ArrayRef[ListAnnotatedDatasetsResponse()];

coerce 'RepeatedListAnnotatedDatasetsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datalabeling::V1beta1::DataLabelingService::ListAnnotatedDatasetsResponse'->new($_) } @$_ ] };

declare 'MapStringListAnnotatedDatasetsResponse',
    as HashRef[ListAnnotatedDatasetsResponse()];

declare 'DeleteAnnotatedDatasetRequest',
    as InstanceOf['Google::Cloud::Datalabeling::V1beta1::DataLabelingService::DeleteAnnotatedDatasetRequest'];

coerce 'DeleteAnnotatedDatasetRequest',
    from HashRef, via { 'Google::Cloud::Datalabeling::V1beta1::DataLabelingService::DeleteAnnotatedDatasetRequest'->new($_) };

declare 'RepeatedDeleteAnnotatedDatasetRequest',
    as ArrayRef[DeleteAnnotatedDatasetRequest()];

coerce 'RepeatedDeleteAnnotatedDatasetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datalabeling::V1beta1::DataLabelingService::DeleteAnnotatedDatasetRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteAnnotatedDatasetRequest',
    as HashRef[DeleteAnnotatedDatasetRequest()];

declare 'LabelImageRequest',
    as InstanceOf['Google::Cloud::Datalabeling::V1beta1::DataLabelingService::LabelImageRequest'];

coerce 'LabelImageRequest',
    from HashRef, via { 'Google::Cloud::Datalabeling::V1beta1::DataLabelingService::LabelImageRequest'->new($_) };

declare 'RepeatedLabelImageRequest',
    as ArrayRef[LabelImageRequest()];

coerce 'RepeatedLabelImageRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datalabeling::V1beta1::DataLabelingService::LabelImageRequest'->new($_) } @$_ ] };

declare 'MapStringLabelImageRequest',
    as HashRef[LabelImageRequest()];

declare 'Feature',
    as (Int | Str);

declare 'LabelVideoRequest',
    as InstanceOf['Google::Cloud::Datalabeling::V1beta1::DataLabelingService::LabelVideoRequest'];

coerce 'LabelVideoRequest',
    from HashRef, via { 'Google::Cloud::Datalabeling::V1beta1::DataLabelingService::LabelVideoRequest'->new($_) };

declare 'RepeatedLabelVideoRequest',
    as ArrayRef[LabelVideoRequest()];

coerce 'RepeatedLabelVideoRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datalabeling::V1beta1::DataLabelingService::LabelVideoRequest'->new($_) } @$_ ] };

declare 'MapStringLabelVideoRequest',
    as HashRef[LabelVideoRequest()];

declare 'Feature',
    as (Int | Str);

declare 'LabelTextRequest',
    as InstanceOf['Google::Cloud::Datalabeling::V1beta1::DataLabelingService::LabelTextRequest'];

coerce 'LabelTextRequest',
    from HashRef, via { 'Google::Cloud::Datalabeling::V1beta1::DataLabelingService::LabelTextRequest'->new($_) };

declare 'RepeatedLabelTextRequest',
    as ArrayRef[LabelTextRequest()];

coerce 'RepeatedLabelTextRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datalabeling::V1beta1::DataLabelingService::LabelTextRequest'->new($_) } @$_ ] };

declare 'MapStringLabelTextRequest',
    as HashRef[LabelTextRequest()];

declare 'Feature',
    as (Int | Str);

declare 'GetExampleRequest',
    as InstanceOf['Google::Cloud::Datalabeling::V1beta1::DataLabelingService::GetExampleRequest'];

coerce 'GetExampleRequest',
    from HashRef, via { 'Google::Cloud::Datalabeling::V1beta1::DataLabelingService::GetExampleRequest'->new($_) };

declare 'RepeatedGetExampleRequest',
    as ArrayRef[GetExampleRequest()];

coerce 'RepeatedGetExampleRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datalabeling::V1beta1::DataLabelingService::GetExampleRequest'->new($_) } @$_ ] };

declare 'MapStringGetExampleRequest',
    as HashRef[GetExampleRequest()];

declare 'ListExamplesRequest',
    as InstanceOf['Google::Cloud::Datalabeling::V1beta1::DataLabelingService::ListExamplesRequest'];

coerce 'ListExamplesRequest',
    from HashRef, via { 'Google::Cloud::Datalabeling::V1beta1::DataLabelingService::ListExamplesRequest'->new($_) };

declare 'RepeatedListExamplesRequest',
    as ArrayRef[ListExamplesRequest()];

coerce 'RepeatedListExamplesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datalabeling::V1beta1::DataLabelingService::ListExamplesRequest'->new($_) } @$_ ] };

declare 'MapStringListExamplesRequest',
    as HashRef[ListExamplesRequest()];

declare 'ListExamplesResponse',
    as InstanceOf['Google::Cloud::Datalabeling::V1beta1::DataLabelingService::ListExamplesResponse'];

coerce 'ListExamplesResponse',
    from HashRef, via { 'Google::Cloud::Datalabeling::V1beta1::DataLabelingService::ListExamplesResponse'->new($_) };

declare 'RepeatedListExamplesResponse',
    as ArrayRef[ListExamplesResponse()];

coerce 'RepeatedListExamplesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datalabeling::V1beta1::DataLabelingService::ListExamplesResponse'->new($_) } @$_ ] };

declare 'MapStringListExamplesResponse',
    as HashRef[ListExamplesResponse()];

declare 'CreateAnnotationSpecSetRequest',
    as InstanceOf['Google::Cloud::Datalabeling::V1beta1::DataLabelingService::CreateAnnotationSpecSetRequest'];

coerce 'CreateAnnotationSpecSetRequest',
    from HashRef, via { 'Google::Cloud::Datalabeling::V1beta1::DataLabelingService::CreateAnnotationSpecSetRequest'->new($_) };

declare 'RepeatedCreateAnnotationSpecSetRequest',
    as ArrayRef[CreateAnnotationSpecSetRequest()];

coerce 'RepeatedCreateAnnotationSpecSetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datalabeling::V1beta1::DataLabelingService::CreateAnnotationSpecSetRequest'->new($_) } @$_ ] };

declare 'MapStringCreateAnnotationSpecSetRequest',
    as HashRef[CreateAnnotationSpecSetRequest()];

declare 'GetAnnotationSpecSetRequest',
    as InstanceOf['Google::Cloud::Datalabeling::V1beta1::DataLabelingService::GetAnnotationSpecSetRequest'];

coerce 'GetAnnotationSpecSetRequest',
    from HashRef, via { 'Google::Cloud::Datalabeling::V1beta1::DataLabelingService::GetAnnotationSpecSetRequest'->new($_) };

declare 'RepeatedGetAnnotationSpecSetRequest',
    as ArrayRef[GetAnnotationSpecSetRequest()];

coerce 'RepeatedGetAnnotationSpecSetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datalabeling::V1beta1::DataLabelingService::GetAnnotationSpecSetRequest'->new($_) } @$_ ] };

declare 'MapStringGetAnnotationSpecSetRequest',
    as HashRef[GetAnnotationSpecSetRequest()];

declare 'ListAnnotationSpecSetsRequest',
    as InstanceOf['Google::Cloud::Datalabeling::V1beta1::DataLabelingService::ListAnnotationSpecSetsRequest'];

coerce 'ListAnnotationSpecSetsRequest',
    from HashRef, via { 'Google::Cloud::Datalabeling::V1beta1::DataLabelingService::ListAnnotationSpecSetsRequest'->new($_) };

declare 'RepeatedListAnnotationSpecSetsRequest',
    as ArrayRef[ListAnnotationSpecSetsRequest()];

coerce 'RepeatedListAnnotationSpecSetsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datalabeling::V1beta1::DataLabelingService::ListAnnotationSpecSetsRequest'->new($_) } @$_ ] };

declare 'MapStringListAnnotationSpecSetsRequest',
    as HashRef[ListAnnotationSpecSetsRequest()];

declare 'ListAnnotationSpecSetsResponse',
    as InstanceOf['Google::Cloud::Datalabeling::V1beta1::DataLabelingService::ListAnnotationSpecSetsResponse'];

coerce 'ListAnnotationSpecSetsResponse',
    from HashRef, via { 'Google::Cloud::Datalabeling::V1beta1::DataLabelingService::ListAnnotationSpecSetsResponse'->new($_) };

declare 'RepeatedListAnnotationSpecSetsResponse',
    as ArrayRef[ListAnnotationSpecSetsResponse()];

coerce 'RepeatedListAnnotationSpecSetsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datalabeling::V1beta1::DataLabelingService::ListAnnotationSpecSetsResponse'->new($_) } @$_ ] };

declare 'MapStringListAnnotationSpecSetsResponse',
    as HashRef[ListAnnotationSpecSetsResponse()];

declare 'DeleteAnnotationSpecSetRequest',
    as InstanceOf['Google::Cloud::Datalabeling::V1beta1::DataLabelingService::DeleteAnnotationSpecSetRequest'];

coerce 'DeleteAnnotationSpecSetRequest',
    from HashRef, via { 'Google::Cloud::Datalabeling::V1beta1::DataLabelingService::DeleteAnnotationSpecSetRequest'->new($_) };

declare 'RepeatedDeleteAnnotationSpecSetRequest',
    as ArrayRef[DeleteAnnotationSpecSetRequest()];

coerce 'RepeatedDeleteAnnotationSpecSetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datalabeling::V1beta1::DataLabelingService::DeleteAnnotationSpecSetRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteAnnotationSpecSetRequest',
    as HashRef[DeleteAnnotationSpecSetRequest()];

declare 'CreateInstructionRequest',
    as InstanceOf['Google::Cloud::Datalabeling::V1beta1::DataLabelingService::CreateInstructionRequest'];

coerce 'CreateInstructionRequest',
    from HashRef, via { 'Google::Cloud::Datalabeling::V1beta1::DataLabelingService::CreateInstructionRequest'->new($_) };

declare 'RepeatedCreateInstructionRequest',
    as ArrayRef[CreateInstructionRequest()];

coerce 'RepeatedCreateInstructionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datalabeling::V1beta1::DataLabelingService::CreateInstructionRequest'->new($_) } @$_ ] };

declare 'MapStringCreateInstructionRequest',
    as HashRef[CreateInstructionRequest()];

declare 'GetInstructionRequest',
    as InstanceOf['Google::Cloud::Datalabeling::V1beta1::DataLabelingService::GetInstructionRequest'];

coerce 'GetInstructionRequest',
    from HashRef, via { 'Google::Cloud::Datalabeling::V1beta1::DataLabelingService::GetInstructionRequest'->new($_) };

declare 'RepeatedGetInstructionRequest',
    as ArrayRef[GetInstructionRequest()];

coerce 'RepeatedGetInstructionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datalabeling::V1beta1::DataLabelingService::GetInstructionRequest'->new($_) } @$_ ] };

declare 'MapStringGetInstructionRequest',
    as HashRef[GetInstructionRequest()];

declare 'DeleteInstructionRequest',
    as InstanceOf['Google::Cloud::Datalabeling::V1beta1::DataLabelingService::DeleteInstructionRequest'];

coerce 'DeleteInstructionRequest',
    from HashRef, via { 'Google::Cloud::Datalabeling::V1beta1::DataLabelingService::DeleteInstructionRequest'->new($_) };

declare 'RepeatedDeleteInstructionRequest',
    as ArrayRef[DeleteInstructionRequest()];

coerce 'RepeatedDeleteInstructionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datalabeling::V1beta1::DataLabelingService::DeleteInstructionRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteInstructionRequest',
    as HashRef[DeleteInstructionRequest()];

declare 'ListInstructionsRequest',
    as InstanceOf['Google::Cloud::Datalabeling::V1beta1::DataLabelingService::ListInstructionsRequest'];

coerce 'ListInstructionsRequest',
    from HashRef, via { 'Google::Cloud::Datalabeling::V1beta1::DataLabelingService::ListInstructionsRequest'->new($_) };

declare 'RepeatedListInstructionsRequest',
    as ArrayRef[ListInstructionsRequest()];

coerce 'RepeatedListInstructionsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datalabeling::V1beta1::DataLabelingService::ListInstructionsRequest'->new($_) } @$_ ] };

declare 'MapStringListInstructionsRequest',
    as HashRef[ListInstructionsRequest()];

declare 'ListInstructionsResponse',
    as InstanceOf['Google::Cloud::Datalabeling::V1beta1::DataLabelingService::ListInstructionsResponse'];

coerce 'ListInstructionsResponse',
    from HashRef, via { 'Google::Cloud::Datalabeling::V1beta1::DataLabelingService::ListInstructionsResponse'->new($_) };

declare 'RepeatedListInstructionsResponse',
    as ArrayRef[ListInstructionsResponse()];

coerce 'RepeatedListInstructionsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datalabeling::V1beta1::DataLabelingService::ListInstructionsResponse'->new($_) } @$_ ] };

declare 'MapStringListInstructionsResponse',
    as HashRef[ListInstructionsResponse()];

declare 'GetEvaluationRequest',
    as InstanceOf['Google::Cloud::Datalabeling::V1beta1::DataLabelingService::GetEvaluationRequest'];

coerce 'GetEvaluationRequest',
    from HashRef, via { 'Google::Cloud::Datalabeling::V1beta1::DataLabelingService::GetEvaluationRequest'->new($_) };

declare 'RepeatedGetEvaluationRequest',
    as ArrayRef[GetEvaluationRequest()];

coerce 'RepeatedGetEvaluationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datalabeling::V1beta1::DataLabelingService::GetEvaluationRequest'->new($_) } @$_ ] };

declare 'MapStringGetEvaluationRequest',
    as HashRef[GetEvaluationRequest()];

declare 'SearchEvaluationsRequest',
    as InstanceOf['Google::Cloud::Datalabeling::V1beta1::DataLabelingService::SearchEvaluationsRequest'];

coerce 'SearchEvaluationsRequest',
    from HashRef, via { 'Google::Cloud::Datalabeling::V1beta1::DataLabelingService::SearchEvaluationsRequest'->new($_) };

declare 'RepeatedSearchEvaluationsRequest',
    as ArrayRef[SearchEvaluationsRequest()];

coerce 'RepeatedSearchEvaluationsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datalabeling::V1beta1::DataLabelingService::SearchEvaluationsRequest'->new($_) } @$_ ] };

declare 'MapStringSearchEvaluationsRequest',
    as HashRef[SearchEvaluationsRequest()];

declare 'SearchEvaluationsResponse',
    as InstanceOf['Google::Cloud::Datalabeling::V1beta1::DataLabelingService::SearchEvaluationsResponse'];

coerce 'SearchEvaluationsResponse',
    from HashRef, via { 'Google::Cloud::Datalabeling::V1beta1::DataLabelingService::SearchEvaluationsResponse'->new($_) };

declare 'RepeatedSearchEvaluationsResponse',
    as ArrayRef[SearchEvaluationsResponse()];

coerce 'RepeatedSearchEvaluationsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datalabeling::V1beta1::DataLabelingService::SearchEvaluationsResponse'->new($_) } @$_ ] };

declare 'MapStringSearchEvaluationsResponse',
    as HashRef[SearchEvaluationsResponse()];

declare 'SearchExampleComparisonsRequest',
    as InstanceOf['Google::Cloud::Datalabeling::V1beta1::DataLabelingService::SearchExampleComparisonsRequest'];

coerce 'SearchExampleComparisonsRequest',
    from HashRef, via { 'Google::Cloud::Datalabeling::V1beta1::DataLabelingService::SearchExampleComparisonsRequest'->new($_) };

declare 'RepeatedSearchExampleComparisonsRequest',
    as ArrayRef[SearchExampleComparisonsRequest()];

coerce 'RepeatedSearchExampleComparisonsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datalabeling::V1beta1::DataLabelingService::SearchExampleComparisonsRequest'->new($_) } @$_ ] };

declare 'MapStringSearchExampleComparisonsRequest',
    as HashRef[SearchExampleComparisonsRequest()];

declare 'SearchExampleComparisonsResponse',
    as InstanceOf['Google::Cloud::Datalabeling::V1beta1::DataLabelingService::SearchExampleComparisonsResponse'];

coerce 'SearchExampleComparisonsResponse',
    from HashRef, via { 'Google::Cloud::Datalabeling::V1beta1::DataLabelingService::SearchExampleComparisonsResponse'->new($_) };

declare 'RepeatedSearchExampleComparisonsResponse',
    as ArrayRef[SearchExampleComparisonsResponse()];

coerce 'RepeatedSearchExampleComparisonsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datalabeling::V1beta1::DataLabelingService::SearchExampleComparisonsResponse'->new($_) } @$_ ] };

declare 'MapStringSearchExampleComparisonsResponse',
    as HashRef[SearchExampleComparisonsResponse()];

declare 'ExampleComparison',
    as InstanceOf['Google::Cloud::Datalabeling::V1beta1::DataLabelingService::SearchExampleComparisonsResponse::ExampleComparison'];

coerce 'ExampleComparison',
    from HashRef, via { 'Google::Cloud::Datalabeling::V1beta1::DataLabelingService::SearchExampleComparisonsResponse::ExampleComparison'->new($_) };

declare 'RepeatedExampleComparison',
    as ArrayRef[ExampleComparison()];

coerce 'RepeatedExampleComparison',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datalabeling::V1beta1::DataLabelingService::SearchExampleComparisonsResponse::ExampleComparison'->new($_) } @$_ ] };

declare 'MapStringExampleComparison',
    as HashRef[ExampleComparison()];

declare 'CreateEvaluationJobRequest',
    as InstanceOf['Google::Cloud::Datalabeling::V1beta1::DataLabelingService::CreateEvaluationJobRequest'];

coerce 'CreateEvaluationJobRequest',
    from HashRef, via { 'Google::Cloud::Datalabeling::V1beta1::DataLabelingService::CreateEvaluationJobRequest'->new($_) };

declare 'RepeatedCreateEvaluationJobRequest',
    as ArrayRef[CreateEvaluationJobRequest()];

coerce 'RepeatedCreateEvaluationJobRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datalabeling::V1beta1::DataLabelingService::CreateEvaluationJobRequest'->new($_) } @$_ ] };

declare 'MapStringCreateEvaluationJobRequest',
    as HashRef[CreateEvaluationJobRequest()];

declare 'UpdateEvaluationJobRequest',
    as InstanceOf['Google::Cloud::Datalabeling::V1beta1::DataLabelingService::UpdateEvaluationJobRequest'];

coerce 'UpdateEvaluationJobRequest',
    from HashRef, via { 'Google::Cloud::Datalabeling::V1beta1::DataLabelingService::UpdateEvaluationJobRequest'->new($_) };

declare 'RepeatedUpdateEvaluationJobRequest',
    as ArrayRef[UpdateEvaluationJobRequest()];

coerce 'RepeatedUpdateEvaluationJobRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datalabeling::V1beta1::DataLabelingService::UpdateEvaluationJobRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateEvaluationJobRequest',
    as HashRef[UpdateEvaluationJobRequest()];

declare 'GetEvaluationJobRequest',
    as InstanceOf['Google::Cloud::Datalabeling::V1beta1::DataLabelingService::GetEvaluationJobRequest'];

coerce 'GetEvaluationJobRequest',
    from HashRef, via { 'Google::Cloud::Datalabeling::V1beta1::DataLabelingService::GetEvaluationJobRequest'->new($_) };

declare 'RepeatedGetEvaluationJobRequest',
    as ArrayRef[GetEvaluationJobRequest()];

coerce 'RepeatedGetEvaluationJobRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datalabeling::V1beta1::DataLabelingService::GetEvaluationJobRequest'->new($_) } @$_ ] };

declare 'MapStringGetEvaluationJobRequest',
    as HashRef[GetEvaluationJobRequest()];

declare 'PauseEvaluationJobRequest',
    as InstanceOf['Google::Cloud::Datalabeling::V1beta1::DataLabelingService::PauseEvaluationJobRequest'];

coerce 'PauseEvaluationJobRequest',
    from HashRef, via { 'Google::Cloud::Datalabeling::V1beta1::DataLabelingService::PauseEvaluationJobRequest'->new($_) };

declare 'RepeatedPauseEvaluationJobRequest',
    as ArrayRef[PauseEvaluationJobRequest()];

coerce 'RepeatedPauseEvaluationJobRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datalabeling::V1beta1::DataLabelingService::PauseEvaluationJobRequest'->new($_) } @$_ ] };

declare 'MapStringPauseEvaluationJobRequest',
    as HashRef[PauseEvaluationJobRequest()];

declare 'ResumeEvaluationJobRequest',
    as InstanceOf['Google::Cloud::Datalabeling::V1beta1::DataLabelingService::ResumeEvaluationJobRequest'];

coerce 'ResumeEvaluationJobRequest',
    from HashRef, via { 'Google::Cloud::Datalabeling::V1beta1::DataLabelingService::ResumeEvaluationJobRequest'->new($_) };

declare 'RepeatedResumeEvaluationJobRequest',
    as ArrayRef[ResumeEvaluationJobRequest()];

coerce 'RepeatedResumeEvaluationJobRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datalabeling::V1beta1::DataLabelingService::ResumeEvaluationJobRequest'->new($_) } @$_ ] };

declare 'MapStringResumeEvaluationJobRequest',
    as HashRef[ResumeEvaluationJobRequest()];

declare 'DeleteEvaluationJobRequest',
    as InstanceOf['Google::Cloud::Datalabeling::V1beta1::DataLabelingService::DeleteEvaluationJobRequest'];

coerce 'DeleteEvaluationJobRequest',
    from HashRef, via { 'Google::Cloud::Datalabeling::V1beta1::DataLabelingService::DeleteEvaluationJobRequest'->new($_) };

declare 'RepeatedDeleteEvaluationJobRequest',
    as ArrayRef[DeleteEvaluationJobRequest()];

coerce 'RepeatedDeleteEvaluationJobRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datalabeling::V1beta1::DataLabelingService::DeleteEvaluationJobRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteEvaluationJobRequest',
    as HashRef[DeleteEvaluationJobRequest()];

declare 'ListEvaluationJobsRequest',
    as InstanceOf['Google::Cloud::Datalabeling::V1beta1::DataLabelingService::ListEvaluationJobsRequest'];

coerce 'ListEvaluationJobsRequest',
    from HashRef, via { 'Google::Cloud::Datalabeling::V1beta1::DataLabelingService::ListEvaluationJobsRequest'->new($_) };

declare 'RepeatedListEvaluationJobsRequest',
    as ArrayRef[ListEvaluationJobsRequest()];

coerce 'RepeatedListEvaluationJobsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datalabeling::V1beta1::DataLabelingService::ListEvaluationJobsRequest'->new($_) } @$_ ] };

declare 'MapStringListEvaluationJobsRequest',
    as HashRef[ListEvaluationJobsRequest()];

declare 'ListEvaluationJobsResponse',
    as InstanceOf['Google::Cloud::Datalabeling::V1beta1::DataLabelingService::ListEvaluationJobsResponse'];

coerce 'ListEvaluationJobsResponse',
    from HashRef, via { 'Google::Cloud::Datalabeling::V1beta1::DataLabelingService::ListEvaluationJobsResponse'->new($_) };

declare 'RepeatedListEvaluationJobsResponse',
    as ArrayRef[ListEvaluationJobsResponse()];

coerce 'RepeatedListEvaluationJobsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datalabeling::V1beta1::DataLabelingService::ListEvaluationJobsResponse'->new($_) } @$_ ] };

declare 'MapStringListEvaluationJobsResponse',
    as HashRef[ListEvaluationJobsResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Datalabeling::V1beta1::DataLabelingService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
