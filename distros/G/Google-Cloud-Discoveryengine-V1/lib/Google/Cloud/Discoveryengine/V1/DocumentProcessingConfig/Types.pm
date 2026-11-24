package Google::Cloud::Discoveryengine::V1::DocumentProcessingConfig::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'DocumentProcessingConfig',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::DocumentProcessingConfig::DocumentProcessingConfig'];

coerce 'DocumentProcessingConfig',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::DocumentProcessingConfig::DocumentProcessingConfig'->new($_) };

declare 'RepeatedDocumentProcessingConfig',
    as ArrayRef[DocumentProcessingConfig()];

coerce 'RepeatedDocumentProcessingConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::DocumentProcessingConfig::DocumentProcessingConfig'->new($_) } @$_ ] };

declare 'MapStringDocumentProcessingConfig',
    as HashRef[DocumentProcessingConfig()];

declare 'ChunkingConfig',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::DocumentProcessingConfig::DocumentProcessingConfig::ChunkingConfig'];

coerce 'ChunkingConfig',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::DocumentProcessingConfig::DocumentProcessingConfig::ChunkingConfig'->new($_) };

declare 'RepeatedChunkingConfig',
    as ArrayRef[ChunkingConfig()];

coerce 'RepeatedChunkingConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::DocumentProcessingConfig::DocumentProcessingConfig::ChunkingConfig'->new($_) } @$_ ] };

declare 'MapStringChunkingConfig',
    as HashRef[ChunkingConfig()];

declare 'LayoutBasedChunkingConfig',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::DocumentProcessingConfig::DocumentProcessingConfig::ChunkingConfig::LayoutBasedChunkingConfig'];

coerce 'LayoutBasedChunkingConfig',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::DocumentProcessingConfig::DocumentProcessingConfig::ChunkingConfig::LayoutBasedChunkingConfig'->new($_) };

declare 'RepeatedLayoutBasedChunkingConfig',
    as ArrayRef[LayoutBasedChunkingConfig()];

coerce 'RepeatedLayoutBasedChunkingConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::DocumentProcessingConfig::DocumentProcessingConfig::ChunkingConfig::LayoutBasedChunkingConfig'->new($_) } @$_ ] };

declare 'MapStringLayoutBasedChunkingConfig',
    as HashRef[LayoutBasedChunkingConfig()];

declare 'ParsingConfig',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::DocumentProcessingConfig::DocumentProcessingConfig::ParsingConfig'];

coerce 'ParsingConfig',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::DocumentProcessingConfig::DocumentProcessingConfig::ParsingConfig'->new($_) };

declare 'RepeatedParsingConfig',
    as ArrayRef[ParsingConfig()];

coerce 'RepeatedParsingConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::DocumentProcessingConfig::DocumentProcessingConfig::ParsingConfig'->new($_) } @$_ ] };

declare 'MapStringParsingConfig',
    as HashRef[ParsingConfig()];

declare 'DigitalParsingConfig',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::DocumentProcessingConfig::DocumentProcessingConfig::ParsingConfig::DigitalParsingConfig'];

coerce 'DigitalParsingConfig',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::DocumentProcessingConfig::DocumentProcessingConfig::ParsingConfig::DigitalParsingConfig'->new($_) };

declare 'RepeatedDigitalParsingConfig',
    as ArrayRef[DigitalParsingConfig()];

coerce 'RepeatedDigitalParsingConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::DocumentProcessingConfig::DocumentProcessingConfig::ParsingConfig::DigitalParsingConfig'->new($_) } @$_ ] };

declare 'MapStringDigitalParsingConfig',
    as HashRef[DigitalParsingConfig()];

declare 'OcrParsingConfig',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::DocumentProcessingConfig::DocumentProcessingConfig::ParsingConfig::OcrParsingConfig'];

coerce 'OcrParsingConfig',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::DocumentProcessingConfig::DocumentProcessingConfig::ParsingConfig::OcrParsingConfig'->new($_) };

declare 'RepeatedOcrParsingConfig',
    as ArrayRef[OcrParsingConfig()];

coerce 'RepeatedOcrParsingConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::DocumentProcessingConfig::DocumentProcessingConfig::ParsingConfig::OcrParsingConfig'->new($_) } @$_ ] };

declare 'MapStringOcrParsingConfig',
    as HashRef[OcrParsingConfig()];

declare 'LayoutParsingConfig',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::DocumentProcessingConfig::DocumentProcessingConfig::ParsingConfig::LayoutParsingConfig'];

coerce 'LayoutParsingConfig',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::DocumentProcessingConfig::DocumentProcessingConfig::ParsingConfig::LayoutParsingConfig'->new($_) };

declare 'RepeatedLayoutParsingConfig',
    as ArrayRef[LayoutParsingConfig()];

coerce 'RepeatedLayoutParsingConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::DocumentProcessingConfig::DocumentProcessingConfig::ParsingConfig::LayoutParsingConfig'->new($_) } @$_ ] };

declare 'MapStringLayoutParsingConfig',
    as HashRef[LayoutParsingConfig()];

declare 'ParsingConfigOverridesEntry',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::DocumentProcessingConfig::DocumentProcessingConfig::ParsingConfigOverridesEntry'];

coerce 'ParsingConfigOverridesEntry',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::DocumentProcessingConfig::DocumentProcessingConfig::ParsingConfigOverridesEntry'->new($_) };

declare 'RepeatedParsingConfigOverridesEntry',
    as ArrayRef[ParsingConfigOverridesEntry()];

coerce 'RepeatedParsingConfigOverridesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::DocumentProcessingConfig::DocumentProcessingConfig::ParsingConfigOverridesEntry'->new($_) } @$_ ] };

declare 'MapStringParsingConfigOverridesEntry',
    as HashRef[ParsingConfigOverridesEntry()];

1;

__END__

=head1 NAME

Google::Cloud::Discoveryengine::V1::DocumentProcessingConfig::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
