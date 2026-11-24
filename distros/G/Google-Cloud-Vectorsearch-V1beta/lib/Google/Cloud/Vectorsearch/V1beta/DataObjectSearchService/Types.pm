package Google::Cloud::Vectorsearch::V1beta::DataObjectSearchService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'AggregationMethod',
    as (Int | Str);

declare 'OutputFields',
    as InstanceOf['Google::Cloud::Vectorsearch::V1beta::DataObjectSearchService::OutputFields'];

coerce 'OutputFields',
    from HashRef, via { 'Google::Cloud::Vectorsearch::V1beta::DataObjectSearchService::OutputFields'->new($_) };

declare 'RepeatedOutputFields',
    as ArrayRef[OutputFields()];

coerce 'RepeatedOutputFields',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vectorsearch::V1beta::DataObjectSearchService::OutputFields'->new($_) } @$_ ] };

declare 'MapStringOutputFields',
    as HashRef[OutputFields()];

declare 'SearchHint',
    as InstanceOf['Google::Cloud::Vectorsearch::V1beta::DataObjectSearchService::SearchHint'];

coerce 'SearchHint',
    from HashRef, via { 'Google::Cloud::Vectorsearch::V1beta::DataObjectSearchService::SearchHint'->new($_) };

declare 'RepeatedSearchHint',
    as ArrayRef[SearchHint()];

coerce 'RepeatedSearchHint',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vectorsearch::V1beta::DataObjectSearchService::SearchHint'->new($_) } @$_ ] };

declare 'MapStringSearchHint',
    as HashRef[SearchHint()];

declare 'IndexHint',
    as InstanceOf['Google::Cloud::Vectorsearch::V1beta::DataObjectSearchService::SearchHint::IndexHint'];

coerce 'IndexHint',
    from HashRef, via { 'Google::Cloud::Vectorsearch::V1beta::DataObjectSearchService::SearchHint::IndexHint'->new($_) };

declare 'RepeatedIndexHint',
    as ArrayRef[IndexHint()];

coerce 'RepeatedIndexHint',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vectorsearch::V1beta::DataObjectSearchService::SearchHint::IndexHint'->new($_) } @$_ ] };

declare 'MapStringIndexHint',
    as HashRef[IndexHint()];

declare 'DenseScannParams',
    as InstanceOf['Google::Cloud::Vectorsearch::V1beta::DataObjectSearchService::SearchHint::IndexHint::DenseScannParams'];

coerce 'DenseScannParams',
    from HashRef, via { 'Google::Cloud::Vectorsearch::V1beta::DataObjectSearchService::SearchHint::IndexHint::DenseScannParams'->new($_) };

declare 'RepeatedDenseScannParams',
    as ArrayRef[DenseScannParams()];

coerce 'RepeatedDenseScannParams',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vectorsearch::V1beta::DataObjectSearchService::SearchHint::IndexHint::DenseScannParams'->new($_) } @$_ ] };

declare 'MapStringDenseScannParams',
    as HashRef[DenseScannParams()];

declare 'KnnHint',
    as InstanceOf['Google::Cloud::Vectorsearch::V1beta::DataObjectSearchService::SearchHint::KnnHint'];

coerce 'KnnHint',
    from HashRef, via { 'Google::Cloud::Vectorsearch::V1beta::DataObjectSearchService::SearchHint::KnnHint'->new($_) };

declare 'RepeatedKnnHint',
    as ArrayRef[KnnHint()];

coerce 'RepeatedKnnHint',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vectorsearch::V1beta::DataObjectSearchService::SearchHint::KnnHint'->new($_) } @$_ ] };

declare 'MapStringKnnHint',
    as HashRef[KnnHint()];

declare 'Search',
    as InstanceOf['Google::Cloud::Vectorsearch::V1beta::DataObjectSearchService::Search'];

coerce 'Search',
    from HashRef, via { 'Google::Cloud::Vectorsearch::V1beta::DataObjectSearchService::Search'->new($_) };

declare 'RepeatedSearch',
    as ArrayRef[Search()];

coerce 'RepeatedSearch',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vectorsearch::V1beta::DataObjectSearchService::Search'->new($_) } @$_ ] };

declare 'MapStringSearch',
    as HashRef[Search()];

declare 'VectorSearch',
    as InstanceOf['Google::Cloud::Vectorsearch::V1beta::DataObjectSearchService::VectorSearch'];

coerce 'VectorSearch',
    from HashRef, via { 'Google::Cloud::Vectorsearch::V1beta::DataObjectSearchService::VectorSearch'->new($_) };

declare 'RepeatedVectorSearch',
    as ArrayRef[VectorSearch()];

coerce 'RepeatedVectorSearch',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vectorsearch::V1beta::DataObjectSearchService::VectorSearch'->new($_) } @$_ ] };

declare 'MapStringVectorSearch',
    as HashRef[VectorSearch()];

declare 'SemanticSearch',
    as InstanceOf['Google::Cloud::Vectorsearch::V1beta::DataObjectSearchService::SemanticSearch'];

coerce 'SemanticSearch',
    from HashRef, via { 'Google::Cloud::Vectorsearch::V1beta::DataObjectSearchService::SemanticSearch'->new($_) };

declare 'RepeatedSemanticSearch',
    as ArrayRef[SemanticSearch()];

coerce 'RepeatedSemanticSearch',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vectorsearch::V1beta::DataObjectSearchService::SemanticSearch'->new($_) } @$_ ] };

declare 'MapStringSemanticSearch',
    as HashRef[SemanticSearch()];

declare 'TextSearch',
    as InstanceOf['Google::Cloud::Vectorsearch::V1beta::DataObjectSearchService::TextSearch'];

coerce 'TextSearch',
    from HashRef, via { 'Google::Cloud::Vectorsearch::V1beta::DataObjectSearchService::TextSearch'->new($_) };

declare 'RepeatedTextSearch',
    as ArrayRef[TextSearch()];

coerce 'RepeatedTextSearch',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vectorsearch::V1beta::DataObjectSearchService::TextSearch'->new($_) } @$_ ] };

declare 'MapStringTextSearch',
    as HashRef[TextSearch()];

declare 'StructuredQuery',
    as InstanceOf['Google::Cloud::Vectorsearch::V1beta::DataObjectSearchService::StructuredQuery'];

coerce 'StructuredQuery',
    from HashRef, via { 'Google::Cloud::Vectorsearch::V1beta::DataObjectSearchService::StructuredQuery'->new($_) };

declare 'RepeatedStructuredQuery',
    as ArrayRef[StructuredQuery()];

coerce 'RepeatedStructuredQuery',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vectorsearch::V1beta::DataObjectSearchService::StructuredQuery'->new($_) } @$_ ] };

declare 'MapStringStructuredQuery',
    as HashRef[StructuredQuery()];

declare 'TextQuery',
    as InstanceOf['Google::Cloud::Vectorsearch::V1beta::DataObjectSearchService::TextQuery'];

coerce 'TextQuery',
    from HashRef, via { 'Google::Cloud::Vectorsearch::V1beta::DataObjectSearchService::TextQuery'->new($_) };

declare 'RepeatedTextQuery',
    as ArrayRef[TextQuery()];

coerce 'RepeatedTextQuery',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vectorsearch::V1beta::DataObjectSearchService::TextQuery'->new($_) } @$_ ] };

declare 'MapStringTextQuery',
    as HashRef[TextQuery()];

declare 'MatchType',
    as (Int | Str);

declare 'QueryEnhancement',
    as InstanceOf['Google::Cloud::Vectorsearch::V1beta::DataObjectSearchService::QueryEnhancement'];

coerce 'QueryEnhancement',
    from HashRef, via { 'Google::Cloud::Vectorsearch::V1beta::DataObjectSearchService::QueryEnhancement'->new($_) };

declare 'RepeatedQueryEnhancement',
    as ArrayRef[QueryEnhancement()];

coerce 'RepeatedQueryEnhancement',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vectorsearch::V1beta::DataObjectSearchService::QueryEnhancement'->new($_) } @$_ ] };

declare 'MapStringQueryEnhancement',
    as HashRef[QueryEnhancement()];

declare 'UnaryQuery',
    as InstanceOf['Google::Cloud::Vectorsearch::V1beta::DataObjectSearchService::UnaryQuery'];

coerce 'UnaryQuery',
    from HashRef, via { 'Google::Cloud::Vectorsearch::V1beta::DataObjectSearchService::UnaryQuery'->new($_) };

declare 'RepeatedUnaryQuery',
    as ArrayRef[UnaryQuery()];

coerce 'RepeatedUnaryQuery',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vectorsearch::V1beta::DataObjectSearchService::UnaryQuery'->new($_) } @$_ ] };

declare 'MapStringUnaryQuery',
    as HashRef[UnaryQuery()];

declare 'Operator',
    as (Int | Str);

declare 'CombinedQuery',
    as InstanceOf['Google::Cloud::Vectorsearch::V1beta::DataObjectSearchService::CombinedQuery'];

coerce 'CombinedQuery',
    from HashRef, via { 'Google::Cloud::Vectorsearch::V1beta::DataObjectSearchService::CombinedQuery'->new($_) };

declare 'RepeatedCombinedQuery',
    as ArrayRef[CombinedQuery()];

coerce 'RepeatedCombinedQuery',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vectorsearch::V1beta::DataObjectSearchService::CombinedQuery'->new($_) } @$_ ] };

declare 'MapStringCombinedQuery',
    as HashRef[CombinedQuery()];

declare 'Operator',
    as (Int | Str);

declare 'SearchDataObjectsRequest',
    as InstanceOf['Google::Cloud::Vectorsearch::V1beta::DataObjectSearchService::SearchDataObjectsRequest'];

coerce 'SearchDataObjectsRequest',
    from HashRef, via { 'Google::Cloud::Vectorsearch::V1beta::DataObjectSearchService::SearchDataObjectsRequest'->new($_) };

declare 'RepeatedSearchDataObjectsRequest',
    as ArrayRef[SearchDataObjectsRequest()];

coerce 'RepeatedSearchDataObjectsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vectorsearch::V1beta::DataObjectSearchService::SearchDataObjectsRequest'->new($_) } @$_ ] };

declare 'MapStringSearchDataObjectsRequest',
    as HashRef[SearchDataObjectsRequest()];

declare 'SearchResult',
    as InstanceOf['Google::Cloud::Vectorsearch::V1beta::DataObjectSearchService::SearchResult'];

coerce 'SearchResult',
    from HashRef, via { 'Google::Cloud::Vectorsearch::V1beta::DataObjectSearchService::SearchResult'->new($_) };

declare 'RepeatedSearchResult',
    as ArrayRef[SearchResult()];

coerce 'RepeatedSearchResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vectorsearch::V1beta::DataObjectSearchService::SearchResult'->new($_) } @$_ ] };

declare 'MapStringSearchResult',
    as HashRef[SearchResult()];

declare 'SearchResultMetadata',
    as InstanceOf['Google::Cloud::Vectorsearch::V1beta::DataObjectSearchService::SearchResult::SearchResultMetadata'];

coerce 'SearchResultMetadata',
    from HashRef, via { 'Google::Cloud::Vectorsearch::V1beta::DataObjectSearchService::SearchResult::SearchResultMetadata'->new($_) };

declare 'RepeatedSearchResultMetadata',
    as ArrayRef[SearchResultMetadata()];

coerce 'RepeatedSearchResultMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vectorsearch::V1beta::DataObjectSearchService::SearchResult::SearchResultMetadata'->new($_) } @$_ ] };

declare 'MapStringSearchResultMetadata',
    as HashRef[SearchResultMetadata()];

declare 'SearchDistance',
    as InstanceOf['Google::Cloud::Vectorsearch::V1beta::DataObjectSearchService::SearchResult::SearchResultMetadata::SearchDistance'];

coerce 'SearchDistance',
    from HashRef, via { 'Google::Cloud::Vectorsearch::V1beta::DataObjectSearchService::SearchResult::SearchResultMetadata::SearchDistance'->new($_) };

declare 'RepeatedSearchDistance',
    as ArrayRef[SearchDistance()];

coerce 'RepeatedSearchDistance',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vectorsearch::V1beta::DataObjectSearchService::SearchResult::SearchResultMetadata::SearchDistance'->new($_) } @$_ ] };

declare 'MapStringSearchDistance',
    as HashRef[SearchDistance()];

declare 'RrfRankerResult',
    as InstanceOf['Google::Cloud::Vectorsearch::V1beta::DataObjectSearchService::SearchResult::SearchResultMetadata::RrfRankerResult'];

coerce 'RrfRankerResult',
    from HashRef, via { 'Google::Cloud::Vectorsearch::V1beta::DataObjectSearchService::SearchResult::SearchResultMetadata::RrfRankerResult'->new($_) };

declare 'RepeatedRrfRankerResult',
    as ArrayRef[RrfRankerResult()];

coerce 'RepeatedRrfRankerResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vectorsearch::V1beta::DataObjectSearchService::SearchResult::SearchResultMetadata::RrfRankerResult'->new($_) } @$_ ] };

declare 'MapStringRrfRankerResult',
    as HashRef[RrfRankerResult()];

declare 'VertexRankerResult',
    as InstanceOf['Google::Cloud::Vectorsearch::V1beta::DataObjectSearchService::SearchResult::SearchResultMetadata::VertexRankerResult'];

coerce 'VertexRankerResult',
    from HashRef, via { 'Google::Cloud::Vectorsearch::V1beta::DataObjectSearchService::SearchResult::SearchResultMetadata::VertexRankerResult'->new($_) };

declare 'RepeatedVertexRankerResult',
    as ArrayRef[VertexRankerResult()];

coerce 'RepeatedVertexRankerResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vectorsearch::V1beta::DataObjectSearchService::SearchResult::SearchResultMetadata::VertexRankerResult'->new($_) } @$_ ] };

declare 'MapStringVertexRankerResult',
    as HashRef[VertexRankerResult()];

declare 'SearchResponseMetadata',
    as InstanceOf['Google::Cloud::Vectorsearch::V1beta::DataObjectSearchService::SearchResponseMetadata'];

coerce 'SearchResponseMetadata',
    from HashRef, via { 'Google::Cloud::Vectorsearch::V1beta::DataObjectSearchService::SearchResponseMetadata'->new($_) };

declare 'RepeatedSearchResponseMetadata',
    as ArrayRef[SearchResponseMetadata()];

coerce 'RepeatedSearchResponseMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vectorsearch::V1beta::DataObjectSearchService::SearchResponseMetadata'->new($_) } @$_ ] };

declare 'MapStringSearchResponseMetadata',
    as HashRef[SearchResponseMetadata()];

declare 'IndexInfo',
    as InstanceOf['Google::Cloud::Vectorsearch::V1beta::DataObjectSearchService::SearchResponseMetadata::IndexInfo'];

coerce 'IndexInfo',
    from HashRef, via { 'Google::Cloud::Vectorsearch::V1beta::DataObjectSearchService::SearchResponseMetadata::IndexInfo'->new($_) };

declare 'RepeatedIndexInfo',
    as ArrayRef[IndexInfo()];

coerce 'RepeatedIndexInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vectorsearch::V1beta::DataObjectSearchService::SearchResponseMetadata::IndexInfo'->new($_) } @$_ ] };

declare 'MapStringIndexInfo',
    as HashRef[IndexInfo()];

declare 'SearchDataObjectsResponse',
    as InstanceOf['Google::Cloud::Vectorsearch::V1beta::DataObjectSearchService::SearchDataObjectsResponse'];

coerce 'SearchDataObjectsResponse',
    from HashRef, via { 'Google::Cloud::Vectorsearch::V1beta::DataObjectSearchService::SearchDataObjectsResponse'->new($_) };

declare 'RepeatedSearchDataObjectsResponse',
    as ArrayRef[SearchDataObjectsResponse()];

coerce 'RepeatedSearchDataObjectsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vectorsearch::V1beta::DataObjectSearchService::SearchDataObjectsResponse'->new($_) } @$_ ] };

declare 'MapStringSearchDataObjectsResponse',
    as HashRef[SearchDataObjectsResponse()];

declare 'AggregateDataObjectsRequest',
    as InstanceOf['Google::Cloud::Vectorsearch::V1beta::DataObjectSearchService::AggregateDataObjectsRequest'];

coerce 'AggregateDataObjectsRequest',
    from HashRef, via { 'Google::Cloud::Vectorsearch::V1beta::DataObjectSearchService::AggregateDataObjectsRequest'->new($_) };

declare 'RepeatedAggregateDataObjectsRequest',
    as ArrayRef[AggregateDataObjectsRequest()];

coerce 'RepeatedAggregateDataObjectsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vectorsearch::V1beta::DataObjectSearchService::AggregateDataObjectsRequest'->new($_) } @$_ ] };

declare 'MapStringAggregateDataObjectsRequest',
    as HashRef[AggregateDataObjectsRequest()];

declare 'AggregateDataObjectsResponse',
    as InstanceOf['Google::Cloud::Vectorsearch::V1beta::DataObjectSearchService::AggregateDataObjectsResponse'];

coerce 'AggregateDataObjectsResponse',
    from HashRef, via { 'Google::Cloud::Vectorsearch::V1beta::DataObjectSearchService::AggregateDataObjectsResponse'->new($_) };

declare 'RepeatedAggregateDataObjectsResponse',
    as ArrayRef[AggregateDataObjectsResponse()];

coerce 'RepeatedAggregateDataObjectsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vectorsearch::V1beta::DataObjectSearchService::AggregateDataObjectsResponse'->new($_) } @$_ ] };

declare 'MapStringAggregateDataObjectsResponse',
    as HashRef[AggregateDataObjectsResponse()];

declare 'QueryDataObjectsRequest',
    as InstanceOf['Google::Cloud::Vectorsearch::V1beta::DataObjectSearchService::QueryDataObjectsRequest'];

coerce 'QueryDataObjectsRequest',
    from HashRef, via { 'Google::Cloud::Vectorsearch::V1beta::DataObjectSearchService::QueryDataObjectsRequest'->new($_) };

declare 'RepeatedQueryDataObjectsRequest',
    as ArrayRef[QueryDataObjectsRequest()];

coerce 'RepeatedQueryDataObjectsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vectorsearch::V1beta::DataObjectSearchService::QueryDataObjectsRequest'->new($_) } @$_ ] };

declare 'MapStringQueryDataObjectsRequest',
    as HashRef[QueryDataObjectsRequest()];

declare 'QueryDataObjectsResponse',
    as InstanceOf['Google::Cloud::Vectorsearch::V1beta::DataObjectSearchService::QueryDataObjectsResponse'];

coerce 'QueryDataObjectsResponse',
    from HashRef, via { 'Google::Cloud::Vectorsearch::V1beta::DataObjectSearchService::QueryDataObjectsResponse'->new($_) };

declare 'RepeatedQueryDataObjectsResponse',
    as ArrayRef[QueryDataObjectsResponse()];

coerce 'RepeatedQueryDataObjectsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vectorsearch::V1beta::DataObjectSearchService::QueryDataObjectsResponse'->new($_) } @$_ ] };

declare 'MapStringQueryDataObjectsResponse',
    as HashRef[QueryDataObjectsResponse()];

declare 'BatchSearchDataObjectsRequest',
    as InstanceOf['Google::Cloud::Vectorsearch::V1beta::DataObjectSearchService::BatchSearchDataObjectsRequest'];

coerce 'BatchSearchDataObjectsRequest',
    from HashRef, via { 'Google::Cloud::Vectorsearch::V1beta::DataObjectSearchService::BatchSearchDataObjectsRequest'->new($_) };

declare 'RepeatedBatchSearchDataObjectsRequest',
    as ArrayRef[BatchSearchDataObjectsRequest()];

coerce 'RepeatedBatchSearchDataObjectsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vectorsearch::V1beta::DataObjectSearchService::BatchSearchDataObjectsRequest'->new($_) } @$_ ] };

declare 'MapStringBatchSearchDataObjectsRequest',
    as HashRef[BatchSearchDataObjectsRequest()];

declare 'CombineResultsOptions',
    as InstanceOf['Google::Cloud::Vectorsearch::V1beta::DataObjectSearchService::BatchSearchDataObjectsRequest::CombineResultsOptions'];

coerce 'CombineResultsOptions',
    from HashRef, via { 'Google::Cloud::Vectorsearch::V1beta::DataObjectSearchService::BatchSearchDataObjectsRequest::CombineResultsOptions'->new($_) };

declare 'RepeatedCombineResultsOptions',
    as ArrayRef[CombineResultsOptions()];

coerce 'RepeatedCombineResultsOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vectorsearch::V1beta::DataObjectSearchService::BatchSearchDataObjectsRequest::CombineResultsOptions'->new($_) } @$_ ] };

declare 'MapStringCombineResultsOptions',
    as HashRef[CombineResultsOptions()];

declare 'BatchSearchMetadataOptions',
    as InstanceOf['Google::Cloud::Vectorsearch::V1beta::DataObjectSearchService::BatchSearchDataObjectsRequest::BatchSearchMetadataOptions'];

coerce 'BatchSearchMetadataOptions',
    from HashRef, via { 'Google::Cloud::Vectorsearch::V1beta::DataObjectSearchService::BatchSearchDataObjectsRequest::BatchSearchMetadataOptions'->new($_) };

declare 'RepeatedBatchSearchMetadataOptions',
    as ArrayRef[BatchSearchMetadataOptions()];

coerce 'RepeatedBatchSearchMetadataOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vectorsearch::V1beta::DataObjectSearchService::BatchSearchDataObjectsRequest::BatchSearchMetadataOptions'->new($_) } @$_ ] };

declare 'MapStringBatchSearchMetadataOptions',
    as HashRef[BatchSearchMetadataOptions()];

declare 'Ranker',
    as InstanceOf['Google::Cloud::Vectorsearch::V1beta::DataObjectSearchService::Ranker'];

coerce 'Ranker',
    from HashRef, via { 'Google::Cloud::Vectorsearch::V1beta::DataObjectSearchService::Ranker'->new($_) };

declare 'RepeatedRanker',
    as ArrayRef[Ranker()];

coerce 'RepeatedRanker',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vectorsearch::V1beta::DataObjectSearchService::Ranker'->new($_) } @$_ ] };

declare 'MapStringRanker',
    as HashRef[Ranker()];

declare 'ReciprocalRankFusion',
    as InstanceOf['Google::Cloud::Vectorsearch::V1beta::DataObjectSearchService::ReciprocalRankFusion'];

coerce 'ReciprocalRankFusion',
    from HashRef, via { 'Google::Cloud::Vectorsearch::V1beta::DataObjectSearchService::ReciprocalRankFusion'->new($_) };

declare 'RepeatedReciprocalRankFusion',
    as ArrayRef[ReciprocalRankFusion()];

coerce 'RepeatedReciprocalRankFusion',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vectorsearch::V1beta::DataObjectSearchService::ReciprocalRankFusion'->new($_) } @$_ ] };

declare 'MapStringReciprocalRankFusion',
    as HashRef[ReciprocalRankFusion()];

declare 'VertexRanker',
    as InstanceOf['Google::Cloud::Vectorsearch::V1beta::DataObjectSearchService::VertexRanker'];

coerce 'VertexRanker',
    from HashRef, via { 'Google::Cloud::Vectorsearch::V1beta::DataObjectSearchService::VertexRanker'->new($_) };

declare 'RepeatedVertexRanker',
    as ArrayRef[VertexRanker()];

coerce 'RepeatedVertexRanker',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vectorsearch::V1beta::DataObjectSearchService::VertexRanker'->new($_) } @$_ ] };

declare 'MapStringVertexRanker',
    as HashRef[VertexRanker()];

declare 'TextRecordSpec',
    as InstanceOf['Google::Cloud::Vectorsearch::V1beta::DataObjectSearchService::VertexRanker::TextRecordSpec'];

coerce 'TextRecordSpec',
    from HashRef, via { 'Google::Cloud::Vectorsearch::V1beta::DataObjectSearchService::VertexRanker::TextRecordSpec'->new($_) };

declare 'RepeatedTextRecordSpec',
    as ArrayRef[TextRecordSpec()];

coerce 'RepeatedTextRecordSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vectorsearch::V1beta::DataObjectSearchService::VertexRanker::TextRecordSpec'->new($_) } @$_ ] };

declare 'MapStringTextRecordSpec',
    as HashRef[TextRecordSpec()];

declare 'BatchSearchDataObjectsResponse',
    as InstanceOf['Google::Cloud::Vectorsearch::V1beta::DataObjectSearchService::BatchSearchDataObjectsResponse'];

coerce 'BatchSearchDataObjectsResponse',
    from HashRef, via { 'Google::Cloud::Vectorsearch::V1beta::DataObjectSearchService::BatchSearchDataObjectsResponse'->new($_) };

declare 'RepeatedBatchSearchDataObjectsResponse',
    as ArrayRef[BatchSearchDataObjectsResponse()];

coerce 'RepeatedBatchSearchDataObjectsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vectorsearch::V1beta::DataObjectSearchService::BatchSearchDataObjectsResponse'->new($_) } @$_ ] };

declare 'MapStringBatchSearchDataObjectsResponse',
    as HashRef[BatchSearchDataObjectsResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Vectorsearch::V1beta::DataObjectSearchService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
