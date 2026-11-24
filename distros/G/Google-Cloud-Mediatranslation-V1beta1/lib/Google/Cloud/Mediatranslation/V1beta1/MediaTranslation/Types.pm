package Google::Cloud::Mediatranslation::V1beta1::MediaTranslation::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'TranslateSpeechConfig',
    as InstanceOf['Google::Cloud::Mediatranslation::V1beta1::MediaTranslation::TranslateSpeechConfig'];

coerce 'TranslateSpeechConfig',
    from HashRef, via { 'Google::Cloud::Mediatranslation::V1beta1::MediaTranslation::TranslateSpeechConfig'->new($_) };

declare 'RepeatedTranslateSpeechConfig',
    as ArrayRef[TranslateSpeechConfig()];

coerce 'RepeatedTranslateSpeechConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Mediatranslation::V1beta1::MediaTranslation::TranslateSpeechConfig'->new($_) } @$_ ] };

declare 'MapStringTranslateSpeechConfig',
    as HashRef[TranslateSpeechConfig()];

declare 'StreamingTranslateSpeechConfig',
    as InstanceOf['Google::Cloud::Mediatranslation::V1beta1::MediaTranslation::StreamingTranslateSpeechConfig'];

coerce 'StreamingTranslateSpeechConfig',
    from HashRef, via { 'Google::Cloud::Mediatranslation::V1beta1::MediaTranslation::StreamingTranslateSpeechConfig'->new($_) };

declare 'RepeatedStreamingTranslateSpeechConfig',
    as ArrayRef[StreamingTranslateSpeechConfig()];

coerce 'RepeatedStreamingTranslateSpeechConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Mediatranslation::V1beta1::MediaTranslation::StreamingTranslateSpeechConfig'->new($_) } @$_ ] };

declare 'MapStringStreamingTranslateSpeechConfig',
    as HashRef[StreamingTranslateSpeechConfig()];

declare 'StreamingTranslateSpeechRequest',
    as InstanceOf['Google::Cloud::Mediatranslation::V1beta1::MediaTranslation::StreamingTranslateSpeechRequest'];

coerce 'StreamingTranslateSpeechRequest',
    from HashRef, via { 'Google::Cloud::Mediatranslation::V1beta1::MediaTranslation::StreamingTranslateSpeechRequest'->new($_) };

declare 'RepeatedStreamingTranslateSpeechRequest',
    as ArrayRef[StreamingTranslateSpeechRequest()];

coerce 'RepeatedStreamingTranslateSpeechRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Mediatranslation::V1beta1::MediaTranslation::StreamingTranslateSpeechRequest'->new($_) } @$_ ] };

declare 'MapStringStreamingTranslateSpeechRequest',
    as HashRef[StreamingTranslateSpeechRequest()];

declare 'StreamingTranslateSpeechResult',
    as InstanceOf['Google::Cloud::Mediatranslation::V1beta1::MediaTranslation::StreamingTranslateSpeechResult'];

coerce 'StreamingTranslateSpeechResult',
    from HashRef, via { 'Google::Cloud::Mediatranslation::V1beta1::MediaTranslation::StreamingTranslateSpeechResult'->new($_) };

declare 'RepeatedStreamingTranslateSpeechResult',
    as ArrayRef[StreamingTranslateSpeechResult()];

coerce 'RepeatedStreamingTranslateSpeechResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Mediatranslation::V1beta1::MediaTranslation::StreamingTranslateSpeechResult'->new($_) } @$_ ] };

declare 'MapStringStreamingTranslateSpeechResult',
    as HashRef[StreamingTranslateSpeechResult()];

declare 'TextTranslationResult',
    as InstanceOf['Google::Cloud::Mediatranslation::V1beta1::MediaTranslation::StreamingTranslateSpeechResult::TextTranslationResult'];

coerce 'TextTranslationResult',
    from HashRef, via { 'Google::Cloud::Mediatranslation::V1beta1::MediaTranslation::StreamingTranslateSpeechResult::TextTranslationResult'->new($_) };

declare 'RepeatedTextTranslationResult',
    as ArrayRef[TextTranslationResult()];

coerce 'RepeatedTextTranslationResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Mediatranslation::V1beta1::MediaTranslation::StreamingTranslateSpeechResult::TextTranslationResult'->new($_) } @$_ ] };

declare 'MapStringTextTranslationResult',
    as HashRef[TextTranslationResult()];

declare 'StreamingTranslateSpeechResponse',
    as InstanceOf['Google::Cloud::Mediatranslation::V1beta1::MediaTranslation::StreamingTranslateSpeechResponse'];

coerce 'StreamingTranslateSpeechResponse',
    from HashRef, via { 'Google::Cloud::Mediatranslation::V1beta1::MediaTranslation::StreamingTranslateSpeechResponse'->new($_) };

declare 'RepeatedStreamingTranslateSpeechResponse',
    as ArrayRef[StreamingTranslateSpeechResponse()];

coerce 'RepeatedStreamingTranslateSpeechResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Mediatranslation::V1beta1::MediaTranslation::StreamingTranslateSpeechResponse'->new($_) } @$_ ] };

declare 'MapStringStreamingTranslateSpeechResponse',
    as HashRef[StreamingTranslateSpeechResponse()];

declare 'SpeechEventType',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Mediatranslation::V1beta1::MediaTranslation::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
