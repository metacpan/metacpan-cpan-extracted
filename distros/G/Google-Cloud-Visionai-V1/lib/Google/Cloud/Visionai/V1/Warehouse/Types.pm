package Google::Cloud::Visionai::V1::Warehouse::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'FacetBucketType',
    as (Int | Str);

declare 'CreateAssetRequest',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::CreateAssetRequest'];

coerce 'CreateAssetRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::CreateAssetRequest'->new($_) };

declare 'RepeatedCreateAssetRequest',
    as ArrayRef[CreateAssetRequest()];

coerce 'RepeatedCreateAssetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::CreateAssetRequest'->new($_) } @$_ ] };

declare 'MapStringCreateAssetRequest',
    as HashRef[CreateAssetRequest()];

declare 'GetAssetRequest',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::GetAssetRequest'];

coerce 'GetAssetRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::GetAssetRequest'->new($_) };

declare 'RepeatedGetAssetRequest',
    as ArrayRef[GetAssetRequest()];

coerce 'RepeatedGetAssetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::GetAssetRequest'->new($_) } @$_ ] };

declare 'MapStringGetAssetRequest',
    as HashRef[GetAssetRequest()];

declare 'ListAssetsRequest',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::ListAssetsRequest'];

coerce 'ListAssetsRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::ListAssetsRequest'->new($_) };

declare 'RepeatedListAssetsRequest',
    as ArrayRef[ListAssetsRequest()];

coerce 'RepeatedListAssetsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::ListAssetsRequest'->new($_) } @$_ ] };

declare 'MapStringListAssetsRequest',
    as HashRef[ListAssetsRequest()];

declare 'ListAssetsResponse',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::ListAssetsResponse'];

coerce 'ListAssetsResponse',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::ListAssetsResponse'->new($_) };

declare 'RepeatedListAssetsResponse',
    as ArrayRef[ListAssetsResponse()];

coerce 'RepeatedListAssetsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::ListAssetsResponse'->new($_) } @$_ ] };

declare 'MapStringListAssetsResponse',
    as HashRef[ListAssetsResponse()];

declare 'UpdateAssetRequest',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::UpdateAssetRequest'];

coerce 'UpdateAssetRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::UpdateAssetRequest'->new($_) };

declare 'RepeatedUpdateAssetRequest',
    as ArrayRef[UpdateAssetRequest()];

coerce 'RepeatedUpdateAssetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::UpdateAssetRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateAssetRequest',
    as HashRef[UpdateAssetRequest()];

declare 'DeleteAssetRequest',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::DeleteAssetRequest'];

coerce 'DeleteAssetRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::DeleteAssetRequest'->new($_) };

declare 'RepeatedDeleteAssetRequest',
    as ArrayRef[DeleteAssetRequest()];

coerce 'RepeatedDeleteAssetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::DeleteAssetRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteAssetRequest',
    as HashRef[DeleteAssetRequest()];

declare 'AssetSource',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::AssetSource'];

coerce 'AssetSource',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::AssetSource'->new($_) };

declare 'RepeatedAssetSource',
    as ArrayRef[AssetSource()];

coerce 'RepeatedAssetSource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::AssetSource'->new($_) } @$_ ] };

declare 'MapStringAssetSource',
    as HashRef[AssetSource()];

declare 'AssetGcsSource',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::AssetSource::AssetGcsSource'];

coerce 'AssetGcsSource',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::AssetSource::AssetGcsSource'->new($_) };

declare 'RepeatedAssetGcsSource',
    as ArrayRef[AssetGcsSource()];

coerce 'RepeatedAssetGcsSource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::AssetSource::AssetGcsSource'->new($_) } @$_ ] };

declare 'MapStringAssetGcsSource',
    as HashRef[AssetGcsSource()];

declare 'AssetContentData',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::AssetSource::AssetContentData'];

coerce 'AssetContentData',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::AssetSource::AssetContentData'->new($_) };

declare 'RepeatedAssetContentData',
    as ArrayRef[AssetContentData()];

coerce 'RepeatedAssetContentData',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::AssetSource::AssetContentData'->new($_) } @$_ ] };

declare 'MapStringAssetContentData',
    as HashRef[AssetContentData()];

declare 'UploadAssetRequest',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::UploadAssetRequest'];

coerce 'UploadAssetRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::UploadAssetRequest'->new($_) };

declare 'RepeatedUploadAssetRequest',
    as ArrayRef[UploadAssetRequest()];

coerce 'RepeatedUploadAssetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::UploadAssetRequest'->new($_) } @$_ ] };

declare 'MapStringUploadAssetRequest',
    as HashRef[UploadAssetRequest()];

declare 'UploadAssetResponse',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::UploadAssetResponse'];

coerce 'UploadAssetResponse',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::UploadAssetResponse'->new($_) };

declare 'RepeatedUploadAssetResponse',
    as ArrayRef[UploadAssetResponse()];

coerce 'RepeatedUploadAssetResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::UploadAssetResponse'->new($_) } @$_ ] };

declare 'MapStringUploadAssetResponse',
    as HashRef[UploadAssetResponse()];

declare 'UploadAssetMetadata',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::UploadAssetMetadata'];

coerce 'UploadAssetMetadata',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::UploadAssetMetadata'->new($_) };

declare 'RepeatedUploadAssetMetadata',
    as ArrayRef[UploadAssetMetadata()];

coerce 'RepeatedUploadAssetMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::UploadAssetMetadata'->new($_) } @$_ ] };

declare 'MapStringUploadAssetMetadata',
    as HashRef[UploadAssetMetadata()];

declare 'GenerateRetrievalUrlRequest',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::GenerateRetrievalUrlRequest'];

coerce 'GenerateRetrievalUrlRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::GenerateRetrievalUrlRequest'->new($_) };

declare 'RepeatedGenerateRetrievalUrlRequest',
    as ArrayRef[GenerateRetrievalUrlRequest()];

coerce 'RepeatedGenerateRetrievalUrlRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::GenerateRetrievalUrlRequest'->new($_) } @$_ ] };

declare 'MapStringGenerateRetrievalUrlRequest',
    as HashRef[GenerateRetrievalUrlRequest()];

declare 'GenerateRetrievalUrlResponse',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::GenerateRetrievalUrlResponse'];

coerce 'GenerateRetrievalUrlResponse',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::GenerateRetrievalUrlResponse'->new($_) };

declare 'RepeatedGenerateRetrievalUrlResponse',
    as ArrayRef[GenerateRetrievalUrlResponse()];

coerce 'RepeatedGenerateRetrievalUrlResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::GenerateRetrievalUrlResponse'->new($_) } @$_ ] };

declare 'MapStringGenerateRetrievalUrlResponse',
    as HashRef[GenerateRetrievalUrlResponse()];

declare 'Asset',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::Asset'];

coerce 'Asset',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::Asset'->new($_) };

declare 'RepeatedAsset',
    as ArrayRef[Asset()];

coerce 'RepeatedAsset',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::Asset'->new($_) } @$_ ] };

declare 'MapStringAsset',
    as HashRef[Asset()];

declare 'AnalyzeAssetRequest',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::AnalyzeAssetRequest'];

coerce 'AnalyzeAssetRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::AnalyzeAssetRequest'->new($_) };

declare 'RepeatedAnalyzeAssetRequest',
    as ArrayRef[AnalyzeAssetRequest()];

coerce 'RepeatedAnalyzeAssetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::AnalyzeAssetRequest'->new($_) } @$_ ] };

declare 'MapStringAnalyzeAssetRequest',
    as HashRef[AnalyzeAssetRequest()];

declare 'AnalyzeAssetMetadata',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::AnalyzeAssetMetadata'];

coerce 'AnalyzeAssetMetadata',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::AnalyzeAssetMetadata'->new($_) };

declare 'RepeatedAnalyzeAssetMetadata',
    as ArrayRef[AnalyzeAssetMetadata()];

coerce 'RepeatedAnalyzeAssetMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::AnalyzeAssetMetadata'->new($_) } @$_ ] };

declare 'MapStringAnalyzeAssetMetadata',
    as HashRef[AnalyzeAssetMetadata()];

declare 'AnalysisStatus',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::AnalyzeAssetMetadata::AnalysisStatus'];

coerce 'AnalysisStatus',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::AnalyzeAssetMetadata::AnalysisStatus'->new($_) };

declare 'RepeatedAnalysisStatus',
    as ArrayRef[AnalysisStatus()];

coerce 'RepeatedAnalysisStatus',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::AnalyzeAssetMetadata::AnalysisStatus'->new($_) } @$_ ] };

declare 'MapStringAnalysisStatus',
    as HashRef[AnalysisStatus()];

declare 'State',
    as (Int | Str);

declare 'AnalyzeAssetResponse',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::AnalyzeAssetResponse'];

coerce 'AnalyzeAssetResponse',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::AnalyzeAssetResponse'->new($_) };

declare 'RepeatedAnalyzeAssetResponse',
    as ArrayRef[AnalyzeAssetResponse()];

coerce 'RepeatedAnalyzeAssetResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::AnalyzeAssetResponse'->new($_) } @$_ ] };

declare 'MapStringAnalyzeAssetResponse',
    as HashRef[AnalyzeAssetResponse()];

declare 'IndexingStatus',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::IndexingStatus'];

coerce 'IndexingStatus',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::IndexingStatus'->new($_) };

declare 'RepeatedIndexingStatus',
    as ArrayRef[IndexingStatus()];

coerce 'RepeatedIndexingStatus',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::IndexingStatus'->new($_) } @$_ ] };

declare 'MapStringIndexingStatus',
    as HashRef[IndexingStatus()];

declare 'State',
    as (Int | Str);

declare 'IndexAssetRequest',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::IndexAssetRequest'];

coerce 'IndexAssetRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::IndexAssetRequest'->new($_) };

declare 'RepeatedIndexAssetRequest',
    as ArrayRef[IndexAssetRequest()];

coerce 'RepeatedIndexAssetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::IndexAssetRequest'->new($_) } @$_ ] };

declare 'MapStringIndexAssetRequest',
    as HashRef[IndexAssetRequest()];

declare 'IndexAssetMetadata',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::IndexAssetMetadata'];

coerce 'IndexAssetMetadata',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::IndexAssetMetadata'->new($_) };

declare 'RepeatedIndexAssetMetadata',
    as ArrayRef[IndexAssetMetadata()];

coerce 'RepeatedIndexAssetMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::IndexAssetMetadata'->new($_) } @$_ ] };

declare 'MapStringIndexAssetMetadata',
    as HashRef[IndexAssetMetadata()];

declare 'IndexAssetResponse',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::IndexAssetResponse'];

coerce 'IndexAssetResponse',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::IndexAssetResponse'->new($_) };

declare 'RepeatedIndexAssetResponse',
    as ArrayRef[IndexAssetResponse()];

coerce 'RepeatedIndexAssetResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::IndexAssetResponse'->new($_) } @$_ ] };

declare 'MapStringIndexAssetResponse',
    as HashRef[IndexAssetResponse()];

declare 'RemoveIndexAssetRequest',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::RemoveIndexAssetRequest'];

coerce 'RemoveIndexAssetRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::RemoveIndexAssetRequest'->new($_) };

declare 'RepeatedRemoveIndexAssetRequest',
    as ArrayRef[RemoveIndexAssetRequest()];

coerce 'RepeatedRemoveIndexAssetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::RemoveIndexAssetRequest'->new($_) } @$_ ] };

declare 'MapStringRemoveIndexAssetRequest',
    as HashRef[RemoveIndexAssetRequest()];

declare 'RemoveIndexAssetMetadata',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::RemoveIndexAssetMetadata'];

coerce 'RemoveIndexAssetMetadata',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::RemoveIndexAssetMetadata'->new($_) };

declare 'RepeatedRemoveIndexAssetMetadata',
    as ArrayRef[RemoveIndexAssetMetadata()];

coerce 'RepeatedRemoveIndexAssetMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::RemoveIndexAssetMetadata'->new($_) } @$_ ] };

declare 'MapStringRemoveIndexAssetMetadata',
    as HashRef[RemoveIndexAssetMetadata()];

declare 'RemoveIndexAssetResponse',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::RemoveIndexAssetResponse'];

coerce 'RemoveIndexAssetResponse',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::RemoveIndexAssetResponse'->new($_) };

declare 'RepeatedRemoveIndexAssetResponse',
    as ArrayRef[RemoveIndexAssetResponse()];

coerce 'RepeatedRemoveIndexAssetResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::RemoveIndexAssetResponse'->new($_) } @$_ ] };

declare 'MapStringRemoveIndexAssetResponse',
    as HashRef[RemoveIndexAssetResponse()];

declare 'IndexedAsset',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::IndexedAsset'];

coerce 'IndexedAsset',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::IndexedAsset'->new($_) };

declare 'RepeatedIndexedAsset',
    as ArrayRef[IndexedAsset()];

coerce 'RepeatedIndexedAsset',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::IndexedAsset'->new($_) } @$_ ] };

declare 'MapStringIndexedAsset',
    as HashRef[IndexedAsset()];

declare 'ViewIndexedAssetsRequest',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::ViewIndexedAssetsRequest'];

coerce 'ViewIndexedAssetsRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::ViewIndexedAssetsRequest'->new($_) };

declare 'RepeatedViewIndexedAssetsRequest',
    as ArrayRef[ViewIndexedAssetsRequest()];

coerce 'RepeatedViewIndexedAssetsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::ViewIndexedAssetsRequest'->new($_) } @$_ ] };

declare 'MapStringViewIndexedAssetsRequest',
    as HashRef[ViewIndexedAssetsRequest()];

declare 'ViewIndexedAssetsResponse',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::ViewIndexedAssetsResponse'];

coerce 'ViewIndexedAssetsResponse',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::ViewIndexedAssetsResponse'->new($_) };

declare 'RepeatedViewIndexedAssetsResponse',
    as ArrayRef[ViewIndexedAssetsResponse()];

coerce 'RepeatedViewIndexedAssetsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::ViewIndexedAssetsResponse'->new($_) } @$_ ] };

declare 'MapStringViewIndexedAssetsResponse',
    as HashRef[ViewIndexedAssetsResponse()];

declare 'CreateCorpusRequest',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::CreateCorpusRequest'];

coerce 'CreateCorpusRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::CreateCorpusRequest'->new($_) };

declare 'RepeatedCreateCorpusRequest',
    as ArrayRef[CreateCorpusRequest()];

coerce 'RepeatedCreateCorpusRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::CreateCorpusRequest'->new($_) } @$_ ] };

declare 'MapStringCreateCorpusRequest',
    as HashRef[CreateCorpusRequest()];

declare 'CreateCorpusMetadata',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::CreateCorpusMetadata'];

coerce 'CreateCorpusMetadata',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::CreateCorpusMetadata'->new($_) };

declare 'RepeatedCreateCorpusMetadata',
    as ArrayRef[CreateCorpusMetadata()];

coerce 'RepeatedCreateCorpusMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::CreateCorpusMetadata'->new($_) } @$_ ] };

declare 'MapStringCreateCorpusMetadata',
    as HashRef[CreateCorpusMetadata()];

declare 'SearchCapability',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::SearchCapability'];

coerce 'SearchCapability',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::SearchCapability'->new($_) };

declare 'RepeatedSearchCapability',
    as ArrayRef[SearchCapability()];

coerce 'RepeatedSearchCapability',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::SearchCapability'->new($_) } @$_ ] };

declare 'MapStringSearchCapability',
    as HashRef[SearchCapability()];

declare 'Type',
    as (Int | Str);

declare 'SearchCapabilitySetting',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::SearchCapabilitySetting'];

coerce 'SearchCapabilitySetting',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::SearchCapabilitySetting'->new($_) };

declare 'RepeatedSearchCapabilitySetting',
    as ArrayRef[SearchCapabilitySetting()];

coerce 'RepeatedSearchCapabilitySetting',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::SearchCapabilitySetting'->new($_) } @$_ ] };

declare 'MapStringSearchCapabilitySetting',
    as HashRef[SearchCapabilitySetting()];

declare 'CreateCollectionMetadata',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::CreateCollectionMetadata'];

coerce 'CreateCollectionMetadata',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::CreateCollectionMetadata'->new($_) };

declare 'RepeatedCreateCollectionMetadata',
    as ArrayRef[CreateCollectionMetadata()];

coerce 'RepeatedCreateCollectionMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::CreateCollectionMetadata'->new($_) } @$_ ] };

declare 'MapStringCreateCollectionMetadata',
    as HashRef[CreateCollectionMetadata()];

declare 'CreateCollectionRequest',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::CreateCollectionRequest'];

coerce 'CreateCollectionRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::CreateCollectionRequest'->new($_) };

declare 'RepeatedCreateCollectionRequest',
    as ArrayRef[CreateCollectionRequest()];

coerce 'RepeatedCreateCollectionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::CreateCollectionRequest'->new($_) } @$_ ] };

declare 'MapStringCreateCollectionRequest',
    as HashRef[CreateCollectionRequest()];

declare 'DeleteCollectionMetadata',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::DeleteCollectionMetadata'];

coerce 'DeleteCollectionMetadata',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::DeleteCollectionMetadata'->new($_) };

declare 'RepeatedDeleteCollectionMetadata',
    as ArrayRef[DeleteCollectionMetadata()];

coerce 'RepeatedDeleteCollectionMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::DeleteCollectionMetadata'->new($_) } @$_ ] };

declare 'MapStringDeleteCollectionMetadata',
    as HashRef[DeleteCollectionMetadata()];

declare 'DeleteCollectionRequest',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::DeleteCollectionRequest'];

coerce 'DeleteCollectionRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::DeleteCollectionRequest'->new($_) };

declare 'RepeatedDeleteCollectionRequest',
    as ArrayRef[DeleteCollectionRequest()];

coerce 'RepeatedDeleteCollectionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::DeleteCollectionRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteCollectionRequest',
    as HashRef[DeleteCollectionRequest()];

declare 'GetCollectionRequest',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::GetCollectionRequest'];

coerce 'GetCollectionRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::GetCollectionRequest'->new($_) };

declare 'RepeatedGetCollectionRequest',
    as ArrayRef[GetCollectionRequest()];

coerce 'RepeatedGetCollectionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::GetCollectionRequest'->new($_) } @$_ ] };

declare 'MapStringGetCollectionRequest',
    as HashRef[GetCollectionRequest()];

declare 'UpdateCollectionRequest',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::UpdateCollectionRequest'];

coerce 'UpdateCollectionRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::UpdateCollectionRequest'->new($_) };

declare 'RepeatedUpdateCollectionRequest',
    as ArrayRef[UpdateCollectionRequest()];

coerce 'RepeatedUpdateCollectionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::UpdateCollectionRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateCollectionRequest',
    as HashRef[UpdateCollectionRequest()];

declare 'ListCollectionsRequest',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::ListCollectionsRequest'];

coerce 'ListCollectionsRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::ListCollectionsRequest'->new($_) };

declare 'RepeatedListCollectionsRequest',
    as ArrayRef[ListCollectionsRequest()];

coerce 'RepeatedListCollectionsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::ListCollectionsRequest'->new($_) } @$_ ] };

declare 'MapStringListCollectionsRequest',
    as HashRef[ListCollectionsRequest()];

declare 'ListCollectionsResponse',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::ListCollectionsResponse'];

coerce 'ListCollectionsResponse',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::ListCollectionsResponse'->new($_) };

declare 'RepeatedListCollectionsResponse',
    as ArrayRef[ListCollectionsResponse()];

coerce 'RepeatedListCollectionsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::ListCollectionsResponse'->new($_) } @$_ ] };

declare 'MapStringListCollectionsResponse',
    as HashRef[ListCollectionsResponse()];

declare 'AddCollectionItemRequest',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::AddCollectionItemRequest'];

coerce 'AddCollectionItemRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::AddCollectionItemRequest'->new($_) };

declare 'RepeatedAddCollectionItemRequest',
    as ArrayRef[AddCollectionItemRequest()];

coerce 'RepeatedAddCollectionItemRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::AddCollectionItemRequest'->new($_) } @$_ ] };

declare 'MapStringAddCollectionItemRequest',
    as HashRef[AddCollectionItemRequest()];

declare 'AddCollectionItemResponse',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::AddCollectionItemResponse'];

coerce 'AddCollectionItemResponse',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::AddCollectionItemResponse'->new($_) };

declare 'RepeatedAddCollectionItemResponse',
    as ArrayRef[AddCollectionItemResponse()];

coerce 'RepeatedAddCollectionItemResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::AddCollectionItemResponse'->new($_) } @$_ ] };

declare 'MapStringAddCollectionItemResponse',
    as HashRef[AddCollectionItemResponse()];

declare 'RemoveCollectionItemRequest',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::RemoveCollectionItemRequest'];

coerce 'RemoveCollectionItemRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::RemoveCollectionItemRequest'->new($_) };

declare 'RepeatedRemoveCollectionItemRequest',
    as ArrayRef[RemoveCollectionItemRequest()];

coerce 'RepeatedRemoveCollectionItemRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::RemoveCollectionItemRequest'->new($_) } @$_ ] };

declare 'MapStringRemoveCollectionItemRequest',
    as HashRef[RemoveCollectionItemRequest()];

declare 'RemoveCollectionItemResponse',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::RemoveCollectionItemResponse'];

coerce 'RemoveCollectionItemResponse',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::RemoveCollectionItemResponse'->new($_) };

declare 'RepeatedRemoveCollectionItemResponse',
    as ArrayRef[RemoveCollectionItemResponse()];

coerce 'RepeatedRemoveCollectionItemResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::RemoveCollectionItemResponse'->new($_) } @$_ ] };

declare 'MapStringRemoveCollectionItemResponse',
    as HashRef[RemoveCollectionItemResponse()];

declare 'ViewCollectionItemsRequest',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::ViewCollectionItemsRequest'];

coerce 'ViewCollectionItemsRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::ViewCollectionItemsRequest'->new($_) };

declare 'RepeatedViewCollectionItemsRequest',
    as ArrayRef[ViewCollectionItemsRequest()];

coerce 'RepeatedViewCollectionItemsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::ViewCollectionItemsRequest'->new($_) } @$_ ] };

declare 'MapStringViewCollectionItemsRequest',
    as HashRef[ViewCollectionItemsRequest()];

declare 'ViewCollectionItemsResponse',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::ViewCollectionItemsResponse'];

coerce 'ViewCollectionItemsResponse',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::ViewCollectionItemsResponse'->new($_) };

declare 'RepeatedViewCollectionItemsResponse',
    as ArrayRef[ViewCollectionItemsResponse()];

coerce 'RepeatedViewCollectionItemsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::ViewCollectionItemsResponse'->new($_) } @$_ ] };

declare 'MapStringViewCollectionItemsResponse',
    as HashRef[ViewCollectionItemsResponse()];

declare 'Collection',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::Collection'];

coerce 'Collection',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::Collection'->new($_) };

declare 'RepeatedCollection',
    as ArrayRef[Collection()];

coerce 'RepeatedCollection',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::Collection'->new($_) } @$_ ] };

declare 'MapStringCollection',
    as HashRef[Collection()];

declare 'CollectionItem',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::CollectionItem'];

coerce 'CollectionItem',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::CollectionItem'->new($_) };

declare 'RepeatedCollectionItem',
    as ArrayRef[CollectionItem()];

coerce 'RepeatedCollectionItem',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::CollectionItem'->new($_) } @$_ ] };

declare 'MapStringCollectionItem',
    as HashRef[CollectionItem()];

declare 'Type',
    as (Int | Str);

declare 'CreateIndexRequest',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::CreateIndexRequest'];

coerce 'CreateIndexRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::CreateIndexRequest'->new($_) };

declare 'RepeatedCreateIndexRequest',
    as ArrayRef[CreateIndexRequest()];

coerce 'RepeatedCreateIndexRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::CreateIndexRequest'->new($_) } @$_ ] };

declare 'MapStringCreateIndexRequest',
    as HashRef[CreateIndexRequest()];

declare 'CreateIndexMetadata',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::CreateIndexMetadata'];

coerce 'CreateIndexMetadata',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::CreateIndexMetadata'->new($_) };

declare 'RepeatedCreateIndexMetadata',
    as ArrayRef[CreateIndexMetadata()];

coerce 'RepeatedCreateIndexMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::CreateIndexMetadata'->new($_) } @$_ ] };

declare 'MapStringCreateIndexMetadata',
    as HashRef[CreateIndexMetadata()];

declare 'UpdateIndexRequest',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::UpdateIndexRequest'];

coerce 'UpdateIndexRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::UpdateIndexRequest'->new($_) };

declare 'RepeatedUpdateIndexRequest',
    as ArrayRef[UpdateIndexRequest()];

coerce 'RepeatedUpdateIndexRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::UpdateIndexRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateIndexRequest',
    as HashRef[UpdateIndexRequest()];

declare 'UpdateIndexMetadata',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::UpdateIndexMetadata'];

coerce 'UpdateIndexMetadata',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::UpdateIndexMetadata'->new($_) };

declare 'RepeatedUpdateIndexMetadata',
    as ArrayRef[UpdateIndexMetadata()];

coerce 'RepeatedUpdateIndexMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::UpdateIndexMetadata'->new($_) } @$_ ] };

declare 'MapStringUpdateIndexMetadata',
    as HashRef[UpdateIndexMetadata()];

declare 'GetIndexRequest',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::GetIndexRequest'];

coerce 'GetIndexRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::GetIndexRequest'->new($_) };

declare 'RepeatedGetIndexRequest',
    as ArrayRef[GetIndexRequest()];

coerce 'RepeatedGetIndexRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::GetIndexRequest'->new($_) } @$_ ] };

declare 'MapStringGetIndexRequest',
    as HashRef[GetIndexRequest()];

declare 'ListIndexesRequest',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::ListIndexesRequest'];

coerce 'ListIndexesRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::ListIndexesRequest'->new($_) };

declare 'RepeatedListIndexesRequest',
    as ArrayRef[ListIndexesRequest()];

coerce 'RepeatedListIndexesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::ListIndexesRequest'->new($_) } @$_ ] };

declare 'MapStringListIndexesRequest',
    as HashRef[ListIndexesRequest()];

declare 'ListIndexesResponse',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::ListIndexesResponse'];

coerce 'ListIndexesResponse',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::ListIndexesResponse'->new($_) };

declare 'RepeatedListIndexesResponse',
    as ArrayRef[ListIndexesResponse()];

coerce 'RepeatedListIndexesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::ListIndexesResponse'->new($_) } @$_ ] };

declare 'MapStringListIndexesResponse',
    as HashRef[ListIndexesResponse()];

declare 'DeleteIndexRequest',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::DeleteIndexRequest'];

coerce 'DeleteIndexRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::DeleteIndexRequest'->new($_) };

declare 'RepeatedDeleteIndexRequest',
    as ArrayRef[DeleteIndexRequest()];

coerce 'RepeatedDeleteIndexRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::DeleteIndexRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteIndexRequest',
    as HashRef[DeleteIndexRequest()];

declare 'DeleteIndexMetadata',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::DeleteIndexMetadata'];

coerce 'DeleteIndexMetadata',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::DeleteIndexMetadata'->new($_) };

declare 'RepeatedDeleteIndexMetadata',
    as ArrayRef[DeleteIndexMetadata()];

coerce 'RepeatedDeleteIndexMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::DeleteIndexMetadata'->new($_) } @$_ ] };

declare 'MapStringDeleteIndexMetadata',
    as HashRef[DeleteIndexMetadata()];

declare 'Index',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::Index'];

coerce 'Index',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::Index'->new($_) };

declare 'RepeatedIndex',
    as ArrayRef[Index()];

coerce 'RepeatedIndex',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::Index'->new($_) } @$_ ] };

declare 'MapStringIndex',
    as HashRef[Index()];

declare 'State',
    as (Int | Str);

declare 'DeployedIndexReference',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::DeployedIndexReference'];

coerce 'DeployedIndexReference',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::DeployedIndexReference'->new($_) };

declare 'RepeatedDeployedIndexReference',
    as ArrayRef[DeployedIndexReference()];

coerce 'RepeatedDeployedIndexReference',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::DeployedIndexReference'->new($_) } @$_ ] };

declare 'MapStringDeployedIndexReference',
    as HashRef[DeployedIndexReference()];

declare 'Corpus',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::Corpus'];

coerce 'Corpus',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::Corpus'->new($_) };

declare 'RepeatedCorpus',
    as ArrayRef[Corpus()];

coerce 'RepeatedCorpus',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::Corpus'->new($_) } @$_ ] };

declare 'MapStringCorpus',
    as HashRef[Corpus()];

declare 'Type',
    as (Int | Str);

declare 'GetCorpusRequest',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::GetCorpusRequest'];

coerce 'GetCorpusRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::GetCorpusRequest'->new($_) };

declare 'RepeatedGetCorpusRequest',
    as ArrayRef[GetCorpusRequest()];

coerce 'RepeatedGetCorpusRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::GetCorpusRequest'->new($_) } @$_ ] };

declare 'MapStringGetCorpusRequest',
    as HashRef[GetCorpusRequest()];

declare 'UpdateCorpusRequest',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::UpdateCorpusRequest'];

coerce 'UpdateCorpusRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::UpdateCorpusRequest'->new($_) };

declare 'RepeatedUpdateCorpusRequest',
    as ArrayRef[UpdateCorpusRequest()];

coerce 'RepeatedUpdateCorpusRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::UpdateCorpusRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateCorpusRequest',
    as HashRef[UpdateCorpusRequest()];

declare 'ListCorporaRequest',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::ListCorporaRequest'];

coerce 'ListCorporaRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::ListCorporaRequest'->new($_) };

declare 'RepeatedListCorporaRequest',
    as ArrayRef[ListCorporaRequest()];

coerce 'RepeatedListCorporaRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::ListCorporaRequest'->new($_) } @$_ ] };

declare 'MapStringListCorporaRequest',
    as HashRef[ListCorporaRequest()];

declare 'ListCorporaResponse',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::ListCorporaResponse'];

coerce 'ListCorporaResponse',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::ListCorporaResponse'->new($_) };

declare 'RepeatedListCorporaResponse',
    as ArrayRef[ListCorporaResponse()];

coerce 'RepeatedListCorporaResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::ListCorporaResponse'->new($_) } @$_ ] };

declare 'MapStringListCorporaResponse',
    as HashRef[ListCorporaResponse()];

declare 'DeleteCorpusRequest',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::DeleteCorpusRequest'];

coerce 'DeleteCorpusRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::DeleteCorpusRequest'->new($_) };

declare 'RepeatedDeleteCorpusRequest',
    as ArrayRef[DeleteCorpusRequest()];

coerce 'RepeatedDeleteCorpusRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::DeleteCorpusRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteCorpusRequest',
    as HashRef[DeleteCorpusRequest()];

declare 'AnalyzeCorpusRequest',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::AnalyzeCorpusRequest'];

coerce 'AnalyzeCorpusRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::AnalyzeCorpusRequest'->new($_) };

declare 'RepeatedAnalyzeCorpusRequest',
    as ArrayRef[AnalyzeCorpusRequest()];

coerce 'RepeatedAnalyzeCorpusRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::AnalyzeCorpusRequest'->new($_) } @$_ ] };

declare 'MapStringAnalyzeCorpusRequest',
    as HashRef[AnalyzeCorpusRequest()];

declare 'AnalyzeCorpusMetadata',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::AnalyzeCorpusMetadata'];

coerce 'AnalyzeCorpusMetadata',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::AnalyzeCorpusMetadata'->new($_) };

declare 'RepeatedAnalyzeCorpusMetadata',
    as ArrayRef[AnalyzeCorpusMetadata()];

coerce 'RepeatedAnalyzeCorpusMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::AnalyzeCorpusMetadata'->new($_) } @$_ ] };

declare 'MapStringAnalyzeCorpusMetadata',
    as HashRef[AnalyzeCorpusMetadata()];

declare 'AnalyzeCorpusResponse',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::AnalyzeCorpusResponse'];

coerce 'AnalyzeCorpusResponse',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::AnalyzeCorpusResponse'->new($_) };

declare 'RepeatedAnalyzeCorpusResponse',
    as ArrayRef[AnalyzeCorpusResponse()];

coerce 'RepeatedAnalyzeCorpusResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::AnalyzeCorpusResponse'->new($_) } @$_ ] };

declare 'MapStringAnalyzeCorpusResponse',
    as HashRef[AnalyzeCorpusResponse()];

declare 'CreateDataSchemaRequest',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::CreateDataSchemaRequest'];

coerce 'CreateDataSchemaRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::CreateDataSchemaRequest'->new($_) };

declare 'RepeatedCreateDataSchemaRequest',
    as ArrayRef[CreateDataSchemaRequest()];

coerce 'RepeatedCreateDataSchemaRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::CreateDataSchemaRequest'->new($_) } @$_ ] };

declare 'MapStringCreateDataSchemaRequest',
    as HashRef[CreateDataSchemaRequest()];

declare 'DataSchema',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::DataSchema'];

coerce 'DataSchema',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::DataSchema'->new($_) };

declare 'RepeatedDataSchema',
    as ArrayRef[DataSchema()];

coerce 'RepeatedDataSchema',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::DataSchema'->new($_) } @$_ ] };

declare 'MapStringDataSchema',
    as HashRef[DataSchema()];

declare 'DataSchemaDetails',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::DataSchemaDetails'];

coerce 'DataSchemaDetails',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::DataSchemaDetails'->new($_) };

declare 'RepeatedDataSchemaDetails',
    as ArrayRef[DataSchemaDetails()];

coerce 'RepeatedDataSchemaDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::DataSchemaDetails'->new($_) } @$_ ] };

declare 'MapStringDataSchemaDetails',
    as HashRef[DataSchemaDetails()];

declare 'DataType',
    as (Int | Str);

declare 'Granularity',
    as (Int | Str);

declare 'ProtoAnyConfig',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::DataSchemaDetails::ProtoAnyConfig'];

coerce 'ProtoAnyConfig',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::DataSchemaDetails::ProtoAnyConfig'->new($_) };

declare 'RepeatedProtoAnyConfig',
    as ArrayRef[ProtoAnyConfig()];

coerce 'RepeatedProtoAnyConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::DataSchemaDetails::ProtoAnyConfig'->new($_) } @$_ ] };

declare 'MapStringProtoAnyConfig',
    as HashRef[ProtoAnyConfig()];

declare 'ListConfig',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::DataSchemaDetails::ListConfig'];

coerce 'ListConfig',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::DataSchemaDetails::ListConfig'->new($_) };

declare 'RepeatedListConfig',
    as ArrayRef[ListConfig()];

coerce 'RepeatedListConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::DataSchemaDetails::ListConfig'->new($_) } @$_ ] };

declare 'MapStringListConfig',
    as HashRef[ListConfig()];

declare 'CustomizedStructConfig',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::DataSchemaDetails::CustomizedStructConfig'];

coerce 'CustomizedStructConfig',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::DataSchemaDetails::CustomizedStructConfig'->new($_) };

declare 'RepeatedCustomizedStructConfig',
    as ArrayRef[CustomizedStructConfig()];

coerce 'RepeatedCustomizedStructConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::DataSchemaDetails::CustomizedStructConfig'->new($_) } @$_ ] };

declare 'MapStringCustomizedStructConfig',
    as HashRef[CustomizedStructConfig()];

declare 'FieldSchemasEntry',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::DataSchemaDetails::CustomizedStructConfig::FieldSchemasEntry'];

coerce 'FieldSchemasEntry',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::DataSchemaDetails::CustomizedStructConfig::FieldSchemasEntry'->new($_) };

declare 'RepeatedFieldSchemasEntry',
    as ArrayRef[FieldSchemasEntry()];

coerce 'RepeatedFieldSchemasEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::DataSchemaDetails::CustomizedStructConfig::FieldSchemasEntry'->new($_) } @$_ ] };

declare 'MapStringFieldSchemasEntry',
    as HashRef[FieldSchemasEntry()];

declare 'SearchStrategy',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::DataSchemaDetails::SearchStrategy'];

coerce 'SearchStrategy',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::DataSchemaDetails::SearchStrategy'->new($_) };

declare 'RepeatedSearchStrategy',
    as ArrayRef[SearchStrategy()];

coerce 'RepeatedSearchStrategy',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::DataSchemaDetails::SearchStrategy'->new($_) } @$_ ] };

declare 'MapStringSearchStrategy',
    as HashRef[SearchStrategy()];

declare 'SearchStrategyType',
    as (Int | Str);

declare 'ConfidenceScoreIndexConfig',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::DataSchemaDetails::SearchStrategy::ConfidenceScoreIndexConfig'];

coerce 'ConfidenceScoreIndexConfig',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::DataSchemaDetails::SearchStrategy::ConfidenceScoreIndexConfig'->new($_) };

declare 'RepeatedConfidenceScoreIndexConfig',
    as ArrayRef[ConfidenceScoreIndexConfig()];

coerce 'RepeatedConfidenceScoreIndexConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::DataSchemaDetails::SearchStrategy::ConfidenceScoreIndexConfig'->new($_) } @$_ ] };

declare 'MapStringConfidenceScoreIndexConfig',
    as HashRef[ConfidenceScoreIndexConfig()];

declare 'UpdateDataSchemaRequest',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::UpdateDataSchemaRequest'];

coerce 'UpdateDataSchemaRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::UpdateDataSchemaRequest'->new($_) };

declare 'RepeatedUpdateDataSchemaRequest',
    as ArrayRef[UpdateDataSchemaRequest()];

coerce 'RepeatedUpdateDataSchemaRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::UpdateDataSchemaRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateDataSchemaRequest',
    as HashRef[UpdateDataSchemaRequest()];

declare 'GetDataSchemaRequest',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::GetDataSchemaRequest'];

coerce 'GetDataSchemaRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::GetDataSchemaRequest'->new($_) };

declare 'RepeatedGetDataSchemaRequest',
    as ArrayRef[GetDataSchemaRequest()];

coerce 'RepeatedGetDataSchemaRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::GetDataSchemaRequest'->new($_) } @$_ ] };

declare 'MapStringGetDataSchemaRequest',
    as HashRef[GetDataSchemaRequest()];

declare 'DeleteDataSchemaRequest',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::DeleteDataSchemaRequest'];

coerce 'DeleteDataSchemaRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::DeleteDataSchemaRequest'->new($_) };

declare 'RepeatedDeleteDataSchemaRequest',
    as ArrayRef[DeleteDataSchemaRequest()];

coerce 'RepeatedDeleteDataSchemaRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::DeleteDataSchemaRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteDataSchemaRequest',
    as HashRef[DeleteDataSchemaRequest()];

declare 'ListDataSchemasRequest',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::ListDataSchemasRequest'];

coerce 'ListDataSchemasRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::ListDataSchemasRequest'->new($_) };

declare 'RepeatedListDataSchemasRequest',
    as ArrayRef[ListDataSchemasRequest()];

coerce 'RepeatedListDataSchemasRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::ListDataSchemasRequest'->new($_) } @$_ ] };

declare 'MapStringListDataSchemasRequest',
    as HashRef[ListDataSchemasRequest()];

declare 'ListDataSchemasResponse',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::ListDataSchemasResponse'];

coerce 'ListDataSchemasResponse',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::ListDataSchemasResponse'->new($_) };

declare 'RepeatedListDataSchemasResponse',
    as ArrayRef[ListDataSchemasResponse()];

coerce 'RepeatedListDataSchemasResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::ListDataSchemasResponse'->new($_) } @$_ ] };

declare 'MapStringListDataSchemasResponse',
    as HashRef[ListDataSchemasResponse()];

declare 'CreateAnnotationRequest',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::CreateAnnotationRequest'];

coerce 'CreateAnnotationRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::CreateAnnotationRequest'->new($_) };

declare 'RepeatedCreateAnnotationRequest',
    as ArrayRef[CreateAnnotationRequest()];

coerce 'RepeatedCreateAnnotationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::CreateAnnotationRequest'->new($_) } @$_ ] };

declare 'MapStringCreateAnnotationRequest',
    as HashRef[CreateAnnotationRequest()];

declare 'Annotation',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::Annotation'];

coerce 'Annotation',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::Annotation'->new($_) };

declare 'RepeatedAnnotation',
    as ArrayRef[Annotation()];

coerce 'RepeatedAnnotation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::Annotation'->new($_) } @$_ ] };

declare 'MapStringAnnotation',
    as HashRef[Annotation()];

declare 'UserSpecifiedAnnotation',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::UserSpecifiedAnnotation'];

coerce 'UserSpecifiedAnnotation',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::UserSpecifiedAnnotation'->new($_) };

declare 'RepeatedUserSpecifiedAnnotation',
    as ArrayRef[UserSpecifiedAnnotation()];

coerce 'RepeatedUserSpecifiedAnnotation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::UserSpecifiedAnnotation'->new($_) } @$_ ] };

declare 'MapStringUserSpecifiedAnnotation',
    as HashRef[UserSpecifiedAnnotation()];

declare 'GeoCoordinate',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::GeoCoordinate'];

coerce 'GeoCoordinate',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::GeoCoordinate'->new($_) };

declare 'RepeatedGeoCoordinate',
    as ArrayRef[GeoCoordinate()];

coerce 'RepeatedGeoCoordinate',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::GeoCoordinate'->new($_) } @$_ ] };

declare 'MapStringGeoCoordinate',
    as HashRef[GeoCoordinate()];

declare 'AnnotationValue',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::AnnotationValue'];

coerce 'AnnotationValue',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::AnnotationValue'->new($_) };

declare 'RepeatedAnnotationValue',
    as ArrayRef[AnnotationValue()];

coerce 'RepeatedAnnotationValue',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::AnnotationValue'->new($_) } @$_ ] };

declare 'MapStringAnnotationValue',
    as HashRef[AnnotationValue()];

declare 'AnnotationList',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::AnnotationList'];

coerce 'AnnotationList',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::AnnotationList'->new($_) };

declare 'RepeatedAnnotationList',
    as ArrayRef[AnnotationList()];

coerce 'RepeatedAnnotationList',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::AnnotationList'->new($_) } @$_ ] };

declare 'MapStringAnnotationList',
    as HashRef[AnnotationList()];

declare 'AnnotationCustomizedStruct',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::AnnotationCustomizedStruct'];

coerce 'AnnotationCustomizedStruct',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::AnnotationCustomizedStruct'->new($_) };

declare 'RepeatedAnnotationCustomizedStruct',
    as ArrayRef[AnnotationCustomizedStruct()];

coerce 'RepeatedAnnotationCustomizedStruct',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::AnnotationCustomizedStruct'->new($_) } @$_ ] };

declare 'MapStringAnnotationCustomizedStruct',
    as HashRef[AnnotationCustomizedStruct()];

declare 'ElementsEntry',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::AnnotationCustomizedStruct::ElementsEntry'];

coerce 'ElementsEntry',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::AnnotationCustomizedStruct::ElementsEntry'->new($_) };

declare 'RepeatedElementsEntry',
    as ArrayRef[ElementsEntry()];

coerce 'RepeatedElementsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::AnnotationCustomizedStruct::ElementsEntry'->new($_) } @$_ ] };

declare 'MapStringElementsEntry',
    as HashRef[ElementsEntry()];

declare 'ListAnnotationsRequest',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::ListAnnotationsRequest'];

coerce 'ListAnnotationsRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::ListAnnotationsRequest'->new($_) };

declare 'RepeatedListAnnotationsRequest',
    as ArrayRef[ListAnnotationsRequest()];

coerce 'RepeatedListAnnotationsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::ListAnnotationsRequest'->new($_) } @$_ ] };

declare 'MapStringListAnnotationsRequest',
    as HashRef[ListAnnotationsRequest()];

declare 'ListAnnotationsResponse',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::ListAnnotationsResponse'];

coerce 'ListAnnotationsResponse',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::ListAnnotationsResponse'->new($_) };

declare 'RepeatedListAnnotationsResponse',
    as ArrayRef[ListAnnotationsResponse()];

coerce 'RepeatedListAnnotationsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::ListAnnotationsResponse'->new($_) } @$_ ] };

declare 'MapStringListAnnotationsResponse',
    as HashRef[ListAnnotationsResponse()];

declare 'GetAnnotationRequest',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::GetAnnotationRequest'];

coerce 'GetAnnotationRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::GetAnnotationRequest'->new($_) };

declare 'RepeatedGetAnnotationRequest',
    as ArrayRef[GetAnnotationRequest()];

coerce 'RepeatedGetAnnotationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::GetAnnotationRequest'->new($_) } @$_ ] };

declare 'MapStringGetAnnotationRequest',
    as HashRef[GetAnnotationRequest()];

declare 'UpdateAnnotationRequest',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::UpdateAnnotationRequest'];

coerce 'UpdateAnnotationRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::UpdateAnnotationRequest'->new($_) };

declare 'RepeatedUpdateAnnotationRequest',
    as ArrayRef[UpdateAnnotationRequest()];

coerce 'RepeatedUpdateAnnotationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::UpdateAnnotationRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateAnnotationRequest',
    as HashRef[UpdateAnnotationRequest()];

declare 'DeleteAnnotationRequest',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::DeleteAnnotationRequest'];

coerce 'DeleteAnnotationRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::DeleteAnnotationRequest'->new($_) };

declare 'RepeatedDeleteAnnotationRequest',
    as ArrayRef[DeleteAnnotationRequest()];

coerce 'RepeatedDeleteAnnotationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::DeleteAnnotationRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteAnnotationRequest',
    as HashRef[DeleteAnnotationRequest()];

declare 'ImportAssetsRequest',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::ImportAssetsRequest'];

coerce 'ImportAssetsRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::ImportAssetsRequest'->new($_) };

declare 'RepeatedImportAssetsRequest',
    as ArrayRef[ImportAssetsRequest()];

coerce 'RepeatedImportAssetsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::ImportAssetsRequest'->new($_) } @$_ ] };

declare 'MapStringImportAssetsRequest',
    as HashRef[ImportAssetsRequest()];

declare 'ImportAssetsMetadata',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::ImportAssetsMetadata'];

coerce 'ImportAssetsMetadata',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::ImportAssetsMetadata'->new($_) };

declare 'RepeatedImportAssetsMetadata',
    as ArrayRef[ImportAssetsMetadata()];

coerce 'RepeatedImportAssetsMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::ImportAssetsMetadata'->new($_) } @$_ ] };

declare 'MapStringImportAssetsMetadata',
    as HashRef[ImportAssetsMetadata()];

declare 'BatchOperationStatus',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::BatchOperationStatus'];

coerce 'BatchOperationStatus',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::BatchOperationStatus'->new($_) };

declare 'RepeatedBatchOperationStatus',
    as ArrayRef[BatchOperationStatus()];

coerce 'RepeatedBatchOperationStatus',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::BatchOperationStatus'->new($_) } @$_ ] };

declare 'MapStringBatchOperationStatus',
    as HashRef[BatchOperationStatus()];

declare 'ImportAssetsResponse',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::ImportAssetsResponse'];

coerce 'ImportAssetsResponse',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::ImportAssetsResponse'->new($_) };

declare 'RepeatedImportAssetsResponse',
    as ArrayRef[ImportAssetsResponse()];

coerce 'RepeatedImportAssetsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::ImportAssetsResponse'->new($_) } @$_ ] };

declare 'MapStringImportAssetsResponse',
    as HashRef[ImportAssetsResponse()];

declare 'CreateSearchConfigRequest',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::CreateSearchConfigRequest'];

coerce 'CreateSearchConfigRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::CreateSearchConfigRequest'->new($_) };

declare 'RepeatedCreateSearchConfigRequest',
    as ArrayRef[CreateSearchConfigRequest()];

coerce 'RepeatedCreateSearchConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::CreateSearchConfigRequest'->new($_) } @$_ ] };

declare 'MapStringCreateSearchConfigRequest',
    as HashRef[CreateSearchConfigRequest()];

declare 'UpdateSearchConfigRequest',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::UpdateSearchConfigRequest'];

coerce 'UpdateSearchConfigRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::UpdateSearchConfigRequest'->new($_) };

declare 'RepeatedUpdateSearchConfigRequest',
    as ArrayRef[UpdateSearchConfigRequest()];

coerce 'RepeatedUpdateSearchConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::UpdateSearchConfigRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateSearchConfigRequest',
    as HashRef[UpdateSearchConfigRequest()];

declare 'GetSearchConfigRequest',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::GetSearchConfigRequest'];

coerce 'GetSearchConfigRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::GetSearchConfigRequest'->new($_) };

declare 'RepeatedGetSearchConfigRequest',
    as ArrayRef[GetSearchConfigRequest()];

coerce 'RepeatedGetSearchConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::GetSearchConfigRequest'->new($_) } @$_ ] };

declare 'MapStringGetSearchConfigRequest',
    as HashRef[GetSearchConfigRequest()];

declare 'DeleteSearchConfigRequest',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::DeleteSearchConfigRequest'];

coerce 'DeleteSearchConfigRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::DeleteSearchConfigRequest'->new($_) };

declare 'RepeatedDeleteSearchConfigRequest',
    as ArrayRef[DeleteSearchConfigRequest()];

coerce 'RepeatedDeleteSearchConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::DeleteSearchConfigRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteSearchConfigRequest',
    as HashRef[DeleteSearchConfigRequest()];

declare 'ListSearchConfigsRequest',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::ListSearchConfigsRequest'];

coerce 'ListSearchConfigsRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::ListSearchConfigsRequest'->new($_) };

declare 'RepeatedListSearchConfigsRequest',
    as ArrayRef[ListSearchConfigsRequest()];

coerce 'RepeatedListSearchConfigsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::ListSearchConfigsRequest'->new($_) } @$_ ] };

declare 'MapStringListSearchConfigsRequest',
    as HashRef[ListSearchConfigsRequest()];

declare 'ListSearchConfigsResponse',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::ListSearchConfigsResponse'];

coerce 'ListSearchConfigsResponse',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::ListSearchConfigsResponse'->new($_) };

declare 'RepeatedListSearchConfigsResponse',
    as ArrayRef[ListSearchConfigsResponse()];

coerce 'RepeatedListSearchConfigsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::ListSearchConfigsResponse'->new($_) } @$_ ] };

declare 'MapStringListSearchConfigsResponse',
    as HashRef[ListSearchConfigsResponse()];

declare 'SearchConfig',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::SearchConfig'];

coerce 'SearchConfig',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::SearchConfig'->new($_) };

declare 'RepeatedSearchConfig',
    as ArrayRef[SearchConfig()];

coerce 'RepeatedSearchConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::SearchConfig'->new($_) } @$_ ] };

declare 'MapStringSearchConfig',
    as HashRef[SearchConfig()];

declare 'IndexEndpoint',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::IndexEndpoint'];

coerce 'IndexEndpoint',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::IndexEndpoint'->new($_) };

declare 'RepeatedIndexEndpoint',
    as ArrayRef[IndexEndpoint()];

coerce 'RepeatedIndexEndpoint',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::IndexEndpoint'->new($_) } @$_ ] };

declare 'MapStringIndexEndpoint',
    as HashRef[IndexEndpoint()];

declare 'State',
    as (Int | Str);

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::IndexEndpoint::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::IndexEndpoint::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::IndexEndpoint::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'CreateIndexEndpointRequest',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::CreateIndexEndpointRequest'];

coerce 'CreateIndexEndpointRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::CreateIndexEndpointRequest'->new($_) };

declare 'RepeatedCreateIndexEndpointRequest',
    as ArrayRef[CreateIndexEndpointRequest()];

coerce 'RepeatedCreateIndexEndpointRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::CreateIndexEndpointRequest'->new($_) } @$_ ] };

declare 'MapStringCreateIndexEndpointRequest',
    as HashRef[CreateIndexEndpointRequest()];

declare 'CreateIndexEndpointMetadata',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::CreateIndexEndpointMetadata'];

coerce 'CreateIndexEndpointMetadata',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::CreateIndexEndpointMetadata'->new($_) };

declare 'RepeatedCreateIndexEndpointMetadata',
    as ArrayRef[CreateIndexEndpointMetadata()];

coerce 'RepeatedCreateIndexEndpointMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::CreateIndexEndpointMetadata'->new($_) } @$_ ] };

declare 'MapStringCreateIndexEndpointMetadata',
    as HashRef[CreateIndexEndpointMetadata()];

declare 'GetIndexEndpointRequest',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::GetIndexEndpointRequest'];

coerce 'GetIndexEndpointRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::GetIndexEndpointRequest'->new($_) };

declare 'RepeatedGetIndexEndpointRequest',
    as ArrayRef[GetIndexEndpointRequest()];

coerce 'RepeatedGetIndexEndpointRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::GetIndexEndpointRequest'->new($_) } @$_ ] };

declare 'MapStringGetIndexEndpointRequest',
    as HashRef[GetIndexEndpointRequest()];

declare 'ListIndexEndpointsRequest',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::ListIndexEndpointsRequest'];

coerce 'ListIndexEndpointsRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::ListIndexEndpointsRequest'->new($_) };

declare 'RepeatedListIndexEndpointsRequest',
    as ArrayRef[ListIndexEndpointsRequest()];

coerce 'RepeatedListIndexEndpointsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::ListIndexEndpointsRequest'->new($_) } @$_ ] };

declare 'MapStringListIndexEndpointsRequest',
    as HashRef[ListIndexEndpointsRequest()];

declare 'ListIndexEndpointsResponse',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::ListIndexEndpointsResponse'];

coerce 'ListIndexEndpointsResponse',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::ListIndexEndpointsResponse'->new($_) };

declare 'RepeatedListIndexEndpointsResponse',
    as ArrayRef[ListIndexEndpointsResponse()];

coerce 'RepeatedListIndexEndpointsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::ListIndexEndpointsResponse'->new($_) } @$_ ] };

declare 'MapStringListIndexEndpointsResponse',
    as HashRef[ListIndexEndpointsResponse()];

declare 'UpdateIndexEndpointRequest',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::UpdateIndexEndpointRequest'];

coerce 'UpdateIndexEndpointRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::UpdateIndexEndpointRequest'->new($_) };

declare 'RepeatedUpdateIndexEndpointRequest',
    as ArrayRef[UpdateIndexEndpointRequest()];

coerce 'RepeatedUpdateIndexEndpointRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::UpdateIndexEndpointRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateIndexEndpointRequest',
    as HashRef[UpdateIndexEndpointRequest()];

declare 'UpdateIndexEndpointMetadata',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::UpdateIndexEndpointMetadata'];

coerce 'UpdateIndexEndpointMetadata',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::UpdateIndexEndpointMetadata'->new($_) };

declare 'RepeatedUpdateIndexEndpointMetadata',
    as ArrayRef[UpdateIndexEndpointMetadata()];

coerce 'RepeatedUpdateIndexEndpointMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::UpdateIndexEndpointMetadata'->new($_) } @$_ ] };

declare 'MapStringUpdateIndexEndpointMetadata',
    as HashRef[UpdateIndexEndpointMetadata()];

declare 'DeleteIndexEndpointRequest',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::DeleteIndexEndpointRequest'];

coerce 'DeleteIndexEndpointRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::DeleteIndexEndpointRequest'->new($_) };

declare 'RepeatedDeleteIndexEndpointRequest',
    as ArrayRef[DeleteIndexEndpointRequest()];

coerce 'RepeatedDeleteIndexEndpointRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::DeleteIndexEndpointRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteIndexEndpointRequest',
    as HashRef[DeleteIndexEndpointRequest()];

declare 'DeleteIndexEndpointMetadata',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::DeleteIndexEndpointMetadata'];

coerce 'DeleteIndexEndpointMetadata',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::DeleteIndexEndpointMetadata'->new($_) };

declare 'RepeatedDeleteIndexEndpointMetadata',
    as ArrayRef[DeleteIndexEndpointMetadata()];

coerce 'RepeatedDeleteIndexEndpointMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::DeleteIndexEndpointMetadata'->new($_) } @$_ ] };

declare 'MapStringDeleteIndexEndpointMetadata',
    as HashRef[DeleteIndexEndpointMetadata()];

declare 'DeployIndexRequest',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::DeployIndexRequest'];

coerce 'DeployIndexRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::DeployIndexRequest'->new($_) };

declare 'RepeatedDeployIndexRequest',
    as ArrayRef[DeployIndexRequest()];

coerce 'RepeatedDeployIndexRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::DeployIndexRequest'->new($_) } @$_ ] };

declare 'MapStringDeployIndexRequest',
    as HashRef[DeployIndexRequest()];

declare 'DeployIndexResponse',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::DeployIndexResponse'];

coerce 'DeployIndexResponse',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::DeployIndexResponse'->new($_) };

declare 'RepeatedDeployIndexResponse',
    as ArrayRef[DeployIndexResponse()];

coerce 'RepeatedDeployIndexResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::DeployIndexResponse'->new($_) } @$_ ] };

declare 'MapStringDeployIndexResponse',
    as HashRef[DeployIndexResponse()];

declare 'DeployIndexMetadata',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::DeployIndexMetadata'];

coerce 'DeployIndexMetadata',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::DeployIndexMetadata'->new($_) };

declare 'RepeatedDeployIndexMetadata',
    as ArrayRef[DeployIndexMetadata()];

coerce 'RepeatedDeployIndexMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::DeployIndexMetadata'->new($_) } @$_ ] };

declare 'MapStringDeployIndexMetadata',
    as HashRef[DeployIndexMetadata()];

declare 'UndeployIndexMetadata',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::UndeployIndexMetadata'];

coerce 'UndeployIndexMetadata',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::UndeployIndexMetadata'->new($_) };

declare 'RepeatedUndeployIndexMetadata',
    as ArrayRef[UndeployIndexMetadata()];

coerce 'RepeatedUndeployIndexMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::UndeployIndexMetadata'->new($_) } @$_ ] };

declare 'MapStringUndeployIndexMetadata',
    as HashRef[UndeployIndexMetadata()];

declare 'UndeployIndexRequest',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::UndeployIndexRequest'];

coerce 'UndeployIndexRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::UndeployIndexRequest'->new($_) };

declare 'RepeatedUndeployIndexRequest',
    as ArrayRef[UndeployIndexRequest()];

coerce 'RepeatedUndeployIndexRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::UndeployIndexRequest'->new($_) } @$_ ] };

declare 'MapStringUndeployIndexRequest',
    as HashRef[UndeployIndexRequest()];

declare 'UndeployIndexResponse',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::UndeployIndexResponse'];

coerce 'UndeployIndexResponse',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::UndeployIndexResponse'->new($_) };

declare 'RepeatedUndeployIndexResponse',
    as ArrayRef[UndeployIndexResponse()];

coerce 'RepeatedUndeployIndexResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::UndeployIndexResponse'->new($_) } @$_ ] };

declare 'MapStringUndeployIndexResponse',
    as HashRef[UndeployIndexResponse()];

declare 'DeployedIndex',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::DeployedIndex'];

coerce 'DeployedIndex',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::DeployedIndex'->new($_) };

declare 'RepeatedDeployedIndex',
    as ArrayRef[DeployedIndex()];

coerce 'RepeatedDeployedIndex',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::DeployedIndex'->new($_) } @$_ ] };

declare 'MapStringDeployedIndex',
    as HashRef[DeployedIndex()];

declare 'FacetProperty',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::FacetProperty'];

coerce 'FacetProperty',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::FacetProperty'->new($_) };

declare 'RepeatedFacetProperty',
    as ArrayRef[FacetProperty()];

coerce 'RepeatedFacetProperty',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::FacetProperty'->new($_) } @$_ ] };

declare 'MapStringFacetProperty',
    as HashRef[FacetProperty()];

declare 'FixedRangeBucketSpec',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::FacetProperty::FixedRangeBucketSpec'];

coerce 'FixedRangeBucketSpec',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::FacetProperty::FixedRangeBucketSpec'->new($_) };

declare 'RepeatedFixedRangeBucketSpec',
    as ArrayRef[FixedRangeBucketSpec()];

coerce 'RepeatedFixedRangeBucketSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::FacetProperty::FixedRangeBucketSpec'->new($_) } @$_ ] };

declare 'MapStringFixedRangeBucketSpec',
    as HashRef[FixedRangeBucketSpec()];

declare 'CustomRangeBucketSpec',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::FacetProperty::CustomRangeBucketSpec'];

coerce 'CustomRangeBucketSpec',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::FacetProperty::CustomRangeBucketSpec'->new($_) };

declare 'RepeatedCustomRangeBucketSpec',
    as ArrayRef[CustomRangeBucketSpec()];

coerce 'RepeatedCustomRangeBucketSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::FacetProperty::CustomRangeBucketSpec'->new($_) } @$_ ] };

declare 'MapStringCustomRangeBucketSpec',
    as HashRef[CustomRangeBucketSpec()];

declare 'DateTimeBucketSpec',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::FacetProperty::DateTimeBucketSpec'];

coerce 'DateTimeBucketSpec',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::FacetProperty::DateTimeBucketSpec'->new($_) };

declare 'RepeatedDateTimeBucketSpec',
    as ArrayRef[DateTimeBucketSpec()];

coerce 'RepeatedDateTimeBucketSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::FacetProperty::DateTimeBucketSpec'->new($_) } @$_ ] };

declare 'MapStringDateTimeBucketSpec',
    as HashRef[DateTimeBucketSpec()];

declare 'Granularity',
    as (Int | Str);

declare 'SearchHypernym',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::SearchHypernym'];

coerce 'SearchHypernym',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::SearchHypernym'->new($_) };

declare 'RepeatedSearchHypernym',
    as ArrayRef[SearchHypernym()];

coerce 'RepeatedSearchHypernym',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::SearchHypernym'->new($_) } @$_ ] };

declare 'MapStringSearchHypernym',
    as HashRef[SearchHypernym()];

declare 'CreateSearchHypernymRequest',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::CreateSearchHypernymRequest'];

coerce 'CreateSearchHypernymRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::CreateSearchHypernymRequest'->new($_) };

declare 'RepeatedCreateSearchHypernymRequest',
    as ArrayRef[CreateSearchHypernymRequest()];

coerce 'RepeatedCreateSearchHypernymRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::CreateSearchHypernymRequest'->new($_) } @$_ ] };

declare 'MapStringCreateSearchHypernymRequest',
    as HashRef[CreateSearchHypernymRequest()];

declare 'UpdateSearchHypernymRequest',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::UpdateSearchHypernymRequest'];

coerce 'UpdateSearchHypernymRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::UpdateSearchHypernymRequest'->new($_) };

declare 'RepeatedUpdateSearchHypernymRequest',
    as ArrayRef[UpdateSearchHypernymRequest()];

coerce 'RepeatedUpdateSearchHypernymRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::UpdateSearchHypernymRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateSearchHypernymRequest',
    as HashRef[UpdateSearchHypernymRequest()];

declare 'GetSearchHypernymRequest',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::GetSearchHypernymRequest'];

coerce 'GetSearchHypernymRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::GetSearchHypernymRequest'->new($_) };

declare 'RepeatedGetSearchHypernymRequest',
    as ArrayRef[GetSearchHypernymRequest()];

coerce 'RepeatedGetSearchHypernymRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::GetSearchHypernymRequest'->new($_) } @$_ ] };

declare 'MapStringGetSearchHypernymRequest',
    as HashRef[GetSearchHypernymRequest()];

declare 'DeleteSearchHypernymRequest',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::DeleteSearchHypernymRequest'];

coerce 'DeleteSearchHypernymRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::DeleteSearchHypernymRequest'->new($_) };

declare 'RepeatedDeleteSearchHypernymRequest',
    as ArrayRef[DeleteSearchHypernymRequest()];

coerce 'RepeatedDeleteSearchHypernymRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::DeleteSearchHypernymRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteSearchHypernymRequest',
    as HashRef[DeleteSearchHypernymRequest()];

declare 'ListSearchHypernymsRequest',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::ListSearchHypernymsRequest'];

coerce 'ListSearchHypernymsRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::ListSearchHypernymsRequest'->new($_) };

declare 'RepeatedListSearchHypernymsRequest',
    as ArrayRef[ListSearchHypernymsRequest()];

coerce 'RepeatedListSearchHypernymsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::ListSearchHypernymsRequest'->new($_) } @$_ ] };

declare 'MapStringListSearchHypernymsRequest',
    as HashRef[ListSearchHypernymsRequest()];

declare 'ListSearchHypernymsResponse',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::ListSearchHypernymsResponse'];

coerce 'ListSearchHypernymsResponse',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::ListSearchHypernymsResponse'->new($_) };

declare 'RepeatedListSearchHypernymsResponse',
    as ArrayRef[ListSearchHypernymsResponse()];

coerce 'RepeatedListSearchHypernymsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::ListSearchHypernymsResponse'->new($_) } @$_ ] };

declare 'MapStringListSearchHypernymsResponse',
    as HashRef[ListSearchHypernymsResponse()];

declare 'SearchCriteriaProperty',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::SearchCriteriaProperty'];

coerce 'SearchCriteriaProperty',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::SearchCriteriaProperty'->new($_) };

declare 'RepeatedSearchCriteriaProperty',
    as ArrayRef[SearchCriteriaProperty()];

coerce 'RepeatedSearchCriteriaProperty',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::SearchCriteriaProperty'->new($_) } @$_ ] };

declare 'MapStringSearchCriteriaProperty',
    as HashRef[SearchCriteriaProperty()];

declare 'FacetValue',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::FacetValue'];

coerce 'FacetValue',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::FacetValue'->new($_) };

declare 'RepeatedFacetValue',
    as ArrayRef[FacetValue()];

coerce 'RepeatedFacetValue',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::FacetValue'->new($_) } @$_ ] };

declare 'MapStringFacetValue',
    as HashRef[FacetValue()];

declare 'FacetBucket',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::FacetBucket'];

coerce 'FacetBucket',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::FacetBucket'->new($_) };

declare 'RepeatedFacetBucket',
    as ArrayRef[FacetBucket()];

coerce 'RepeatedFacetBucket',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::FacetBucket'->new($_) } @$_ ] };

declare 'MapStringFacetBucket',
    as HashRef[FacetBucket()];

declare 'Range',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::FacetBucket::Range'];

coerce 'Range',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::FacetBucket::Range'->new($_) };

declare 'RepeatedRange',
    as ArrayRef[Range()];

coerce 'RepeatedRange',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::FacetBucket::Range'->new($_) } @$_ ] };

declare 'MapStringRange',
    as HashRef[Range()];

declare 'FacetGroup',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::FacetGroup'];

coerce 'FacetGroup',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::FacetGroup'->new($_) };

declare 'RepeatedFacetGroup',
    as ArrayRef[FacetGroup()];

coerce 'RepeatedFacetGroup',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::FacetGroup'->new($_) } @$_ ] };

declare 'MapStringFacetGroup',
    as HashRef[FacetGroup()];

declare 'IngestAssetRequest',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::IngestAssetRequest'];

coerce 'IngestAssetRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::IngestAssetRequest'->new($_) };

declare 'RepeatedIngestAssetRequest',
    as ArrayRef[IngestAssetRequest()];

coerce 'RepeatedIngestAssetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::IngestAssetRequest'->new($_) } @$_ ] };

declare 'MapStringIngestAssetRequest',
    as HashRef[IngestAssetRequest()];

declare 'Config',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::IngestAssetRequest::Config'];

coerce 'Config',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::IngestAssetRequest::Config'->new($_) };

declare 'RepeatedConfig',
    as ArrayRef[Config()];

coerce 'RepeatedConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::IngestAssetRequest::Config'->new($_) } @$_ ] };

declare 'MapStringConfig',
    as HashRef[Config()];

declare 'VideoType',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::IngestAssetRequest::Config::VideoType'];

coerce 'VideoType',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::IngestAssetRequest::Config::VideoType'->new($_) };

declare 'RepeatedVideoType',
    as ArrayRef[VideoType()];

coerce 'RepeatedVideoType',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::IngestAssetRequest::Config::VideoType'->new($_) } @$_ ] };

declare 'MapStringVideoType',
    as HashRef[VideoType()];

declare 'ContainerFormat',
    as (Int | Str);

declare 'TimeIndexedData',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::IngestAssetRequest::TimeIndexedData'];

coerce 'TimeIndexedData',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::IngestAssetRequest::TimeIndexedData'->new($_) };

declare 'RepeatedTimeIndexedData',
    as ArrayRef[TimeIndexedData()];

coerce 'RepeatedTimeIndexedData',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::IngestAssetRequest::TimeIndexedData'->new($_) } @$_ ] };

declare 'MapStringTimeIndexedData',
    as HashRef[TimeIndexedData()];

declare 'IngestAssetResponse',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::IngestAssetResponse'];

coerce 'IngestAssetResponse',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::IngestAssetResponse'->new($_) };

declare 'RepeatedIngestAssetResponse',
    as ArrayRef[IngestAssetResponse()];

coerce 'RepeatedIngestAssetResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::IngestAssetResponse'->new($_) } @$_ ] };

declare 'MapStringIngestAssetResponse',
    as HashRef[IngestAssetResponse()];

declare 'ClipAssetRequest',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::ClipAssetRequest'];

coerce 'ClipAssetRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::ClipAssetRequest'->new($_) };

declare 'RepeatedClipAssetRequest',
    as ArrayRef[ClipAssetRequest()];

coerce 'RepeatedClipAssetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::ClipAssetRequest'->new($_) } @$_ ] };

declare 'MapStringClipAssetRequest',
    as HashRef[ClipAssetRequest()];

declare 'ClipAssetResponse',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::ClipAssetResponse'];

coerce 'ClipAssetResponse',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::ClipAssetResponse'->new($_) };

declare 'RepeatedClipAssetResponse',
    as ArrayRef[ClipAssetResponse()];

coerce 'RepeatedClipAssetResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::ClipAssetResponse'->new($_) } @$_ ] };

declare 'MapStringClipAssetResponse',
    as HashRef[ClipAssetResponse()];

declare 'TimeIndexedUri',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::ClipAssetResponse::TimeIndexedUri'];

coerce 'TimeIndexedUri',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::ClipAssetResponse::TimeIndexedUri'->new($_) };

declare 'RepeatedTimeIndexedUri',
    as ArrayRef[TimeIndexedUri()];

coerce 'RepeatedTimeIndexedUri',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::ClipAssetResponse::TimeIndexedUri'->new($_) } @$_ ] };

declare 'MapStringTimeIndexedUri',
    as HashRef[TimeIndexedUri()];

declare 'GenerateHlsUriRequest',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::GenerateHlsUriRequest'];

coerce 'GenerateHlsUriRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::GenerateHlsUriRequest'->new($_) };

declare 'RepeatedGenerateHlsUriRequest',
    as ArrayRef[GenerateHlsUriRequest()];

coerce 'RepeatedGenerateHlsUriRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::GenerateHlsUriRequest'->new($_) } @$_ ] };

declare 'MapStringGenerateHlsUriRequest',
    as HashRef[GenerateHlsUriRequest()];

declare 'GenerateHlsUriResponse',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::GenerateHlsUriResponse'];

coerce 'GenerateHlsUriResponse',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::GenerateHlsUriResponse'->new($_) };

declare 'RepeatedGenerateHlsUriResponse',
    as ArrayRef[GenerateHlsUriResponse()];

coerce 'RepeatedGenerateHlsUriResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::GenerateHlsUriResponse'->new($_) } @$_ ] };

declare 'MapStringGenerateHlsUriResponse',
    as HashRef[GenerateHlsUriResponse()];

declare 'SearchAssetsRequest',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::SearchAssetsRequest'];

coerce 'SearchAssetsRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::SearchAssetsRequest'->new($_) };

declare 'RepeatedSearchAssetsRequest',
    as ArrayRef[SearchAssetsRequest()];

coerce 'RepeatedSearchAssetsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::SearchAssetsRequest'->new($_) } @$_ ] };

declare 'MapStringSearchAssetsRequest',
    as HashRef[SearchAssetsRequest()];

declare 'SearchIndexEndpointRequest',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::SearchIndexEndpointRequest'];

coerce 'SearchIndexEndpointRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::SearchIndexEndpointRequest'->new($_) };

declare 'RepeatedSearchIndexEndpointRequest',
    as ArrayRef[SearchIndexEndpointRequest()];

coerce 'RepeatedSearchIndexEndpointRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::SearchIndexEndpointRequest'->new($_) } @$_ ] };

declare 'MapStringSearchIndexEndpointRequest',
    as HashRef[SearchIndexEndpointRequest()];

declare 'ImageQuery',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::ImageQuery'];

coerce 'ImageQuery',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::ImageQuery'->new($_) };

declare 'RepeatedImageQuery',
    as ArrayRef[ImageQuery()];

coerce 'RepeatedImageQuery',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::ImageQuery'->new($_) } @$_ ] };

declare 'MapStringImageQuery',
    as HashRef[ImageQuery()];

declare 'SchemaKeySortingStrategy',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::SchemaKeySortingStrategy'];

coerce 'SchemaKeySortingStrategy',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::SchemaKeySortingStrategy'->new($_) };

declare 'RepeatedSchemaKeySortingStrategy',
    as ArrayRef[SchemaKeySortingStrategy()];

coerce 'RepeatedSchemaKeySortingStrategy',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::SchemaKeySortingStrategy'->new($_) } @$_ ] };

declare 'MapStringSchemaKeySortingStrategy',
    as HashRef[SchemaKeySortingStrategy()];

declare 'Option',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::SchemaKeySortingStrategy::Option'];

coerce 'Option',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::SchemaKeySortingStrategy::Option'->new($_) };

declare 'RepeatedOption',
    as ArrayRef[Option()];

coerce 'RepeatedOption',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::SchemaKeySortingStrategy::Option'->new($_) } @$_ ] };

declare 'MapStringOption',
    as HashRef[Option()];

declare 'AggregateMethod',
    as (Int | Str);

declare 'DeleteAssetMetadata',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::DeleteAssetMetadata'];

coerce 'DeleteAssetMetadata',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::DeleteAssetMetadata'->new($_) };

declare 'RepeatedDeleteAssetMetadata',
    as ArrayRef[DeleteAssetMetadata()];

coerce 'RepeatedDeleteAssetMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::DeleteAssetMetadata'->new($_) } @$_ ] };

declare 'MapStringDeleteAssetMetadata',
    as HashRef[DeleteAssetMetadata()];

declare 'AnnotationMatchingResult',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::AnnotationMatchingResult'];

coerce 'AnnotationMatchingResult',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::AnnotationMatchingResult'->new($_) };

declare 'RepeatedAnnotationMatchingResult',
    as ArrayRef[AnnotationMatchingResult()];

coerce 'RepeatedAnnotationMatchingResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::AnnotationMatchingResult'->new($_) } @$_ ] };

declare 'MapStringAnnotationMatchingResult',
    as HashRef[AnnotationMatchingResult()];

declare 'SearchResultItem',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::SearchResultItem'];

coerce 'SearchResultItem',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::SearchResultItem'->new($_) };

declare 'RepeatedSearchResultItem',
    as ArrayRef[SearchResultItem()];

coerce 'RepeatedSearchResultItem',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::SearchResultItem'->new($_) } @$_ ] };

declare 'MapStringSearchResultItem',
    as HashRef[SearchResultItem()];

declare 'SearchAssetsResponse',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::SearchAssetsResponse'];

coerce 'SearchAssetsResponse',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::SearchAssetsResponse'->new($_) };

declare 'RepeatedSearchAssetsResponse',
    as ArrayRef[SearchAssetsResponse()];

coerce 'RepeatedSearchAssetsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::SearchAssetsResponse'->new($_) } @$_ ] };

declare 'MapStringSearchAssetsResponse',
    as HashRef[SearchAssetsResponse()];

declare 'SearchIndexEndpointResponse',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::SearchIndexEndpointResponse'];

coerce 'SearchIndexEndpointResponse',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::SearchIndexEndpointResponse'->new($_) };

declare 'RepeatedSearchIndexEndpointResponse',
    as ArrayRef[SearchIndexEndpointResponse()];

coerce 'RepeatedSearchIndexEndpointResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::SearchIndexEndpointResponse'->new($_) } @$_ ] };

declare 'MapStringSearchIndexEndpointResponse',
    as HashRef[SearchIndexEndpointResponse()];

declare 'IntRange',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::IntRange'];

coerce 'IntRange',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::IntRange'->new($_) };

declare 'RepeatedIntRange',
    as ArrayRef[IntRange()];

coerce 'RepeatedIntRange',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::IntRange'->new($_) } @$_ ] };

declare 'MapStringIntRange',
    as HashRef[IntRange()];

declare 'FloatRange',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::FloatRange'];

coerce 'FloatRange',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::FloatRange'->new($_) };

declare 'RepeatedFloatRange',
    as ArrayRef[FloatRange()];

coerce 'RepeatedFloatRange',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::FloatRange'->new($_) } @$_ ] };

declare 'MapStringFloatRange',
    as HashRef[FloatRange()];

declare 'StringArray',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::StringArray'];

coerce 'StringArray',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::StringArray'->new($_) };

declare 'RepeatedStringArray',
    as ArrayRef[StringArray()];

coerce 'RepeatedStringArray',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::StringArray'->new($_) } @$_ ] };

declare 'MapStringStringArray',
    as HashRef[StringArray()];

declare 'IntRangeArray',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::IntRangeArray'];

coerce 'IntRangeArray',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::IntRangeArray'->new($_) };

declare 'RepeatedIntRangeArray',
    as ArrayRef[IntRangeArray()];

coerce 'RepeatedIntRangeArray',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::IntRangeArray'->new($_) } @$_ ] };

declare 'MapStringIntRangeArray',
    as HashRef[IntRangeArray()];

declare 'FloatRangeArray',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::FloatRangeArray'];

coerce 'FloatRangeArray',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::FloatRangeArray'->new($_) };

declare 'RepeatedFloatRangeArray',
    as ArrayRef[FloatRangeArray()];

coerce 'RepeatedFloatRangeArray',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::FloatRangeArray'->new($_) } @$_ ] };

declare 'MapStringFloatRangeArray',
    as HashRef[FloatRangeArray()];

declare 'DateTimeRange',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::DateTimeRange'];

coerce 'DateTimeRange',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::DateTimeRange'->new($_) };

declare 'RepeatedDateTimeRange',
    as ArrayRef[DateTimeRange()];

coerce 'RepeatedDateTimeRange',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::DateTimeRange'->new($_) } @$_ ] };

declare 'MapStringDateTimeRange',
    as HashRef[DateTimeRange()];

declare 'DateTimeRangeArray',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::DateTimeRangeArray'];

coerce 'DateTimeRangeArray',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::DateTimeRangeArray'->new($_) };

declare 'RepeatedDateTimeRangeArray',
    as ArrayRef[DateTimeRangeArray()];

coerce 'RepeatedDateTimeRangeArray',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::DateTimeRangeArray'->new($_) } @$_ ] };

declare 'MapStringDateTimeRangeArray',
    as HashRef[DateTimeRangeArray()];

declare 'CircleArea',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::CircleArea'];

coerce 'CircleArea',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::CircleArea'->new($_) };

declare 'RepeatedCircleArea',
    as ArrayRef[CircleArea()];

coerce 'RepeatedCircleArea',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::CircleArea'->new($_) } @$_ ] };

declare 'MapStringCircleArea',
    as HashRef[CircleArea()];

declare 'GeoLocationArray',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::GeoLocationArray'];

coerce 'GeoLocationArray',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::GeoLocationArray'->new($_) };

declare 'RepeatedGeoLocationArray',
    as ArrayRef[GeoLocationArray()];

coerce 'RepeatedGeoLocationArray',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::GeoLocationArray'->new($_) } @$_ ] };

declare 'MapStringGeoLocationArray',
    as HashRef[GeoLocationArray()];

declare 'BoolValue',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::BoolValue'];

coerce 'BoolValue',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::BoolValue'->new($_) };

declare 'RepeatedBoolValue',
    as ArrayRef[BoolValue()];

coerce 'RepeatedBoolValue',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::BoolValue'->new($_) } @$_ ] };

declare 'MapStringBoolValue',
    as HashRef[BoolValue()];

declare 'Criteria',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::Criteria'];

coerce 'Criteria',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::Criteria'->new($_) };

declare 'RepeatedCriteria',
    as ArrayRef[Criteria()];

coerce 'RepeatedCriteria',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::Criteria'->new($_) } @$_ ] };

declare 'MapStringCriteria',
    as HashRef[Criteria()];

declare 'Partition',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::Partition'];

coerce 'Partition',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::Partition'->new($_) };

declare 'RepeatedPartition',
    as ArrayRef[Partition()];

coerce 'RepeatedPartition',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::Partition'->new($_) } @$_ ] };

declare 'MapStringPartition',
    as HashRef[Partition()];

declare 'TemporalPartition',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::Partition::TemporalPartition'];

coerce 'TemporalPartition',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::Partition::TemporalPartition'->new($_) };

declare 'RepeatedTemporalPartition',
    as ArrayRef[TemporalPartition()];

coerce 'RepeatedTemporalPartition',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::Partition::TemporalPartition'->new($_) } @$_ ] };

declare 'MapStringTemporalPartition',
    as HashRef[TemporalPartition()];

declare 'SpatialPartition',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::Partition::SpatialPartition'];

coerce 'SpatialPartition',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::Partition::SpatialPartition'->new($_) };

declare 'RepeatedSpatialPartition',
    as ArrayRef[SpatialPartition()];

coerce 'RepeatedSpatialPartition',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::Partition::SpatialPartition'->new($_) } @$_ ] };

declare 'MapStringSpatialPartition',
    as HashRef[SpatialPartition()];

declare 'RelativeTemporalPartition',
    as InstanceOf['Google::Cloud::Visionai::V1::Warehouse::Partition::RelativeTemporalPartition'];

coerce 'RelativeTemporalPartition',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Warehouse::Partition::RelativeTemporalPartition'->new($_) };

declare 'RepeatedRelativeTemporalPartition',
    as ArrayRef[RelativeTemporalPartition()];

coerce 'RepeatedRelativeTemporalPartition',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Warehouse::Partition::RelativeTemporalPartition'->new($_) } @$_ ] };

declare 'MapStringRelativeTemporalPartition',
    as HashRef[RelativeTemporalPartition()];

1;

__END__

=head1 NAME

Google::Cloud::Visionai::V1::Warehouse::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
