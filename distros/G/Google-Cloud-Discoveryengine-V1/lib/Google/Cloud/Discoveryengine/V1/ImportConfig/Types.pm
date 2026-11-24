package Google::Cloud::Discoveryengine::V1::ImportConfig::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'GcsSource',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::ImportConfig::GcsSource'];

coerce 'GcsSource',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::ImportConfig::GcsSource'->new($_) };

declare 'RepeatedGcsSource',
    as ArrayRef[GcsSource()];

coerce 'RepeatedGcsSource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::ImportConfig::GcsSource'->new($_) } @$_ ] };

declare 'MapStringGcsSource',
    as HashRef[GcsSource()];

declare 'BigQuerySource',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::ImportConfig::BigQuerySource'];

coerce 'BigQuerySource',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::ImportConfig::BigQuerySource'->new($_) };

declare 'RepeatedBigQuerySource',
    as ArrayRef[BigQuerySource()];

coerce 'RepeatedBigQuerySource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::ImportConfig::BigQuerySource'->new($_) } @$_ ] };

declare 'MapStringBigQuerySource',
    as HashRef[BigQuerySource()];

declare 'SpannerSource',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::ImportConfig::SpannerSource'];

coerce 'SpannerSource',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::ImportConfig::SpannerSource'->new($_) };

declare 'RepeatedSpannerSource',
    as ArrayRef[SpannerSource()];

coerce 'RepeatedSpannerSource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::ImportConfig::SpannerSource'->new($_) } @$_ ] };

declare 'MapStringSpannerSource',
    as HashRef[SpannerSource()];

declare 'BigtableOptions',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::ImportConfig::BigtableOptions'];

coerce 'BigtableOptions',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::ImportConfig::BigtableOptions'->new($_) };

declare 'RepeatedBigtableOptions',
    as ArrayRef[BigtableOptions()];

coerce 'RepeatedBigtableOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::ImportConfig::BigtableOptions'->new($_) } @$_ ] };

declare 'MapStringBigtableOptions',
    as HashRef[BigtableOptions()];

declare 'Type',
    as (Int | Str);

declare 'Encoding',
    as (Int | Str);

declare 'BigtableColumnFamily',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::ImportConfig::BigtableOptions::BigtableColumnFamily'];

coerce 'BigtableColumnFamily',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::ImportConfig::BigtableOptions::BigtableColumnFamily'->new($_) };

declare 'RepeatedBigtableColumnFamily',
    as ArrayRef[BigtableColumnFamily()];

coerce 'RepeatedBigtableColumnFamily',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::ImportConfig::BigtableOptions::BigtableColumnFamily'->new($_) } @$_ ] };

declare 'MapStringBigtableColumnFamily',
    as HashRef[BigtableColumnFamily()];

declare 'BigtableColumn',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::ImportConfig::BigtableOptions::BigtableColumn'];

coerce 'BigtableColumn',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::ImportConfig::BigtableOptions::BigtableColumn'->new($_) };

declare 'RepeatedBigtableColumn',
    as ArrayRef[BigtableColumn()];

coerce 'RepeatedBigtableColumn',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::ImportConfig::BigtableOptions::BigtableColumn'->new($_) } @$_ ] };

declare 'MapStringBigtableColumn',
    as HashRef[BigtableColumn()];

declare 'FamiliesEntry',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::ImportConfig::BigtableOptions::FamiliesEntry'];

coerce 'FamiliesEntry',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::ImportConfig::BigtableOptions::FamiliesEntry'->new($_) };

declare 'RepeatedFamiliesEntry',
    as ArrayRef[FamiliesEntry()];

coerce 'RepeatedFamiliesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::ImportConfig::BigtableOptions::FamiliesEntry'->new($_) } @$_ ] };

declare 'MapStringFamiliesEntry',
    as HashRef[FamiliesEntry()];

declare 'BigtableSource',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::ImportConfig::BigtableSource'];

coerce 'BigtableSource',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::ImportConfig::BigtableSource'->new($_) };

declare 'RepeatedBigtableSource',
    as ArrayRef[BigtableSource()];

coerce 'RepeatedBigtableSource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::ImportConfig::BigtableSource'->new($_) } @$_ ] };

declare 'MapStringBigtableSource',
    as HashRef[BigtableSource()];

declare 'FhirStoreSource',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::ImportConfig::FhirStoreSource'];

coerce 'FhirStoreSource',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::ImportConfig::FhirStoreSource'->new($_) };

declare 'RepeatedFhirStoreSource',
    as ArrayRef[FhirStoreSource()];

coerce 'RepeatedFhirStoreSource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::ImportConfig::FhirStoreSource'->new($_) } @$_ ] };

declare 'MapStringFhirStoreSource',
    as HashRef[FhirStoreSource()];

declare 'CloudSqlSource',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::ImportConfig::CloudSqlSource'];

coerce 'CloudSqlSource',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::ImportConfig::CloudSqlSource'->new($_) };

declare 'RepeatedCloudSqlSource',
    as ArrayRef[CloudSqlSource()];

coerce 'RepeatedCloudSqlSource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::ImportConfig::CloudSqlSource'->new($_) } @$_ ] };

declare 'MapStringCloudSqlSource',
    as HashRef[CloudSqlSource()];

declare 'AlloyDbSource',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::ImportConfig::AlloyDbSource'];

coerce 'AlloyDbSource',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::ImportConfig::AlloyDbSource'->new($_) };

declare 'RepeatedAlloyDbSource',
    as ArrayRef[AlloyDbSource()];

coerce 'RepeatedAlloyDbSource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::ImportConfig::AlloyDbSource'->new($_) } @$_ ] };

declare 'MapStringAlloyDbSource',
    as HashRef[AlloyDbSource()];

declare 'FirestoreSource',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::ImportConfig::FirestoreSource'];

coerce 'FirestoreSource',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::ImportConfig::FirestoreSource'->new($_) };

declare 'RepeatedFirestoreSource',
    as ArrayRef[FirestoreSource()];

coerce 'RepeatedFirestoreSource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::ImportConfig::FirestoreSource'->new($_) } @$_ ] };

declare 'MapStringFirestoreSource',
    as HashRef[FirestoreSource()];

declare 'ImportErrorConfig',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::ImportConfig::ImportErrorConfig'];

coerce 'ImportErrorConfig',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::ImportConfig::ImportErrorConfig'->new($_) };

declare 'RepeatedImportErrorConfig',
    as ArrayRef[ImportErrorConfig()];

coerce 'RepeatedImportErrorConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::ImportConfig::ImportErrorConfig'->new($_) } @$_ ] };

declare 'MapStringImportErrorConfig',
    as HashRef[ImportErrorConfig()];

declare 'ImportUserEventsRequest',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::ImportConfig::ImportUserEventsRequest'];

coerce 'ImportUserEventsRequest',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::ImportConfig::ImportUserEventsRequest'->new($_) };

declare 'RepeatedImportUserEventsRequest',
    as ArrayRef[ImportUserEventsRequest()];

coerce 'RepeatedImportUserEventsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::ImportConfig::ImportUserEventsRequest'->new($_) } @$_ ] };

declare 'MapStringImportUserEventsRequest',
    as HashRef[ImportUserEventsRequest()];

declare 'InlineSource',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::ImportConfig::ImportUserEventsRequest::InlineSource'];

coerce 'InlineSource',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::ImportConfig::ImportUserEventsRequest::InlineSource'->new($_) };

declare 'RepeatedInlineSource',
    as ArrayRef[InlineSource()];

coerce 'RepeatedInlineSource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::ImportConfig::ImportUserEventsRequest::InlineSource'->new($_) } @$_ ] };

declare 'MapStringInlineSource',
    as HashRef[InlineSource()];

declare 'ImportUserEventsResponse',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::ImportConfig::ImportUserEventsResponse'];

coerce 'ImportUserEventsResponse',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::ImportConfig::ImportUserEventsResponse'->new($_) };

declare 'RepeatedImportUserEventsResponse',
    as ArrayRef[ImportUserEventsResponse()];

coerce 'RepeatedImportUserEventsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::ImportConfig::ImportUserEventsResponse'->new($_) } @$_ ] };

declare 'MapStringImportUserEventsResponse',
    as HashRef[ImportUserEventsResponse()];

declare 'ImportUserEventsMetadata',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::ImportConfig::ImportUserEventsMetadata'];

coerce 'ImportUserEventsMetadata',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::ImportConfig::ImportUserEventsMetadata'->new($_) };

declare 'RepeatedImportUserEventsMetadata',
    as ArrayRef[ImportUserEventsMetadata()];

coerce 'RepeatedImportUserEventsMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::ImportConfig::ImportUserEventsMetadata'->new($_) } @$_ ] };

declare 'MapStringImportUserEventsMetadata',
    as HashRef[ImportUserEventsMetadata()];

declare 'ImportDocumentsMetadata',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::ImportConfig::ImportDocumentsMetadata'];

coerce 'ImportDocumentsMetadata',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::ImportConfig::ImportDocumentsMetadata'->new($_) };

declare 'RepeatedImportDocumentsMetadata',
    as ArrayRef[ImportDocumentsMetadata()];

coerce 'RepeatedImportDocumentsMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::ImportConfig::ImportDocumentsMetadata'->new($_) } @$_ ] };

declare 'MapStringImportDocumentsMetadata',
    as HashRef[ImportDocumentsMetadata()];

declare 'ImportDocumentsRequest',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::ImportConfig::ImportDocumentsRequest'];

coerce 'ImportDocumentsRequest',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::ImportConfig::ImportDocumentsRequest'->new($_) };

declare 'RepeatedImportDocumentsRequest',
    as ArrayRef[ImportDocumentsRequest()];

coerce 'RepeatedImportDocumentsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::ImportConfig::ImportDocumentsRequest'->new($_) } @$_ ] };

declare 'MapStringImportDocumentsRequest',
    as HashRef[ImportDocumentsRequest()];

declare 'ReconciliationMode',
    as (Int | Str);

declare 'InlineSource',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::ImportConfig::ImportDocumentsRequest::InlineSource'];

coerce 'InlineSource',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::ImportConfig::ImportDocumentsRequest::InlineSource'->new($_) };

declare 'RepeatedInlineSource',
    as ArrayRef[InlineSource()];

coerce 'RepeatedInlineSource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::ImportConfig::ImportDocumentsRequest::InlineSource'->new($_) } @$_ ] };

declare 'MapStringInlineSource',
    as HashRef[InlineSource()];

declare 'ImportDocumentsResponse',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::ImportConfig::ImportDocumentsResponse'];

coerce 'ImportDocumentsResponse',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::ImportConfig::ImportDocumentsResponse'->new($_) };

declare 'RepeatedImportDocumentsResponse',
    as ArrayRef[ImportDocumentsResponse()];

coerce 'RepeatedImportDocumentsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::ImportConfig::ImportDocumentsResponse'->new($_) } @$_ ] };

declare 'MapStringImportDocumentsResponse',
    as HashRef[ImportDocumentsResponse()];

declare 'ImportSuggestionDenyListEntriesRequest',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::ImportConfig::ImportSuggestionDenyListEntriesRequest'];

coerce 'ImportSuggestionDenyListEntriesRequest',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::ImportConfig::ImportSuggestionDenyListEntriesRequest'->new($_) };

declare 'RepeatedImportSuggestionDenyListEntriesRequest',
    as ArrayRef[ImportSuggestionDenyListEntriesRequest()];

coerce 'RepeatedImportSuggestionDenyListEntriesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::ImportConfig::ImportSuggestionDenyListEntriesRequest'->new($_) } @$_ ] };

declare 'MapStringImportSuggestionDenyListEntriesRequest',
    as HashRef[ImportSuggestionDenyListEntriesRequest()];

declare 'InlineSource',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::ImportConfig::ImportSuggestionDenyListEntriesRequest::InlineSource'];

coerce 'InlineSource',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::ImportConfig::ImportSuggestionDenyListEntriesRequest::InlineSource'->new($_) };

declare 'RepeatedInlineSource',
    as ArrayRef[InlineSource()];

coerce 'RepeatedInlineSource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::ImportConfig::ImportSuggestionDenyListEntriesRequest::InlineSource'->new($_) } @$_ ] };

declare 'MapStringInlineSource',
    as HashRef[InlineSource()];

declare 'ImportSuggestionDenyListEntriesResponse',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::ImportConfig::ImportSuggestionDenyListEntriesResponse'];

coerce 'ImportSuggestionDenyListEntriesResponse',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::ImportConfig::ImportSuggestionDenyListEntriesResponse'->new($_) };

declare 'RepeatedImportSuggestionDenyListEntriesResponse',
    as ArrayRef[ImportSuggestionDenyListEntriesResponse()];

coerce 'RepeatedImportSuggestionDenyListEntriesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::ImportConfig::ImportSuggestionDenyListEntriesResponse'->new($_) } @$_ ] };

declare 'MapStringImportSuggestionDenyListEntriesResponse',
    as HashRef[ImportSuggestionDenyListEntriesResponse()];

declare 'ImportSuggestionDenyListEntriesMetadata',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::ImportConfig::ImportSuggestionDenyListEntriesMetadata'];

coerce 'ImportSuggestionDenyListEntriesMetadata',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::ImportConfig::ImportSuggestionDenyListEntriesMetadata'->new($_) };

declare 'RepeatedImportSuggestionDenyListEntriesMetadata',
    as ArrayRef[ImportSuggestionDenyListEntriesMetadata()];

coerce 'RepeatedImportSuggestionDenyListEntriesMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::ImportConfig::ImportSuggestionDenyListEntriesMetadata'->new($_) } @$_ ] };

declare 'MapStringImportSuggestionDenyListEntriesMetadata',
    as HashRef[ImportSuggestionDenyListEntriesMetadata()];

declare 'ImportCompletionSuggestionsRequest',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::ImportConfig::ImportCompletionSuggestionsRequest'];

coerce 'ImportCompletionSuggestionsRequest',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::ImportConfig::ImportCompletionSuggestionsRequest'->new($_) };

declare 'RepeatedImportCompletionSuggestionsRequest',
    as ArrayRef[ImportCompletionSuggestionsRequest()];

coerce 'RepeatedImportCompletionSuggestionsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::ImportConfig::ImportCompletionSuggestionsRequest'->new($_) } @$_ ] };

declare 'MapStringImportCompletionSuggestionsRequest',
    as HashRef[ImportCompletionSuggestionsRequest()];

declare 'InlineSource',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::ImportConfig::ImportCompletionSuggestionsRequest::InlineSource'];

coerce 'InlineSource',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::ImportConfig::ImportCompletionSuggestionsRequest::InlineSource'->new($_) };

declare 'RepeatedInlineSource',
    as ArrayRef[InlineSource()];

coerce 'RepeatedInlineSource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::ImportConfig::ImportCompletionSuggestionsRequest::InlineSource'->new($_) } @$_ ] };

declare 'MapStringInlineSource',
    as HashRef[InlineSource()];

declare 'ImportCompletionSuggestionsResponse',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::ImportConfig::ImportCompletionSuggestionsResponse'];

coerce 'ImportCompletionSuggestionsResponse',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::ImportConfig::ImportCompletionSuggestionsResponse'->new($_) };

declare 'RepeatedImportCompletionSuggestionsResponse',
    as ArrayRef[ImportCompletionSuggestionsResponse()];

coerce 'RepeatedImportCompletionSuggestionsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::ImportConfig::ImportCompletionSuggestionsResponse'->new($_) } @$_ ] };

declare 'MapStringImportCompletionSuggestionsResponse',
    as HashRef[ImportCompletionSuggestionsResponse()];

declare 'ImportCompletionSuggestionsMetadata',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::ImportConfig::ImportCompletionSuggestionsMetadata'];

coerce 'ImportCompletionSuggestionsMetadata',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::ImportConfig::ImportCompletionSuggestionsMetadata'->new($_) };

declare 'RepeatedImportCompletionSuggestionsMetadata',
    as ArrayRef[ImportCompletionSuggestionsMetadata()];

coerce 'RepeatedImportCompletionSuggestionsMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::ImportConfig::ImportCompletionSuggestionsMetadata'->new($_) } @$_ ] };

declare 'MapStringImportCompletionSuggestionsMetadata',
    as HashRef[ImportCompletionSuggestionsMetadata()];

1;

__END__

=head1 NAME

Google::Cloud::Discoveryengine::V1::ImportConfig::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
