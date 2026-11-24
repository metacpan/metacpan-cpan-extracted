package Google::Cloud::Dialogflow::V2::Grounding::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'GroundingMetadata',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Grounding::GroundingMetadata'];

coerce 'GroundingMetadata',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Grounding::GroundingMetadata'->new($_) };

declare 'RepeatedGroundingMetadata',
    as ArrayRef[GroundingMetadata()];

coerce 'RepeatedGroundingMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Grounding::GroundingMetadata'->new($_) } @$_ ] };

declare 'MapStringGroundingMetadata',
    as HashRef[GroundingMetadata()];

declare 'SearchEntryPoint',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Grounding::SearchEntryPoint'];

coerce 'SearchEntryPoint',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Grounding::SearchEntryPoint'->new($_) };

declare 'RepeatedSearchEntryPoint',
    as ArrayRef[SearchEntryPoint()];

coerce 'RepeatedSearchEntryPoint',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Grounding::SearchEntryPoint'->new($_) } @$_ ] };

declare 'MapStringSearchEntryPoint',
    as HashRef[SearchEntryPoint()];

declare 'GroundingChunk',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Grounding::GroundingChunk'];

coerce 'GroundingChunk',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Grounding::GroundingChunk'->new($_) };

declare 'RepeatedGroundingChunk',
    as ArrayRef[GroundingChunk()];

coerce 'RepeatedGroundingChunk',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Grounding::GroundingChunk'->new($_) } @$_ ] };

declare 'MapStringGroundingChunk',
    as HashRef[GroundingChunk()];

declare 'Web',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Grounding::GroundingChunk::Web'];

coerce 'Web',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Grounding::GroundingChunk::Web'->new($_) };

declare 'RepeatedWeb',
    as ArrayRef[Web()];

coerce 'RepeatedWeb',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Grounding::GroundingChunk::Web'->new($_) } @$_ ] };

declare 'MapStringWeb',
    as HashRef[Web()];

declare 'RetrievedContext',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Grounding::GroundingChunk::RetrievedContext'];

coerce 'RetrievedContext',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Grounding::GroundingChunk::RetrievedContext'->new($_) };

declare 'RepeatedRetrievedContext',
    as ArrayRef[RetrievedContext()];

coerce 'RepeatedRetrievedContext',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Grounding::GroundingChunk::RetrievedContext'->new($_) } @$_ ] };

declare 'MapStringRetrievedContext',
    as HashRef[RetrievedContext()];

declare 'Segment',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Grounding::Segment'];

coerce 'Segment',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Grounding::Segment'->new($_) };

declare 'RepeatedSegment',
    as ArrayRef[Segment()];

coerce 'RepeatedSegment',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Grounding::Segment'->new($_) } @$_ ] };

declare 'MapStringSegment',
    as HashRef[Segment()];

declare 'GroundingSupport',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Grounding::GroundingSupport'];

coerce 'GroundingSupport',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Grounding::GroundingSupport'->new($_) };

declare 'RepeatedGroundingSupport',
    as ArrayRef[GroundingSupport()];

coerce 'RepeatedGroundingSupport',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Grounding::GroundingSupport'->new($_) } @$_ ] };

declare 'MapStringGroundingSupport',
    as HashRef[GroundingSupport()];

1;

__END__

=head1 NAME

Google::Cloud::Dialogflow::V2::Grounding::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
