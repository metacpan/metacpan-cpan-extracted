package Google::Cloud::Discoveryengine::V1alpha::Chunk::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Chunk',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::Chunk::Chunk'];

coerce 'Chunk',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::Chunk::Chunk'->new($_) };

declare 'RepeatedChunk',
    as ArrayRef[Chunk()];

coerce 'RepeatedChunk',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::Chunk::Chunk'->new($_) } @$_ ] };

declare 'MapStringChunk',
    as HashRef[Chunk()];

declare 'DocumentMetadata',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::Chunk::Chunk::DocumentMetadata'];

coerce 'DocumentMetadata',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::Chunk::Chunk::DocumentMetadata'->new($_) };

declare 'RepeatedDocumentMetadata',
    as ArrayRef[DocumentMetadata()];

coerce 'RepeatedDocumentMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::Chunk::Chunk::DocumentMetadata'->new($_) } @$_ ] };

declare 'MapStringDocumentMetadata',
    as HashRef[DocumentMetadata()];

declare 'PageSpan',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::Chunk::Chunk::PageSpan'];

coerce 'PageSpan',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::Chunk::Chunk::PageSpan'->new($_) };

declare 'RepeatedPageSpan',
    as ArrayRef[PageSpan()];

coerce 'RepeatedPageSpan',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::Chunk::Chunk::PageSpan'->new($_) } @$_ ] };

declare 'MapStringPageSpan',
    as HashRef[PageSpan()];

declare 'ChunkMetadata',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::Chunk::Chunk::ChunkMetadata'];

coerce 'ChunkMetadata',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::Chunk::Chunk::ChunkMetadata'->new($_) };

declare 'RepeatedChunkMetadata',
    as ArrayRef[ChunkMetadata()];

coerce 'RepeatedChunkMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::Chunk::Chunk::ChunkMetadata'->new($_) } @$_ ] };

declare 'MapStringChunkMetadata',
    as HashRef[ChunkMetadata()];

1;

__END__

=head1 NAME

Google::Cloud::Discoveryengine::V1alpha::Chunk::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
