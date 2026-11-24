package Google::Cloud::Discoveryengine::V1::Chunk::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Chunk',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::Chunk::Chunk'];

coerce 'Chunk',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::Chunk::Chunk'->new($_) };

declare 'RepeatedChunk',
    as ArrayRef[Chunk()];

coerce 'RepeatedChunk',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::Chunk::Chunk'->new($_) } @$_ ] };

declare 'MapStringChunk',
    as HashRef[Chunk()];

declare 'StructureType',
    as (Int | Str);

declare 'DocumentMetadata',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::Chunk::Chunk::DocumentMetadata'];

coerce 'DocumentMetadata',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::Chunk::Chunk::DocumentMetadata'->new($_) };

declare 'RepeatedDocumentMetadata',
    as ArrayRef[DocumentMetadata()];

coerce 'RepeatedDocumentMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::Chunk::Chunk::DocumentMetadata'->new($_) } @$_ ] };

declare 'MapStringDocumentMetadata',
    as HashRef[DocumentMetadata()];

declare 'PageSpan',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::Chunk::Chunk::PageSpan'];

coerce 'PageSpan',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::Chunk::Chunk::PageSpan'->new($_) };

declare 'RepeatedPageSpan',
    as ArrayRef[PageSpan()];

coerce 'RepeatedPageSpan',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::Chunk::Chunk::PageSpan'->new($_) } @$_ ] };

declare 'MapStringPageSpan',
    as HashRef[PageSpan()];

declare 'ChunkMetadata',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::Chunk::Chunk::ChunkMetadata'];

coerce 'ChunkMetadata',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::Chunk::Chunk::ChunkMetadata'->new($_) };

declare 'RepeatedChunkMetadata',
    as ArrayRef[ChunkMetadata()];

coerce 'RepeatedChunkMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::Chunk::Chunk::ChunkMetadata'->new($_) } @$_ ] };

declare 'MapStringChunkMetadata',
    as HashRef[ChunkMetadata()];

declare 'StructuredContent',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::Chunk::Chunk::StructuredContent'];

coerce 'StructuredContent',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::Chunk::Chunk::StructuredContent'->new($_) };

declare 'RepeatedStructuredContent',
    as ArrayRef[StructuredContent()];

coerce 'RepeatedStructuredContent',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::Chunk::Chunk::StructuredContent'->new($_) } @$_ ] };

declare 'MapStringStructuredContent',
    as HashRef[StructuredContent()];

declare 'AnnotationMetadata',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::Chunk::Chunk::AnnotationMetadata'];

coerce 'AnnotationMetadata',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::Chunk::Chunk::AnnotationMetadata'->new($_) };

declare 'RepeatedAnnotationMetadata',
    as ArrayRef[AnnotationMetadata()];

coerce 'RepeatedAnnotationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::Chunk::Chunk::AnnotationMetadata'->new($_) } @$_ ] };

declare 'MapStringAnnotationMetadata',
    as HashRef[AnnotationMetadata()];

1;

__END__

=head1 NAME

Google::Cloud::Discoveryengine::V1::Chunk::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
