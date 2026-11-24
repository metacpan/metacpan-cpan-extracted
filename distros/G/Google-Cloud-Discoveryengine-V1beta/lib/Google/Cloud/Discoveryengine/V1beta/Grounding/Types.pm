package Google::Cloud::Discoveryengine::V1beta::Grounding::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'GroundingConfig',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::Grounding::GroundingConfig'];

coerce 'GroundingConfig',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::Grounding::GroundingConfig'->new($_) };

declare 'RepeatedGroundingConfig',
    as ArrayRef[GroundingConfig()];

coerce 'RepeatedGroundingConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::Grounding::GroundingConfig'->new($_) } @$_ ] };

declare 'MapStringGroundingConfig',
    as HashRef[GroundingConfig()];

declare 'GroundingFact',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::Grounding::GroundingFact'];

coerce 'GroundingFact',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::Grounding::GroundingFact'->new($_) };

declare 'RepeatedGroundingFact',
    as ArrayRef[GroundingFact()];

coerce 'RepeatedGroundingFact',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::Grounding::GroundingFact'->new($_) } @$_ ] };

declare 'MapStringGroundingFact',
    as HashRef[GroundingFact()];

declare 'AttributesEntry',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::Grounding::GroundingFact::AttributesEntry'];

coerce 'AttributesEntry',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::Grounding::GroundingFact::AttributesEntry'->new($_) };

declare 'RepeatedAttributesEntry',
    as ArrayRef[AttributesEntry()];

coerce 'RepeatedAttributesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::Grounding::GroundingFact::AttributesEntry'->new($_) } @$_ ] };

declare 'MapStringAttributesEntry',
    as HashRef[AttributesEntry()];

declare 'FactChunk',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::Grounding::FactChunk'];

coerce 'FactChunk',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::Grounding::FactChunk'->new($_) };

declare 'RepeatedFactChunk',
    as ArrayRef[FactChunk()];

coerce 'RepeatedFactChunk',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::Grounding::FactChunk'->new($_) } @$_ ] };

declare 'MapStringFactChunk',
    as HashRef[FactChunk()];

declare 'SourceMetadataEntry',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::Grounding::FactChunk::SourceMetadataEntry'];

coerce 'SourceMetadataEntry',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::Grounding::FactChunk::SourceMetadataEntry'->new($_) };

declare 'RepeatedSourceMetadataEntry',
    as ArrayRef[SourceMetadataEntry()];

coerce 'RepeatedSourceMetadataEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::Grounding::FactChunk::SourceMetadataEntry'->new($_) } @$_ ] };

declare 'MapStringSourceMetadataEntry',
    as HashRef[SourceMetadataEntry()];

1;

__END__

=head1 NAME

Google::Cloud::Discoveryengine::V1beta::Grounding::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
