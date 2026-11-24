package Google::Cloud::Discoveryengine::V1alpha::Answer::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Answer',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::Answer::Answer'];

coerce 'Answer',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::Answer::Answer'->new($_) };

declare 'RepeatedAnswer',
    as ArrayRef[Answer()];

coerce 'RepeatedAnswer',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::Answer::Answer'->new($_) } @$_ ] };

declare 'MapStringAnswer',
    as HashRef[Answer()];

declare 'State',
    as (Int | Str);

declare 'AnswerSkippedReason',
    as (Int | Str);

declare 'Citation',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::Answer::Answer::Citation'];

coerce 'Citation',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::Answer::Answer::Citation'->new($_) };

declare 'RepeatedCitation',
    as ArrayRef[Citation()];

coerce 'RepeatedCitation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::Answer::Answer::Citation'->new($_) } @$_ ] };

declare 'MapStringCitation',
    as HashRef[Citation()];

declare 'CitationSource',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::Answer::Answer::CitationSource'];

coerce 'CitationSource',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::Answer::Answer::CitationSource'->new($_) };

declare 'RepeatedCitationSource',
    as ArrayRef[CitationSource()];

coerce 'RepeatedCitationSource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::Answer::Answer::CitationSource'->new($_) } @$_ ] };

declare 'MapStringCitationSource',
    as HashRef[CitationSource()];

declare 'Reference',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::Answer::Answer::Reference'];

coerce 'Reference',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::Answer::Answer::Reference'->new($_) };

declare 'RepeatedReference',
    as ArrayRef[Reference()];

coerce 'RepeatedReference',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::Answer::Answer::Reference'->new($_) } @$_ ] };

declare 'MapStringReference',
    as HashRef[Reference()];

declare 'UnstructuredDocumentInfo',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::Answer::Answer::Reference::UnstructuredDocumentInfo'];

coerce 'UnstructuredDocumentInfo',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::Answer::Answer::Reference::UnstructuredDocumentInfo'->new($_) };

declare 'RepeatedUnstructuredDocumentInfo',
    as ArrayRef[UnstructuredDocumentInfo()];

coerce 'RepeatedUnstructuredDocumentInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::Answer::Answer::Reference::UnstructuredDocumentInfo'->new($_) } @$_ ] };

declare 'MapStringUnstructuredDocumentInfo',
    as HashRef[UnstructuredDocumentInfo()];

declare 'ChunkContent',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::Answer::Answer::Reference::UnstructuredDocumentInfo::ChunkContent'];

coerce 'ChunkContent',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::Answer::Answer::Reference::UnstructuredDocumentInfo::ChunkContent'->new($_) };

declare 'RepeatedChunkContent',
    as ArrayRef[ChunkContent()];

coerce 'RepeatedChunkContent',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::Answer::Answer::Reference::UnstructuredDocumentInfo::ChunkContent'->new($_) } @$_ ] };

declare 'MapStringChunkContent',
    as HashRef[ChunkContent()];

declare 'ChunkInfo',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::Answer::Answer::Reference::ChunkInfo'];

coerce 'ChunkInfo',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::Answer::Answer::Reference::ChunkInfo'->new($_) };

declare 'RepeatedChunkInfo',
    as ArrayRef[ChunkInfo()];

coerce 'RepeatedChunkInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::Answer::Answer::Reference::ChunkInfo'->new($_) } @$_ ] };

declare 'MapStringChunkInfo',
    as HashRef[ChunkInfo()];

declare 'DocumentMetadata',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::Answer::Answer::Reference::ChunkInfo::DocumentMetadata'];

coerce 'DocumentMetadata',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::Answer::Answer::Reference::ChunkInfo::DocumentMetadata'->new($_) };

declare 'RepeatedDocumentMetadata',
    as ArrayRef[DocumentMetadata()];

coerce 'RepeatedDocumentMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::Answer::Answer::Reference::ChunkInfo::DocumentMetadata'->new($_) } @$_ ] };

declare 'MapStringDocumentMetadata',
    as HashRef[DocumentMetadata()];

declare 'StructuredDocumentInfo',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::Answer::Answer::Reference::StructuredDocumentInfo'];

coerce 'StructuredDocumentInfo',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::Answer::Answer::Reference::StructuredDocumentInfo'->new($_) };

declare 'RepeatedStructuredDocumentInfo',
    as ArrayRef[StructuredDocumentInfo()];

coerce 'RepeatedStructuredDocumentInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::Answer::Answer::Reference::StructuredDocumentInfo'->new($_) } @$_ ] };

declare 'MapStringStructuredDocumentInfo',
    as HashRef[StructuredDocumentInfo()];

declare 'Step',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::Answer::Answer::Step'];

coerce 'Step',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::Answer::Answer::Step'->new($_) };

declare 'RepeatedStep',
    as ArrayRef[Step()];

coerce 'RepeatedStep',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::Answer::Answer::Step'->new($_) } @$_ ] };

declare 'MapStringStep',
    as HashRef[Step()];

declare 'State',
    as (Int | Str);

declare 'Action',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::Answer::Answer::Step::Action'];

coerce 'Action',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::Answer::Answer::Step::Action'->new($_) };

declare 'RepeatedAction',
    as ArrayRef[Action()];

coerce 'RepeatedAction',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::Answer::Answer::Step::Action'->new($_) } @$_ ] };

declare 'MapStringAction',
    as HashRef[Action()];

declare 'SearchAction',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::Answer::Answer::Step::Action::SearchAction'];

coerce 'SearchAction',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::Answer::Answer::Step::Action::SearchAction'->new($_) };

declare 'RepeatedSearchAction',
    as ArrayRef[SearchAction()];

coerce 'RepeatedSearchAction',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::Answer::Answer::Step::Action::SearchAction'->new($_) } @$_ ] };

declare 'MapStringSearchAction',
    as HashRef[SearchAction()];

declare 'Observation',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::Answer::Answer::Step::Action::Observation'];

coerce 'Observation',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::Answer::Answer::Step::Action::Observation'->new($_) };

declare 'RepeatedObservation',
    as ArrayRef[Observation()];

coerce 'RepeatedObservation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::Answer::Answer::Step::Action::Observation'->new($_) } @$_ ] };

declare 'MapStringObservation',
    as HashRef[Observation()];

declare 'SearchResult',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::Answer::Answer::Step::Action::Observation::SearchResult'];

coerce 'SearchResult',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::Answer::Answer::Step::Action::Observation::SearchResult'->new($_) };

declare 'RepeatedSearchResult',
    as ArrayRef[SearchResult()];

coerce 'RepeatedSearchResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::Answer::Answer::Step::Action::Observation::SearchResult'->new($_) } @$_ ] };

declare 'MapStringSearchResult',
    as HashRef[SearchResult()];

declare 'SnippetInfo',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::Answer::Answer::Step::Action::Observation::SearchResult::SnippetInfo'];

coerce 'SnippetInfo',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::Answer::Answer::Step::Action::Observation::SearchResult::SnippetInfo'->new($_) };

declare 'RepeatedSnippetInfo',
    as ArrayRef[SnippetInfo()];

coerce 'RepeatedSnippetInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::Answer::Answer::Step::Action::Observation::SearchResult::SnippetInfo'->new($_) } @$_ ] };

declare 'MapStringSnippetInfo',
    as HashRef[SnippetInfo()];

declare 'ChunkInfo',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::Answer::Answer::Step::Action::Observation::SearchResult::ChunkInfo'];

coerce 'ChunkInfo',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::Answer::Answer::Step::Action::Observation::SearchResult::ChunkInfo'->new($_) };

declare 'RepeatedChunkInfo',
    as ArrayRef[ChunkInfo()];

coerce 'RepeatedChunkInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::Answer::Answer::Step::Action::Observation::SearchResult::ChunkInfo'->new($_) } @$_ ] };

declare 'MapStringChunkInfo',
    as HashRef[ChunkInfo()];

declare 'QueryUnderstandingInfo',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::Answer::Answer::QueryUnderstandingInfo'];

coerce 'QueryUnderstandingInfo',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::Answer::Answer::QueryUnderstandingInfo'->new($_) };

declare 'RepeatedQueryUnderstandingInfo',
    as ArrayRef[QueryUnderstandingInfo()];

coerce 'RepeatedQueryUnderstandingInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::Answer::Answer::QueryUnderstandingInfo'->new($_) } @$_ ] };

declare 'MapStringQueryUnderstandingInfo',
    as HashRef[QueryUnderstandingInfo()];

declare 'QueryClassificationInfo',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::Answer::Answer::QueryUnderstandingInfo::QueryClassificationInfo'];

coerce 'QueryClassificationInfo',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::Answer::Answer::QueryUnderstandingInfo::QueryClassificationInfo'->new($_) };

declare 'RepeatedQueryClassificationInfo',
    as ArrayRef[QueryClassificationInfo()];

coerce 'RepeatedQueryClassificationInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::Answer::Answer::QueryUnderstandingInfo::QueryClassificationInfo'->new($_) } @$_ ] };

declare 'MapStringQueryClassificationInfo',
    as HashRef[QueryClassificationInfo()];

declare 'Type',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Discoveryengine::V1alpha::Answer::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
