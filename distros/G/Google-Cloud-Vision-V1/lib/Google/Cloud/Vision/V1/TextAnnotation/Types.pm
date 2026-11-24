package Google::Cloud::Vision::V1::TextAnnotation::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'TextAnnotation',
    as InstanceOf['Google::Cloud::Vision::V1::TextAnnotation::TextAnnotation'];

coerce 'TextAnnotation',
    from HashRef, via { 'Google::Cloud::Vision::V1::TextAnnotation::TextAnnotation'->new($_) };

declare 'RepeatedTextAnnotation',
    as ArrayRef[TextAnnotation()];

coerce 'RepeatedTextAnnotation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vision::V1::TextAnnotation::TextAnnotation'->new($_) } @$_ ] };

declare 'MapStringTextAnnotation',
    as HashRef[TextAnnotation()];

declare 'DetectedLanguage',
    as InstanceOf['Google::Cloud::Vision::V1::TextAnnotation::TextAnnotation::DetectedLanguage'];

coerce 'DetectedLanguage',
    from HashRef, via { 'Google::Cloud::Vision::V1::TextAnnotation::TextAnnotation::DetectedLanguage'->new($_) };

declare 'RepeatedDetectedLanguage',
    as ArrayRef[DetectedLanguage()];

coerce 'RepeatedDetectedLanguage',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vision::V1::TextAnnotation::TextAnnotation::DetectedLanguage'->new($_) } @$_ ] };

declare 'MapStringDetectedLanguage',
    as HashRef[DetectedLanguage()];

declare 'DetectedBreak',
    as InstanceOf['Google::Cloud::Vision::V1::TextAnnotation::TextAnnotation::DetectedBreak'];

coerce 'DetectedBreak',
    from HashRef, via { 'Google::Cloud::Vision::V1::TextAnnotation::TextAnnotation::DetectedBreak'->new($_) };

declare 'RepeatedDetectedBreak',
    as ArrayRef[DetectedBreak()];

coerce 'RepeatedDetectedBreak',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vision::V1::TextAnnotation::TextAnnotation::DetectedBreak'->new($_) } @$_ ] };

declare 'MapStringDetectedBreak',
    as HashRef[DetectedBreak()];

declare 'BreakType',
    as (Int | Str);

declare 'TextProperty',
    as InstanceOf['Google::Cloud::Vision::V1::TextAnnotation::TextAnnotation::TextProperty'];

coerce 'TextProperty',
    from HashRef, via { 'Google::Cloud::Vision::V1::TextAnnotation::TextAnnotation::TextProperty'->new($_) };

declare 'RepeatedTextProperty',
    as ArrayRef[TextProperty()];

coerce 'RepeatedTextProperty',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vision::V1::TextAnnotation::TextAnnotation::TextProperty'->new($_) } @$_ ] };

declare 'MapStringTextProperty',
    as HashRef[TextProperty()];

declare 'Page',
    as InstanceOf['Google::Cloud::Vision::V1::TextAnnotation::Page'];

coerce 'Page',
    from HashRef, via { 'Google::Cloud::Vision::V1::TextAnnotation::Page'->new($_) };

declare 'RepeatedPage',
    as ArrayRef[Page()];

coerce 'RepeatedPage',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vision::V1::TextAnnotation::Page'->new($_) } @$_ ] };

declare 'MapStringPage',
    as HashRef[Page()];

declare 'Block',
    as InstanceOf['Google::Cloud::Vision::V1::TextAnnotation::Block'];

coerce 'Block',
    from HashRef, via { 'Google::Cloud::Vision::V1::TextAnnotation::Block'->new($_) };

declare 'RepeatedBlock',
    as ArrayRef[Block()];

coerce 'RepeatedBlock',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vision::V1::TextAnnotation::Block'->new($_) } @$_ ] };

declare 'MapStringBlock',
    as HashRef[Block()];

declare 'BlockType',
    as (Int | Str);

declare 'Paragraph',
    as InstanceOf['Google::Cloud::Vision::V1::TextAnnotation::Paragraph'];

coerce 'Paragraph',
    from HashRef, via { 'Google::Cloud::Vision::V1::TextAnnotation::Paragraph'->new($_) };

declare 'RepeatedParagraph',
    as ArrayRef[Paragraph()];

coerce 'RepeatedParagraph',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vision::V1::TextAnnotation::Paragraph'->new($_) } @$_ ] };

declare 'MapStringParagraph',
    as HashRef[Paragraph()];

declare 'Word',
    as InstanceOf['Google::Cloud::Vision::V1::TextAnnotation::Word'];

coerce 'Word',
    from HashRef, via { 'Google::Cloud::Vision::V1::TextAnnotation::Word'->new($_) };

declare 'RepeatedWord',
    as ArrayRef[Word()];

coerce 'RepeatedWord',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vision::V1::TextAnnotation::Word'->new($_) } @$_ ] };

declare 'MapStringWord',
    as HashRef[Word()];

declare 'Symbol',
    as InstanceOf['Google::Cloud::Vision::V1::TextAnnotation::Symbol'];

coerce 'Symbol',
    from HashRef, via { 'Google::Cloud::Vision::V1::TextAnnotation::Symbol'->new($_) };

declare 'RepeatedSymbol',
    as ArrayRef[Symbol()];

coerce 'RepeatedSymbol',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vision::V1::TextAnnotation::Symbol'->new($_) } @$_ ] };

declare 'MapStringSymbol',
    as HashRef[Symbol()];

1;

__END__

=head1 NAME

Google::Cloud::Vision::V1::TextAnnotation::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
