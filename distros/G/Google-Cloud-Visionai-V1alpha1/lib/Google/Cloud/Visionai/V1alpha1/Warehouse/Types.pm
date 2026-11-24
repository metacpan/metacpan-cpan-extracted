package Google::Cloud::Visionai::V1alpha1::Warehouse::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'FacetBucketType',
    as (Int | Str);

declare 'CreateAssetRequest',
    as InstanceOf['Google::Cloud::Visionai::V1alpha1::Warehouse::CreateAssetRequest'];

coerce 'CreateAssetRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1alpha1::Warehouse::CreateAssetRequest'->new($_) };

declare 'RepeatedCreateAssetRequest',
    as ArrayRef[CreateAssetRequest()];

coerce 'RepeatedCreateAssetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1alpha1::Warehouse::CreateAssetRequest'->new($_) } @$_ ] };

declare 'MapStringCreateAssetRequest',
    as HashRef[CreateAssetRequest()];

declare 'GetAssetRequest',
    as InstanceOf['Google::Cloud::Visionai::V1alpha1::Warehouse::GetAssetRequest'];

coerce 'GetAssetRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1alpha1::Warehouse::GetAssetRequest'->new($_) };

declare 'RepeatedGetAssetRequest',
    as ArrayRef[GetAssetRequest()];

coerce 'RepeatedGetAssetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1alpha1::Warehouse::GetAssetRequest'->new($_) } @$_ ] };

declare 'MapStringGetAssetRequest',
    as HashRef[GetAssetRequest()];

declare 'ListAssetsRequest',
    as InstanceOf['Google::Cloud::Visionai::V1alpha1::Warehouse::ListAssetsRequest'];

coerce 'ListAssetsRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1alpha1::Warehouse::ListAssetsRequest'->new($_) };

declare 'RepeatedListAssetsRequest',
    as ArrayRef[ListAssetsRequest()];

coerce 'RepeatedListAssetsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1alpha1::Warehouse::ListAssetsRequest'->new($_) } @$_ ] };

declare 'MapStringListAssetsRequest',
    as HashRef[ListAssetsRequest()];

declare 'ListAssetsResponse',
    as InstanceOf['Google::Cloud::Visionai::V1alpha1::Warehouse::ListAssetsResponse'];

coerce 'ListAssetsResponse',
    from HashRef, via { 'Google::Cloud::Visionai::V1alpha1::Warehouse::ListAssetsResponse'->new($_) };

declare 'RepeatedListAssetsResponse',
    as ArrayRef[ListAssetsResponse()];

coerce 'RepeatedListAssetsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1alpha1::Warehouse::ListAssetsResponse'->new($_) } @$_ ] };

declare 'MapStringListAssetsResponse',
    as HashRef[ListAssetsResponse()];

declare 'UpdateAssetRequest',
    as InstanceOf['Google::Cloud::Visionai::V1alpha1::Warehouse::UpdateAssetRequest'];

coerce 'UpdateAssetRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1alpha1::Warehouse::UpdateAssetRequest'->new($_) };

declare 'RepeatedUpdateAssetRequest',
    as ArrayRef[UpdateAssetRequest()];

coerce 'RepeatedUpdateAssetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1alpha1::Warehouse::UpdateAssetRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateAssetRequest',
    as HashRef[UpdateAssetRequest()];

declare 'DeleteAssetRequest',
    as InstanceOf['Google::Cloud::Visionai::V1alpha1::Warehouse::DeleteAssetRequest'];

coerce 'DeleteAssetRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1alpha1::Warehouse::DeleteAssetRequest'->new($_) };

declare 'RepeatedDeleteAssetRequest',
    as ArrayRef[DeleteAssetRequest()];

coerce 'RepeatedDeleteAssetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1alpha1::Warehouse::DeleteAssetRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteAssetRequest',
    as HashRef[DeleteAssetRequest()];

declare 'Asset',
    as InstanceOf['Google::Cloud::Visionai::V1alpha1::Warehouse::Asset'];

coerce 'Asset',
    from HashRef, via { 'Google::Cloud::Visionai::V1alpha1::Warehouse::Asset'->new($_) };

declare 'RepeatedAsset',
    as ArrayRef[Asset()];

coerce 'RepeatedAsset',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1alpha1::Warehouse::Asset'->new($_) } @$_ ] };

declare 'MapStringAsset',
    as HashRef[Asset()];

declare 'CreateCorpusRequest',
    as InstanceOf['Google::Cloud::Visionai::V1alpha1::Warehouse::CreateCorpusRequest'];

coerce 'CreateCorpusRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1alpha1::Warehouse::CreateCorpusRequest'->new($_) };

declare 'RepeatedCreateCorpusRequest',
    as ArrayRef[CreateCorpusRequest()];

coerce 'RepeatedCreateCorpusRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1alpha1::Warehouse::CreateCorpusRequest'->new($_) } @$_ ] };

declare 'MapStringCreateCorpusRequest',
    as HashRef[CreateCorpusRequest()];

declare 'CreateCorpusMetadata',
    as InstanceOf['Google::Cloud::Visionai::V1alpha1::Warehouse::CreateCorpusMetadata'];

coerce 'CreateCorpusMetadata',
    from HashRef, via { 'Google::Cloud::Visionai::V1alpha1::Warehouse::CreateCorpusMetadata'->new($_) };

declare 'RepeatedCreateCorpusMetadata',
    as ArrayRef[CreateCorpusMetadata()];

coerce 'RepeatedCreateCorpusMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1alpha1::Warehouse::CreateCorpusMetadata'->new($_) } @$_ ] };

declare 'MapStringCreateCorpusMetadata',
    as HashRef[CreateCorpusMetadata()];

declare 'Corpus',
    as InstanceOf['Google::Cloud::Visionai::V1alpha1::Warehouse::Corpus'];

coerce 'Corpus',
    from HashRef, via { 'Google::Cloud::Visionai::V1alpha1::Warehouse::Corpus'->new($_) };

declare 'RepeatedCorpus',
    as ArrayRef[Corpus()];

coerce 'RepeatedCorpus',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1alpha1::Warehouse::Corpus'->new($_) } @$_ ] };

declare 'MapStringCorpus',
    as HashRef[Corpus()];

declare 'GetCorpusRequest',
    as InstanceOf['Google::Cloud::Visionai::V1alpha1::Warehouse::GetCorpusRequest'];

coerce 'GetCorpusRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1alpha1::Warehouse::GetCorpusRequest'->new($_) };

declare 'RepeatedGetCorpusRequest',
    as ArrayRef[GetCorpusRequest()];

coerce 'RepeatedGetCorpusRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1alpha1::Warehouse::GetCorpusRequest'->new($_) } @$_ ] };

declare 'MapStringGetCorpusRequest',
    as HashRef[GetCorpusRequest()];

declare 'UpdateCorpusRequest',
    as InstanceOf['Google::Cloud::Visionai::V1alpha1::Warehouse::UpdateCorpusRequest'];

coerce 'UpdateCorpusRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1alpha1::Warehouse::UpdateCorpusRequest'->new($_) };

declare 'RepeatedUpdateCorpusRequest',
    as ArrayRef[UpdateCorpusRequest()];

coerce 'RepeatedUpdateCorpusRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1alpha1::Warehouse::UpdateCorpusRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateCorpusRequest',
    as HashRef[UpdateCorpusRequest()];

declare 'ListCorporaRequest',
    as InstanceOf['Google::Cloud::Visionai::V1alpha1::Warehouse::ListCorporaRequest'];

coerce 'ListCorporaRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1alpha1::Warehouse::ListCorporaRequest'->new($_) };

declare 'RepeatedListCorporaRequest',
    as ArrayRef[ListCorporaRequest()];

coerce 'RepeatedListCorporaRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1alpha1::Warehouse::ListCorporaRequest'->new($_) } @$_ ] };

declare 'MapStringListCorporaRequest',
    as HashRef[ListCorporaRequest()];

declare 'ListCorporaResponse',
    as InstanceOf['Google::Cloud::Visionai::V1alpha1::Warehouse::ListCorporaResponse'];

coerce 'ListCorporaResponse',
    from HashRef, via { 'Google::Cloud::Visionai::V1alpha1::Warehouse::ListCorporaResponse'->new($_) };

declare 'RepeatedListCorporaResponse',
    as ArrayRef[ListCorporaResponse()];

coerce 'RepeatedListCorporaResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1alpha1::Warehouse::ListCorporaResponse'->new($_) } @$_ ] };

declare 'MapStringListCorporaResponse',
    as HashRef[ListCorporaResponse()];

declare 'DeleteCorpusRequest',
    as InstanceOf['Google::Cloud::Visionai::V1alpha1::Warehouse::DeleteCorpusRequest'];

coerce 'DeleteCorpusRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1alpha1::Warehouse::DeleteCorpusRequest'->new($_) };

declare 'RepeatedDeleteCorpusRequest',
    as ArrayRef[DeleteCorpusRequest()];

coerce 'RepeatedDeleteCorpusRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1alpha1::Warehouse::DeleteCorpusRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteCorpusRequest',
    as HashRef[DeleteCorpusRequest()];

declare 'CreateDataSchemaRequest',
    as InstanceOf['Google::Cloud::Visionai::V1alpha1::Warehouse::CreateDataSchemaRequest'];

coerce 'CreateDataSchemaRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1alpha1::Warehouse::CreateDataSchemaRequest'->new($_) };

declare 'RepeatedCreateDataSchemaRequest',
    as ArrayRef[CreateDataSchemaRequest()];

coerce 'RepeatedCreateDataSchemaRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1alpha1::Warehouse::CreateDataSchemaRequest'->new($_) } @$_ ] };

declare 'MapStringCreateDataSchemaRequest',
    as HashRef[CreateDataSchemaRequest()];

declare 'DataSchema',
    as InstanceOf['Google::Cloud::Visionai::V1alpha1::Warehouse::DataSchema'];

coerce 'DataSchema',
    from HashRef, via { 'Google::Cloud::Visionai::V1alpha1::Warehouse::DataSchema'->new($_) };

declare 'RepeatedDataSchema',
    as ArrayRef[DataSchema()];

coerce 'RepeatedDataSchema',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1alpha1::Warehouse::DataSchema'->new($_) } @$_ ] };

declare 'MapStringDataSchema',
    as HashRef[DataSchema()];

declare 'DataSchemaDetails',
    as InstanceOf['Google::Cloud::Visionai::V1alpha1::Warehouse::DataSchemaDetails'];

coerce 'DataSchemaDetails',
    from HashRef, via { 'Google::Cloud::Visionai::V1alpha1::Warehouse::DataSchemaDetails'->new($_) };

declare 'RepeatedDataSchemaDetails',
    as ArrayRef[DataSchemaDetails()];

coerce 'RepeatedDataSchemaDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1alpha1::Warehouse::DataSchemaDetails'->new($_) } @$_ ] };

declare 'MapStringDataSchemaDetails',
    as HashRef[DataSchemaDetails()];

declare 'DataType',
    as (Int | Str);

declare 'Granularity',
    as (Int | Str);

declare 'ProtoAnyConfig',
    as InstanceOf['Google::Cloud::Visionai::V1alpha1::Warehouse::DataSchemaDetails::ProtoAnyConfig'];

coerce 'ProtoAnyConfig',
    from HashRef, via { 'Google::Cloud::Visionai::V1alpha1::Warehouse::DataSchemaDetails::ProtoAnyConfig'->new($_) };

declare 'RepeatedProtoAnyConfig',
    as ArrayRef[ProtoAnyConfig()];

coerce 'RepeatedProtoAnyConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1alpha1::Warehouse::DataSchemaDetails::ProtoAnyConfig'->new($_) } @$_ ] };

declare 'MapStringProtoAnyConfig',
    as HashRef[ProtoAnyConfig()];

declare 'SearchStrategy',
    as InstanceOf['Google::Cloud::Visionai::V1alpha1::Warehouse::DataSchemaDetails::SearchStrategy'];

coerce 'SearchStrategy',
    from HashRef, via { 'Google::Cloud::Visionai::V1alpha1::Warehouse::DataSchemaDetails::SearchStrategy'->new($_) };

declare 'RepeatedSearchStrategy',
    as ArrayRef[SearchStrategy()];

coerce 'RepeatedSearchStrategy',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1alpha1::Warehouse::DataSchemaDetails::SearchStrategy'->new($_) } @$_ ] };

declare 'MapStringSearchStrategy',
    as HashRef[SearchStrategy()];

declare 'SearchStrategyType',
    as (Int | Str);

declare 'UpdateDataSchemaRequest',
    as InstanceOf['Google::Cloud::Visionai::V1alpha1::Warehouse::UpdateDataSchemaRequest'];

coerce 'UpdateDataSchemaRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1alpha1::Warehouse::UpdateDataSchemaRequest'->new($_) };

declare 'RepeatedUpdateDataSchemaRequest',
    as ArrayRef[UpdateDataSchemaRequest()];

coerce 'RepeatedUpdateDataSchemaRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1alpha1::Warehouse::UpdateDataSchemaRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateDataSchemaRequest',
    as HashRef[UpdateDataSchemaRequest()];

declare 'GetDataSchemaRequest',
    as InstanceOf['Google::Cloud::Visionai::V1alpha1::Warehouse::GetDataSchemaRequest'];

coerce 'GetDataSchemaRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1alpha1::Warehouse::GetDataSchemaRequest'->new($_) };

declare 'RepeatedGetDataSchemaRequest',
    as ArrayRef[GetDataSchemaRequest()];

coerce 'RepeatedGetDataSchemaRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1alpha1::Warehouse::GetDataSchemaRequest'->new($_) } @$_ ] };

declare 'MapStringGetDataSchemaRequest',
    as HashRef[GetDataSchemaRequest()];

declare 'DeleteDataSchemaRequest',
    as InstanceOf['Google::Cloud::Visionai::V1alpha1::Warehouse::DeleteDataSchemaRequest'];

coerce 'DeleteDataSchemaRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1alpha1::Warehouse::DeleteDataSchemaRequest'->new($_) };

declare 'RepeatedDeleteDataSchemaRequest',
    as ArrayRef[DeleteDataSchemaRequest()];

coerce 'RepeatedDeleteDataSchemaRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1alpha1::Warehouse::DeleteDataSchemaRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteDataSchemaRequest',
    as HashRef[DeleteDataSchemaRequest()];

declare 'ListDataSchemasRequest',
    as InstanceOf['Google::Cloud::Visionai::V1alpha1::Warehouse::ListDataSchemasRequest'];

coerce 'ListDataSchemasRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1alpha1::Warehouse::ListDataSchemasRequest'->new($_) };

declare 'RepeatedListDataSchemasRequest',
    as ArrayRef[ListDataSchemasRequest()];

coerce 'RepeatedListDataSchemasRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1alpha1::Warehouse::ListDataSchemasRequest'->new($_) } @$_ ] };

declare 'MapStringListDataSchemasRequest',
    as HashRef[ListDataSchemasRequest()];

declare 'ListDataSchemasResponse',
    as InstanceOf['Google::Cloud::Visionai::V1alpha1::Warehouse::ListDataSchemasResponse'];

coerce 'ListDataSchemasResponse',
    from HashRef, via { 'Google::Cloud::Visionai::V1alpha1::Warehouse::ListDataSchemasResponse'->new($_) };

declare 'RepeatedListDataSchemasResponse',
    as ArrayRef[ListDataSchemasResponse()];

coerce 'RepeatedListDataSchemasResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1alpha1::Warehouse::ListDataSchemasResponse'->new($_) } @$_ ] };

declare 'MapStringListDataSchemasResponse',
    as HashRef[ListDataSchemasResponse()];

declare 'CreateAnnotationRequest',
    as InstanceOf['Google::Cloud::Visionai::V1alpha1::Warehouse::CreateAnnotationRequest'];

coerce 'CreateAnnotationRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1alpha1::Warehouse::CreateAnnotationRequest'->new($_) };

declare 'RepeatedCreateAnnotationRequest',
    as ArrayRef[CreateAnnotationRequest()];

coerce 'RepeatedCreateAnnotationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1alpha1::Warehouse::CreateAnnotationRequest'->new($_) } @$_ ] };

declare 'MapStringCreateAnnotationRequest',
    as HashRef[CreateAnnotationRequest()];

declare 'Annotation',
    as InstanceOf['Google::Cloud::Visionai::V1alpha1::Warehouse::Annotation'];

coerce 'Annotation',
    from HashRef, via { 'Google::Cloud::Visionai::V1alpha1::Warehouse::Annotation'->new($_) };

declare 'RepeatedAnnotation',
    as ArrayRef[Annotation()];

coerce 'RepeatedAnnotation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1alpha1::Warehouse::Annotation'->new($_) } @$_ ] };

declare 'MapStringAnnotation',
    as HashRef[Annotation()];

declare 'UserSpecifiedAnnotation',
    as InstanceOf['Google::Cloud::Visionai::V1alpha1::Warehouse::UserSpecifiedAnnotation'];

coerce 'UserSpecifiedAnnotation',
    from HashRef, via { 'Google::Cloud::Visionai::V1alpha1::Warehouse::UserSpecifiedAnnotation'->new($_) };

declare 'RepeatedUserSpecifiedAnnotation',
    as ArrayRef[UserSpecifiedAnnotation()];

coerce 'RepeatedUserSpecifiedAnnotation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1alpha1::Warehouse::UserSpecifiedAnnotation'->new($_) } @$_ ] };

declare 'MapStringUserSpecifiedAnnotation',
    as HashRef[UserSpecifiedAnnotation()];

declare 'GeoCoordinate',
    as InstanceOf['Google::Cloud::Visionai::V1alpha1::Warehouse::GeoCoordinate'];

coerce 'GeoCoordinate',
    from HashRef, via { 'Google::Cloud::Visionai::V1alpha1::Warehouse::GeoCoordinate'->new($_) };

declare 'RepeatedGeoCoordinate',
    as ArrayRef[GeoCoordinate()];

coerce 'RepeatedGeoCoordinate',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1alpha1::Warehouse::GeoCoordinate'->new($_) } @$_ ] };

declare 'MapStringGeoCoordinate',
    as HashRef[GeoCoordinate()];

declare 'AnnotationValue',
    as InstanceOf['Google::Cloud::Visionai::V1alpha1::Warehouse::AnnotationValue'];

coerce 'AnnotationValue',
    from HashRef, via { 'Google::Cloud::Visionai::V1alpha1::Warehouse::AnnotationValue'->new($_) };

declare 'RepeatedAnnotationValue',
    as ArrayRef[AnnotationValue()];

coerce 'RepeatedAnnotationValue',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1alpha1::Warehouse::AnnotationValue'->new($_) } @$_ ] };

declare 'MapStringAnnotationValue',
    as HashRef[AnnotationValue()];

declare 'ListAnnotationsRequest',
    as InstanceOf['Google::Cloud::Visionai::V1alpha1::Warehouse::ListAnnotationsRequest'];

coerce 'ListAnnotationsRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1alpha1::Warehouse::ListAnnotationsRequest'->new($_) };

declare 'RepeatedListAnnotationsRequest',
    as ArrayRef[ListAnnotationsRequest()];

coerce 'RepeatedListAnnotationsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1alpha1::Warehouse::ListAnnotationsRequest'->new($_) } @$_ ] };

declare 'MapStringListAnnotationsRequest',
    as HashRef[ListAnnotationsRequest()];

declare 'ListAnnotationsResponse',
    as InstanceOf['Google::Cloud::Visionai::V1alpha1::Warehouse::ListAnnotationsResponse'];

coerce 'ListAnnotationsResponse',
    from HashRef, via { 'Google::Cloud::Visionai::V1alpha1::Warehouse::ListAnnotationsResponse'->new($_) };

declare 'RepeatedListAnnotationsResponse',
    as ArrayRef[ListAnnotationsResponse()];

coerce 'RepeatedListAnnotationsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1alpha1::Warehouse::ListAnnotationsResponse'->new($_) } @$_ ] };

declare 'MapStringListAnnotationsResponse',
    as HashRef[ListAnnotationsResponse()];

declare 'GetAnnotationRequest',
    as InstanceOf['Google::Cloud::Visionai::V1alpha1::Warehouse::GetAnnotationRequest'];

coerce 'GetAnnotationRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1alpha1::Warehouse::GetAnnotationRequest'->new($_) };

declare 'RepeatedGetAnnotationRequest',
    as ArrayRef[GetAnnotationRequest()];

coerce 'RepeatedGetAnnotationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1alpha1::Warehouse::GetAnnotationRequest'->new($_) } @$_ ] };

declare 'MapStringGetAnnotationRequest',
    as HashRef[GetAnnotationRequest()];

declare 'UpdateAnnotationRequest',
    as InstanceOf['Google::Cloud::Visionai::V1alpha1::Warehouse::UpdateAnnotationRequest'];

coerce 'UpdateAnnotationRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1alpha1::Warehouse::UpdateAnnotationRequest'->new($_) };

declare 'RepeatedUpdateAnnotationRequest',
    as ArrayRef[UpdateAnnotationRequest()];

coerce 'RepeatedUpdateAnnotationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1alpha1::Warehouse::UpdateAnnotationRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateAnnotationRequest',
    as HashRef[UpdateAnnotationRequest()];

declare 'DeleteAnnotationRequest',
    as InstanceOf['Google::Cloud::Visionai::V1alpha1::Warehouse::DeleteAnnotationRequest'];

coerce 'DeleteAnnotationRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1alpha1::Warehouse::DeleteAnnotationRequest'->new($_) };

declare 'RepeatedDeleteAnnotationRequest',
    as ArrayRef[DeleteAnnotationRequest()];

coerce 'RepeatedDeleteAnnotationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1alpha1::Warehouse::DeleteAnnotationRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteAnnotationRequest',
    as HashRef[DeleteAnnotationRequest()];

declare 'CreateSearchConfigRequest',
    as InstanceOf['Google::Cloud::Visionai::V1alpha1::Warehouse::CreateSearchConfigRequest'];

coerce 'CreateSearchConfigRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1alpha1::Warehouse::CreateSearchConfigRequest'->new($_) };

declare 'RepeatedCreateSearchConfigRequest',
    as ArrayRef[CreateSearchConfigRequest()];

coerce 'RepeatedCreateSearchConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1alpha1::Warehouse::CreateSearchConfigRequest'->new($_) } @$_ ] };

declare 'MapStringCreateSearchConfigRequest',
    as HashRef[CreateSearchConfigRequest()];

declare 'UpdateSearchConfigRequest',
    as InstanceOf['Google::Cloud::Visionai::V1alpha1::Warehouse::UpdateSearchConfigRequest'];

coerce 'UpdateSearchConfigRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1alpha1::Warehouse::UpdateSearchConfigRequest'->new($_) };

declare 'RepeatedUpdateSearchConfigRequest',
    as ArrayRef[UpdateSearchConfigRequest()];

coerce 'RepeatedUpdateSearchConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1alpha1::Warehouse::UpdateSearchConfigRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateSearchConfigRequest',
    as HashRef[UpdateSearchConfigRequest()];

declare 'GetSearchConfigRequest',
    as InstanceOf['Google::Cloud::Visionai::V1alpha1::Warehouse::GetSearchConfigRequest'];

coerce 'GetSearchConfigRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1alpha1::Warehouse::GetSearchConfigRequest'->new($_) };

declare 'RepeatedGetSearchConfigRequest',
    as ArrayRef[GetSearchConfigRequest()];

coerce 'RepeatedGetSearchConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1alpha1::Warehouse::GetSearchConfigRequest'->new($_) } @$_ ] };

declare 'MapStringGetSearchConfigRequest',
    as HashRef[GetSearchConfigRequest()];

declare 'DeleteSearchConfigRequest',
    as InstanceOf['Google::Cloud::Visionai::V1alpha1::Warehouse::DeleteSearchConfigRequest'];

coerce 'DeleteSearchConfigRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1alpha1::Warehouse::DeleteSearchConfigRequest'->new($_) };

declare 'RepeatedDeleteSearchConfigRequest',
    as ArrayRef[DeleteSearchConfigRequest()];

coerce 'RepeatedDeleteSearchConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1alpha1::Warehouse::DeleteSearchConfigRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteSearchConfigRequest',
    as HashRef[DeleteSearchConfigRequest()];

declare 'ListSearchConfigsRequest',
    as InstanceOf['Google::Cloud::Visionai::V1alpha1::Warehouse::ListSearchConfigsRequest'];

coerce 'ListSearchConfigsRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1alpha1::Warehouse::ListSearchConfigsRequest'->new($_) };

declare 'RepeatedListSearchConfigsRequest',
    as ArrayRef[ListSearchConfigsRequest()];

coerce 'RepeatedListSearchConfigsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1alpha1::Warehouse::ListSearchConfigsRequest'->new($_) } @$_ ] };

declare 'MapStringListSearchConfigsRequest',
    as HashRef[ListSearchConfigsRequest()];

declare 'ListSearchConfigsResponse',
    as InstanceOf['Google::Cloud::Visionai::V1alpha1::Warehouse::ListSearchConfigsResponse'];

coerce 'ListSearchConfigsResponse',
    from HashRef, via { 'Google::Cloud::Visionai::V1alpha1::Warehouse::ListSearchConfigsResponse'->new($_) };

declare 'RepeatedListSearchConfigsResponse',
    as ArrayRef[ListSearchConfigsResponse()];

coerce 'RepeatedListSearchConfigsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1alpha1::Warehouse::ListSearchConfigsResponse'->new($_) } @$_ ] };

declare 'MapStringListSearchConfigsResponse',
    as HashRef[ListSearchConfigsResponse()];

declare 'SearchConfig',
    as InstanceOf['Google::Cloud::Visionai::V1alpha1::Warehouse::SearchConfig'];

coerce 'SearchConfig',
    from HashRef, via { 'Google::Cloud::Visionai::V1alpha1::Warehouse::SearchConfig'->new($_) };

declare 'RepeatedSearchConfig',
    as ArrayRef[SearchConfig()];

coerce 'RepeatedSearchConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1alpha1::Warehouse::SearchConfig'->new($_) } @$_ ] };

declare 'MapStringSearchConfig',
    as HashRef[SearchConfig()];

declare 'FacetProperty',
    as InstanceOf['Google::Cloud::Visionai::V1alpha1::Warehouse::FacetProperty'];

coerce 'FacetProperty',
    from HashRef, via { 'Google::Cloud::Visionai::V1alpha1::Warehouse::FacetProperty'->new($_) };

declare 'RepeatedFacetProperty',
    as ArrayRef[FacetProperty()];

coerce 'RepeatedFacetProperty',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1alpha1::Warehouse::FacetProperty'->new($_) } @$_ ] };

declare 'MapStringFacetProperty',
    as HashRef[FacetProperty()];

declare 'FixedRangeBucketSpec',
    as InstanceOf['Google::Cloud::Visionai::V1alpha1::Warehouse::FacetProperty::FixedRangeBucketSpec'];

coerce 'FixedRangeBucketSpec',
    from HashRef, via { 'Google::Cloud::Visionai::V1alpha1::Warehouse::FacetProperty::FixedRangeBucketSpec'->new($_) };

declare 'RepeatedFixedRangeBucketSpec',
    as ArrayRef[FixedRangeBucketSpec()];

coerce 'RepeatedFixedRangeBucketSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1alpha1::Warehouse::FacetProperty::FixedRangeBucketSpec'->new($_) } @$_ ] };

declare 'MapStringFixedRangeBucketSpec',
    as HashRef[FixedRangeBucketSpec()];

declare 'CustomRangeBucketSpec',
    as InstanceOf['Google::Cloud::Visionai::V1alpha1::Warehouse::FacetProperty::CustomRangeBucketSpec'];

coerce 'CustomRangeBucketSpec',
    from HashRef, via { 'Google::Cloud::Visionai::V1alpha1::Warehouse::FacetProperty::CustomRangeBucketSpec'->new($_) };

declare 'RepeatedCustomRangeBucketSpec',
    as ArrayRef[CustomRangeBucketSpec()];

coerce 'RepeatedCustomRangeBucketSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1alpha1::Warehouse::FacetProperty::CustomRangeBucketSpec'->new($_) } @$_ ] };

declare 'MapStringCustomRangeBucketSpec',
    as HashRef[CustomRangeBucketSpec()];

declare 'DateTimeBucketSpec',
    as InstanceOf['Google::Cloud::Visionai::V1alpha1::Warehouse::FacetProperty::DateTimeBucketSpec'];

coerce 'DateTimeBucketSpec',
    from HashRef, via { 'Google::Cloud::Visionai::V1alpha1::Warehouse::FacetProperty::DateTimeBucketSpec'->new($_) };

declare 'RepeatedDateTimeBucketSpec',
    as ArrayRef[DateTimeBucketSpec()];

coerce 'RepeatedDateTimeBucketSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1alpha1::Warehouse::FacetProperty::DateTimeBucketSpec'->new($_) } @$_ ] };

declare 'MapStringDateTimeBucketSpec',
    as HashRef[DateTimeBucketSpec()];

declare 'Granularity',
    as (Int | Str);

declare 'SearchCriteriaProperty',
    as InstanceOf['Google::Cloud::Visionai::V1alpha1::Warehouse::SearchCriteriaProperty'];

coerce 'SearchCriteriaProperty',
    from HashRef, via { 'Google::Cloud::Visionai::V1alpha1::Warehouse::SearchCriteriaProperty'->new($_) };

declare 'RepeatedSearchCriteriaProperty',
    as ArrayRef[SearchCriteriaProperty()];

coerce 'RepeatedSearchCriteriaProperty',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1alpha1::Warehouse::SearchCriteriaProperty'->new($_) } @$_ ] };

declare 'MapStringSearchCriteriaProperty',
    as HashRef[SearchCriteriaProperty()];

declare 'FacetValue',
    as InstanceOf['Google::Cloud::Visionai::V1alpha1::Warehouse::FacetValue'];

coerce 'FacetValue',
    from HashRef, via { 'Google::Cloud::Visionai::V1alpha1::Warehouse::FacetValue'->new($_) };

declare 'RepeatedFacetValue',
    as ArrayRef[FacetValue()];

coerce 'RepeatedFacetValue',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1alpha1::Warehouse::FacetValue'->new($_) } @$_ ] };

declare 'MapStringFacetValue',
    as HashRef[FacetValue()];

declare 'FacetBucket',
    as InstanceOf['Google::Cloud::Visionai::V1alpha1::Warehouse::FacetBucket'];

coerce 'FacetBucket',
    from HashRef, via { 'Google::Cloud::Visionai::V1alpha1::Warehouse::FacetBucket'->new($_) };

declare 'RepeatedFacetBucket',
    as ArrayRef[FacetBucket()];

coerce 'RepeatedFacetBucket',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1alpha1::Warehouse::FacetBucket'->new($_) } @$_ ] };

declare 'MapStringFacetBucket',
    as HashRef[FacetBucket()];

declare 'Range',
    as InstanceOf['Google::Cloud::Visionai::V1alpha1::Warehouse::FacetBucket::Range'];

coerce 'Range',
    from HashRef, via { 'Google::Cloud::Visionai::V1alpha1::Warehouse::FacetBucket::Range'->new($_) };

declare 'RepeatedRange',
    as ArrayRef[Range()];

coerce 'RepeatedRange',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1alpha1::Warehouse::FacetBucket::Range'->new($_) } @$_ ] };

declare 'MapStringRange',
    as HashRef[Range()];

declare 'FacetGroup',
    as InstanceOf['Google::Cloud::Visionai::V1alpha1::Warehouse::FacetGroup'];

coerce 'FacetGroup',
    from HashRef, via { 'Google::Cloud::Visionai::V1alpha1::Warehouse::FacetGroup'->new($_) };

declare 'RepeatedFacetGroup',
    as ArrayRef[FacetGroup()];

coerce 'RepeatedFacetGroup',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1alpha1::Warehouse::FacetGroup'->new($_) } @$_ ] };

declare 'MapStringFacetGroup',
    as HashRef[FacetGroup()];

declare 'IngestAssetRequest',
    as InstanceOf['Google::Cloud::Visionai::V1alpha1::Warehouse::IngestAssetRequest'];

coerce 'IngestAssetRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1alpha1::Warehouse::IngestAssetRequest'->new($_) };

declare 'RepeatedIngestAssetRequest',
    as ArrayRef[IngestAssetRequest()];

coerce 'RepeatedIngestAssetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1alpha1::Warehouse::IngestAssetRequest'->new($_) } @$_ ] };

declare 'MapStringIngestAssetRequest',
    as HashRef[IngestAssetRequest()];

declare 'Config',
    as InstanceOf['Google::Cloud::Visionai::V1alpha1::Warehouse::IngestAssetRequest::Config'];

coerce 'Config',
    from HashRef, via { 'Google::Cloud::Visionai::V1alpha1::Warehouse::IngestAssetRequest::Config'->new($_) };

declare 'RepeatedConfig',
    as ArrayRef[Config()];

coerce 'RepeatedConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1alpha1::Warehouse::IngestAssetRequest::Config'->new($_) } @$_ ] };

declare 'MapStringConfig',
    as HashRef[Config()];

declare 'VideoType',
    as InstanceOf['Google::Cloud::Visionai::V1alpha1::Warehouse::IngestAssetRequest::Config::VideoType'];

coerce 'VideoType',
    from HashRef, via { 'Google::Cloud::Visionai::V1alpha1::Warehouse::IngestAssetRequest::Config::VideoType'->new($_) };

declare 'RepeatedVideoType',
    as ArrayRef[VideoType()];

coerce 'RepeatedVideoType',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1alpha1::Warehouse::IngestAssetRequest::Config::VideoType'->new($_) } @$_ ] };

declare 'MapStringVideoType',
    as HashRef[VideoType()];

declare 'ContainerFormat',
    as (Int | Str);

declare 'TimeIndexedData',
    as InstanceOf['Google::Cloud::Visionai::V1alpha1::Warehouse::IngestAssetRequest::TimeIndexedData'];

coerce 'TimeIndexedData',
    from HashRef, via { 'Google::Cloud::Visionai::V1alpha1::Warehouse::IngestAssetRequest::TimeIndexedData'->new($_) };

declare 'RepeatedTimeIndexedData',
    as ArrayRef[TimeIndexedData()];

coerce 'RepeatedTimeIndexedData',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1alpha1::Warehouse::IngestAssetRequest::TimeIndexedData'->new($_) } @$_ ] };

declare 'MapStringTimeIndexedData',
    as HashRef[TimeIndexedData()];

declare 'IngestAssetResponse',
    as InstanceOf['Google::Cloud::Visionai::V1alpha1::Warehouse::IngestAssetResponse'];

coerce 'IngestAssetResponse',
    from HashRef, via { 'Google::Cloud::Visionai::V1alpha1::Warehouse::IngestAssetResponse'->new($_) };

declare 'RepeatedIngestAssetResponse',
    as ArrayRef[IngestAssetResponse()];

coerce 'RepeatedIngestAssetResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1alpha1::Warehouse::IngestAssetResponse'->new($_) } @$_ ] };

declare 'MapStringIngestAssetResponse',
    as HashRef[IngestAssetResponse()];

declare 'ClipAssetRequest',
    as InstanceOf['Google::Cloud::Visionai::V1alpha1::Warehouse::ClipAssetRequest'];

coerce 'ClipAssetRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1alpha1::Warehouse::ClipAssetRequest'->new($_) };

declare 'RepeatedClipAssetRequest',
    as ArrayRef[ClipAssetRequest()];

coerce 'RepeatedClipAssetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1alpha1::Warehouse::ClipAssetRequest'->new($_) } @$_ ] };

declare 'MapStringClipAssetRequest',
    as HashRef[ClipAssetRequest()];

declare 'ClipAssetResponse',
    as InstanceOf['Google::Cloud::Visionai::V1alpha1::Warehouse::ClipAssetResponse'];

coerce 'ClipAssetResponse',
    from HashRef, via { 'Google::Cloud::Visionai::V1alpha1::Warehouse::ClipAssetResponse'->new($_) };

declare 'RepeatedClipAssetResponse',
    as ArrayRef[ClipAssetResponse()];

coerce 'RepeatedClipAssetResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1alpha1::Warehouse::ClipAssetResponse'->new($_) } @$_ ] };

declare 'MapStringClipAssetResponse',
    as HashRef[ClipAssetResponse()];

declare 'TimeIndexedUri',
    as InstanceOf['Google::Cloud::Visionai::V1alpha1::Warehouse::ClipAssetResponse::TimeIndexedUri'];

coerce 'TimeIndexedUri',
    from HashRef, via { 'Google::Cloud::Visionai::V1alpha1::Warehouse::ClipAssetResponse::TimeIndexedUri'->new($_) };

declare 'RepeatedTimeIndexedUri',
    as ArrayRef[TimeIndexedUri()];

coerce 'RepeatedTimeIndexedUri',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1alpha1::Warehouse::ClipAssetResponse::TimeIndexedUri'->new($_) } @$_ ] };

declare 'MapStringTimeIndexedUri',
    as HashRef[TimeIndexedUri()];

declare 'GenerateHlsUriRequest',
    as InstanceOf['Google::Cloud::Visionai::V1alpha1::Warehouse::GenerateHlsUriRequest'];

coerce 'GenerateHlsUriRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1alpha1::Warehouse::GenerateHlsUriRequest'->new($_) };

declare 'RepeatedGenerateHlsUriRequest',
    as ArrayRef[GenerateHlsUriRequest()];

coerce 'RepeatedGenerateHlsUriRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1alpha1::Warehouse::GenerateHlsUriRequest'->new($_) } @$_ ] };

declare 'MapStringGenerateHlsUriRequest',
    as HashRef[GenerateHlsUriRequest()];

declare 'GenerateHlsUriResponse',
    as InstanceOf['Google::Cloud::Visionai::V1alpha1::Warehouse::GenerateHlsUriResponse'];

coerce 'GenerateHlsUriResponse',
    from HashRef, via { 'Google::Cloud::Visionai::V1alpha1::Warehouse::GenerateHlsUriResponse'->new($_) };

declare 'RepeatedGenerateHlsUriResponse',
    as ArrayRef[GenerateHlsUriResponse()];

coerce 'RepeatedGenerateHlsUriResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1alpha1::Warehouse::GenerateHlsUriResponse'->new($_) } @$_ ] };

declare 'MapStringGenerateHlsUriResponse',
    as HashRef[GenerateHlsUriResponse()];

declare 'SearchAssetsRequest',
    as InstanceOf['Google::Cloud::Visionai::V1alpha1::Warehouse::SearchAssetsRequest'];

coerce 'SearchAssetsRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1alpha1::Warehouse::SearchAssetsRequest'->new($_) };

declare 'RepeatedSearchAssetsRequest',
    as ArrayRef[SearchAssetsRequest()];

coerce 'RepeatedSearchAssetsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1alpha1::Warehouse::SearchAssetsRequest'->new($_) } @$_ ] };

declare 'MapStringSearchAssetsRequest',
    as HashRef[SearchAssetsRequest()];

declare 'DeleteAssetMetadata',
    as InstanceOf['Google::Cloud::Visionai::V1alpha1::Warehouse::DeleteAssetMetadata'];

coerce 'DeleteAssetMetadata',
    from HashRef, via { 'Google::Cloud::Visionai::V1alpha1::Warehouse::DeleteAssetMetadata'->new($_) };

declare 'RepeatedDeleteAssetMetadata',
    as ArrayRef[DeleteAssetMetadata()];

coerce 'RepeatedDeleteAssetMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1alpha1::Warehouse::DeleteAssetMetadata'->new($_) } @$_ ] };

declare 'MapStringDeleteAssetMetadata',
    as HashRef[DeleteAssetMetadata()];

declare 'AnnotationMatchingResult',
    as InstanceOf['Google::Cloud::Visionai::V1alpha1::Warehouse::AnnotationMatchingResult'];

coerce 'AnnotationMatchingResult',
    from HashRef, via { 'Google::Cloud::Visionai::V1alpha1::Warehouse::AnnotationMatchingResult'->new($_) };

declare 'RepeatedAnnotationMatchingResult',
    as ArrayRef[AnnotationMatchingResult()];

coerce 'RepeatedAnnotationMatchingResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1alpha1::Warehouse::AnnotationMatchingResult'->new($_) } @$_ ] };

declare 'MapStringAnnotationMatchingResult',
    as HashRef[AnnotationMatchingResult()];

declare 'SearchResultItem',
    as InstanceOf['Google::Cloud::Visionai::V1alpha1::Warehouse::SearchResultItem'];

coerce 'SearchResultItem',
    from HashRef, via { 'Google::Cloud::Visionai::V1alpha1::Warehouse::SearchResultItem'->new($_) };

declare 'RepeatedSearchResultItem',
    as ArrayRef[SearchResultItem()];

coerce 'RepeatedSearchResultItem',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1alpha1::Warehouse::SearchResultItem'->new($_) } @$_ ] };

declare 'MapStringSearchResultItem',
    as HashRef[SearchResultItem()];

declare 'SearchAssetsResponse',
    as InstanceOf['Google::Cloud::Visionai::V1alpha1::Warehouse::SearchAssetsResponse'];

coerce 'SearchAssetsResponse',
    from HashRef, via { 'Google::Cloud::Visionai::V1alpha1::Warehouse::SearchAssetsResponse'->new($_) };

declare 'RepeatedSearchAssetsResponse',
    as ArrayRef[SearchAssetsResponse()];

coerce 'RepeatedSearchAssetsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1alpha1::Warehouse::SearchAssetsResponse'->new($_) } @$_ ] };

declare 'MapStringSearchAssetsResponse',
    as HashRef[SearchAssetsResponse()];

declare 'IntRange',
    as InstanceOf['Google::Cloud::Visionai::V1alpha1::Warehouse::IntRange'];

coerce 'IntRange',
    from HashRef, via { 'Google::Cloud::Visionai::V1alpha1::Warehouse::IntRange'->new($_) };

declare 'RepeatedIntRange',
    as ArrayRef[IntRange()];

coerce 'RepeatedIntRange',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1alpha1::Warehouse::IntRange'->new($_) } @$_ ] };

declare 'MapStringIntRange',
    as HashRef[IntRange()];

declare 'FloatRange',
    as InstanceOf['Google::Cloud::Visionai::V1alpha1::Warehouse::FloatRange'];

coerce 'FloatRange',
    from HashRef, via { 'Google::Cloud::Visionai::V1alpha1::Warehouse::FloatRange'->new($_) };

declare 'RepeatedFloatRange',
    as ArrayRef[FloatRange()];

coerce 'RepeatedFloatRange',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1alpha1::Warehouse::FloatRange'->new($_) } @$_ ] };

declare 'MapStringFloatRange',
    as HashRef[FloatRange()];

declare 'StringArray',
    as InstanceOf['Google::Cloud::Visionai::V1alpha1::Warehouse::StringArray'];

coerce 'StringArray',
    from HashRef, via { 'Google::Cloud::Visionai::V1alpha1::Warehouse::StringArray'->new($_) };

declare 'RepeatedStringArray',
    as ArrayRef[StringArray()];

coerce 'RepeatedStringArray',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1alpha1::Warehouse::StringArray'->new($_) } @$_ ] };

declare 'MapStringStringArray',
    as HashRef[StringArray()];

declare 'IntRangeArray',
    as InstanceOf['Google::Cloud::Visionai::V1alpha1::Warehouse::IntRangeArray'];

coerce 'IntRangeArray',
    from HashRef, via { 'Google::Cloud::Visionai::V1alpha1::Warehouse::IntRangeArray'->new($_) };

declare 'RepeatedIntRangeArray',
    as ArrayRef[IntRangeArray()];

coerce 'RepeatedIntRangeArray',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1alpha1::Warehouse::IntRangeArray'->new($_) } @$_ ] };

declare 'MapStringIntRangeArray',
    as HashRef[IntRangeArray()];

declare 'FloatRangeArray',
    as InstanceOf['Google::Cloud::Visionai::V1alpha1::Warehouse::FloatRangeArray'];

coerce 'FloatRangeArray',
    from HashRef, via { 'Google::Cloud::Visionai::V1alpha1::Warehouse::FloatRangeArray'->new($_) };

declare 'RepeatedFloatRangeArray',
    as ArrayRef[FloatRangeArray()];

coerce 'RepeatedFloatRangeArray',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1alpha1::Warehouse::FloatRangeArray'->new($_) } @$_ ] };

declare 'MapStringFloatRangeArray',
    as HashRef[FloatRangeArray()];

declare 'DateTimeRange',
    as InstanceOf['Google::Cloud::Visionai::V1alpha1::Warehouse::DateTimeRange'];

coerce 'DateTimeRange',
    from HashRef, via { 'Google::Cloud::Visionai::V1alpha1::Warehouse::DateTimeRange'->new($_) };

declare 'RepeatedDateTimeRange',
    as ArrayRef[DateTimeRange()];

coerce 'RepeatedDateTimeRange',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1alpha1::Warehouse::DateTimeRange'->new($_) } @$_ ] };

declare 'MapStringDateTimeRange',
    as HashRef[DateTimeRange()];

declare 'DateTimeRangeArray',
    as InstanceOf['Google::Cloud::Visionai::V1alpha1::Warehouse::DateTimeRangeArray'];

coerce 'DateTimeRangeArray',
    from HashRef, via { 'Google::Cloud::Visionai::V1alpha1::Warehouse::DateTimeRangeArray'->new($_) };

declare 'RepeatedDateTimeRangeArray',
    as ArrayRef[DateTimeRangeArray()];

coerce 'RepeatedDateTimeRangeArray',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1alpha1::Warehouse::DateTimeRangeArray'->new($_) } @$_ ] };

declare 'MapStringDateTimeRangeArray',
    as HashRef[DateTimeRangeArray()];

declare 'CircleArea',
    as InstanceOf['Google::Cloud::Visionai::V1alpha1::Warehouse::CircleArea'];

coerce 'CircleArea',
    from HashRef, via { 'Google::Cloud::Visionai::V1alpha1::Warehouse::CircleArea'->new($_) };

declare 'RepeatedCircleArea',
    as ArrayRef[CircleArea()];

coerce 'RepeatedCircleArea',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1alpha1::Warehouse::CircleArea'->new($_) } @$_ ] };

declare 'MapStringCircleArea',
    as HashRef[CircleArea()];

declare 'GeoLocationArray',
    as InstanceOf['Google::Cloud::Visionai::V1alpha1::Warehouse::GeoLocationArray'];

coerce 'GeoLocationArray',
    from HashRef, via { 'Google::Cloud::Visionai::V1alpha1::Warehouse::GeoLocationArray'->new($_) };

declare 'RepeatedGeoLocationArray',
    as ArrayRef[GeoLocationArray()];

coerce 'RepeatedGeoLocationArray',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1alpha1::Warehouse::GeoLocationArray'->new($_) } @$_ ] };

declare 'MapStringGeoLocationArray',
    as HashRef[GeoLocationArray()];

declare 'BoolValue',
    as InstanceOf['Google::Cloud::Visionai::V1alpha1::Warehouse::BoolValue'];

coerce 'BoolValue',
    from HashRef, via { 'Google::Cloud::Visionai::V1alpha1::Warehouse::BoolValue'->new($_) };

declare 'RepeatedBoolValue',
    as ArrayRef[BoolValue()];

coerce 'RepeatedBoolValue',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1alpha1::Warehouse::BoolValue'->new($_) } @$_ ] };

declare 'MapStringBoolValue',
    as HashRef[BoolValue()];

declare 'Criteria',
    as InstanceOf['Google::Cloud::Visionai::V1alpha1::Warehouse::Criteria'];

coerce 'Criteria',
    from HashRef, via { 'Google::Cloud::Visionai::V1alpha1::Warehouse::Criteria'->new($_) };

declare 'RepeatedCriteria',
    as ArrayRef[Criteria()];

coerce 'RepeatedCriteria',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1alpha1::Warehouse::Criteria'->new($_) } @$_ ] };

declare 'MapStringCriteria',
    as HashRef[Criteria()];

declare 'Partition',
    as InstanceOf['Google::Cloud::Visionai::V1alpha1::Warehouse::Partition'];

coerce 'Partition',
    from HashRef, via { 'Google::Cloud::Visionai::V1alpha1::Warehouse::Partition'->new($_) };

declare 'RepeatedPartition',
    as ArrayRef[Partition()];

coerce 'RepeatedPartition',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1alpha1::Warehouse::Partition'->new($_) } @$_ ] };

declare 'MapStringPartition',
    as HashRef[Partition()];

declare 'TemporalPartition',
    as InstanceOf['Google::Cloud::Visionai::V1alpha1::Warehouse::Partition::TemporalPartition'];

coerce 'TemporalPartition',
    from HashRef, via { 'Google::Cloud::Visionai::V1alpha1::Warehouse::Partition::TemporalPartition'->new($_) };

declare 'RepeatedTemporalPartition',
    as ArrayRef[TemporalPartition()];

coerce 'RepeatedTemporalPartition',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1alpha1::Warehouse::Partition::TemporalPartition'->new($_) } @$_ ] };

declare 'MapStringTemporalPartition',
    as HashRef[TemporalPartition()];

declare 'SpatialPartition',
    as InstanceOf['Google::Cloud::Visionai::V1alpha1::Warehouse::Partition::SpatialPartition'];

coerce 'SpatialPartition',
    from HashRef, via { 'Google::Cloud::Visionai::V1alpha1::Warehouse::Partition::SpatialPartition'->new($_) };

declare 'RepeatedSpatialPartition',
    as ArrayRef[SpatialPartition()];

coerce 'RepeatedSpatialPartition',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1alpha1::Warehouse::Partition::SpatialPartition'->new($_) } @$_ ] };

declare 'MapStringSpatialPartition',
    as HashRef[SpatialPartition()];

1;

__END__

=head1 NAME

Google::Cloud::Visionai::V1alpha1::Warehouse::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
