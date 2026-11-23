package Google::Ai::Generativelanguage::V1beta::Retriever::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Corpus',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::Retriever::Corpus'];

coerce 'Corpus',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::Retriever::Corpus'->new($_) };

declare 'RepeatedCorpus',
    as ArrayRef[Corpus()];

coerce 'RepeatedCorpus',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::Retriever::Corpus'->new($_) } @$_ ] };

declare 'MapStringCorpus',
    as HashRef[Corpus()];

declare 'Document',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::Retriever::Document'];

coerce 'Document',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::Retriever::Document'->new($_) };

declare 'RepeatedDocument',
    as ArrayRef[Document()];

coerce 'RepeatedDocument',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::Retriever::Document'->new($_) } @$_ ] };

declare 'MapStringDocument',
    as HashRef[Document()];

declare 'StringList',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::Retriever::StringList'];

coerce 'StringList',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::Retriever::StringList'->new($_) };

declare 'RepeatedStringList',
    as ArrayRef[StringList()];

coerce 'RepeatedStringList',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::Retriever::StringList'->new($_) } @$_ ] };

declare 'MapStringStringList',
    as HashRef[StringList()];

declare 'CustomMetadata',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::Retriever::CustomMetadata'];

coerce 'CustomMetadata',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::Retriever::CustomMetadata'->new($_) };

declare 'RepeatedCustomMetadata',
    as ArrayRef[CustomMetadata()];

coerce 'RepeatedCustomMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::Retriever::CustomMetadata'->new($_) } @$_ ] };

declare 'MapStringCustomMetadata',
    as HashRef[CustomMetadata()];

declare 'MetadataFilter',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::Retriever::MetadataFilter'];

coerce 'MetadataFilter',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::Retriever::MetadataFilter'->new($_) };

declare 'RepeatedMetadataFilter',
    as ArrayRef[MetadataFilter()];

coerce 'RepeatedMetadataFilter',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::Retriever::MetadataFilter'->new($_) } @$_ ] };

declare 'MapStringMetadataFilter',
    as HashRef[MetadataFilter()];

declare 'Condition',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::Retriever::Condition'];

coerce 'Condition',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::Retriever::Condition'->new($_) };

declare 'RepeatedCondition',
    as ArrayRef[Condition()];

coerce 'RepeatedCondition',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::Retriever::Condition'->new($_) } @$_ ] };

declare 'MapStringCondition',
    as HashRef[Condition()];

declare 'Operator',
    as (Int | Str);

declare 'Chunk',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::Retriever::Chunk'];

coerce 'Chunk',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::Retriever::Chunk'->new($_) };

declare 'RepeatedChunk',
    as ArrayRef[Chunk()];

coerce 'RepeatedChunk',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::Retriever::Chunk'->new($_) } @$_ ] };

declare 'MapStringChunk',
    as HashRef[Chunk()];

declare 'State',
    as (Int | Str);

declare 'ChunkData',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::Retriever::ChunkData'];

coerce 'ChunkData',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::Retriever::ChunkData'->new($_) };

declare 'RepeatedChunkData',
    as ArrayRef[ChunkData()];

coerce 'RepeatedChunkData',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::Retriever::ChunkData'->new($_) } @$_ ] };

declare 'MapStringChunkData',
    as HashRef[ChunkData()];

1;

__END__

=head1 NAME

Google::Ai::Generativelanguage::V1beta::Retriever::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
