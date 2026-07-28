package Google::Ai::Generativelanguage::V1::Content::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Modality',
    as (Int | Str);

declare 'Content',
    as InstanceOf['Google::Ai::Generativelanguage::V1::Content::Content'];

coerce 'Content',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1::Content::Content'->new($_) };

declare 'RepeatedContent',
    as ArrayRef[Content()];

coerce 'RepeatedContent',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1::Content::Content'->new($_) } @$_ ] };

declare 'MapStringContent',
    as HashRef[Content()];

declare 'Part',
    as InstanceOf['Google::Ai::Generativelanguage::V1::Content::Part'];

coerce 'Part',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1::Content::Part'->new($_) };

declare 'RepeatedPart',
    as ArrayRef[Part()];

coerce 'RepeatedPart',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1::Content::Part'->new($_) } @$_ ] };

declare 'MapStringPart',
    as HashRef[Part()];

declare 'Blob',
    as InstanceOf['Google::Ai::Generativelanguage::V1::Content::Blob'];

coerce 'Blob',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1::Content::Blob'->new($_) };

declare 'RepeatedBlob',
    as ArrayRef[Blob()];

coerce 'RepeatedBlob',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1::Content::Blob'->new($_) } @$_ ] };

declare 'MapStringBlob',
    as HashRef[Blob()];

declare 'VideoMetadata',
    as InstanceOf['Google::Ai::Generativelanguage::V1::Content::VideoMetadata'];

coerce 'VideoMetadata',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1::Content::VideoMetadata'->new($_) };

declare 'RepeatedVideoMetadata',
    as ArrayRef[VideoMetadata()];

coerce 'RepeatedVideoMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1::Content::VideoMetadata'->new($_) } @$_ ] };

declare 'MapStringVideoMetadata',
    as HashRef[VideoMetadata()];

declare 'ModalityTokenCount',
    as InstanceOf['Google::Ai::Generativelanguage::V1::Content::ModalityTokenCount'];

coerce 'ModalityTokenCount',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1::Content::ModalityTokenCount'->new($_) };

declare 'RepeatedModalityTokenCount',
    as ArrayRef[ModalityTokenCount()];

coerce 'RepeatedModalityTokenCount',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1::Content::ModalityTokenCount'->new($_) } @$_ ] };

declare 'MapStringModalityTokenCount',
    as HashRef[ModalityTokenCount()];

1;

__END__

=head1 NAME

Google::Ai::Generativelanguage::V1::Content::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
