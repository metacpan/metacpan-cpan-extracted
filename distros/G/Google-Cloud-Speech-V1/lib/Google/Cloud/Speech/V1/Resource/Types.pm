package Google::Cloud::Speech::V1::Resource::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'CustomClass',
    as InstanceOf['Google::Cloud::Speech::V1::Resource::CustomClass'];

coerce 'CustomClass',
    from HashRef, via { 'Google::Cloud::Speech::V1::Resource::CustomClass'->new($_) };

declare 'RepeatedCustomClass',
    as ArrayRef[CustomClass()];

coerce 'RepeatedCustomClass',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Speech::V1::Resource::CustomClass'->new($_) } @$_ ] };

declare 'MapStringCustomClass',
    as HashRef[CustomClass()];

declare 'ClassItem',
    as InstanceOf['Google::Cloud::Speech::V1::Resource::CustomClass::ClassItem'];

coerce 'ClassItem',
    from HashRef, via { 'Google::Cloud::Speech::V1::Resource::CustomClass::ClassItem'->new($_) };

declare 'RepeatedClassItem',
    as ArrayRef[ClassItem()];

coerce 'RepeatedClassItem',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Speech::V1::Resource::CustomClass::ClassItem'->new($_) } @$_ ] };

declare 'MapStringClassItem',
    as HashRef[ClassItem()];

declare 'PhraseSet',
    as InstanceOf['Google::Cloud::Speech::V1::Resource::PhraseSet'];

coerce 'PhraseSet',
    from HashRef, via { 'Google::Cloud::Speech::V1::Resource::PhraseSet'->new($_) };

declare 'RepeatedPhraseSet',
    as ArrayRef[PhraseSet()];

coerce 'RepeatedPhraseSet',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Speech::V1::Resource::PhraseSet'->new($_) } @$_ ] };

declare 'MapStringPhraseSet',
    as HashRef[PhraseSet()];

declare 'Phrase',
    as InstanceOf['Google::Cloud::Speech::V1::Resource::PhraseSet::Phrase'];

coerce 'Phrase',
    from HashRef, via { 'Google::Cloud::Speech::V1::Resource::PhraseSet::Phrase'->new($_) };

declare 'RepeatedPhrase',
    as ArrayRef[Phrase()];

coerce 'RepeatedPhrase',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Speech::V1::Resource::PhraseSet::Phrase'->new($_) } @$_ ] };

declare 'MapStringPhrase',
    as HashRef[Phrase()];

declare 'SpeechAdaptation',
    as InstanceOf['Google::Cloud::Speech::V1::Resource::SpeechAdaptation'];

coerce 'SpeechAdaptation',
    from HashRef, via { 'Google::Cloud::Speech::V1::Resource::SpeechAdaptation'->new($_) };

declare 'RepeatedSpeechAdaptation',
    as ArrayRef[SpeechAdaptation()];

coerce 'RepeatedSpeechAdaptation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Speech::V1::Resource::SpeechAdaptation'->new($_) } @$_ ] };

declare 'MapStringSpeechAdaptation',
    as HashRef[SpeechAdaptation()];

declare 'ABNFGrammar',
    as InstanceOf['Google::Cloud::Speech::V1::Resource::SpeechAdaptation::ABNFGrammar'];

coerce 'ABNFGrammar',
    from HashRef, via { 'Google::Cloud::Speech::V1::Resource::SpeechAdaptation::ABNFGrammar'->new($_) };

declare 'RepeatedABNFGrammar',
    as ArrayRef[ABNFGrammar()];

coerce 'RepeatedABNFGrammar',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Speech::V1::Resource::SpeechAdaptation::ABNFGrammar'->new($_) } @$_ ] };

declare 'MapStringABNFGrammar',
    as HashRef[ABNFGrammar()];

declare 'TranscriptNormalization',
    as InstanceOf['Google::Cloud::Speech::V1::Resource::TranscriptNormalization'];

coerce 'TranscriptNormalization',
    from HashRef, via { 'Google::Cloud::Speech::V1::Resource::TranscriptNormalization'->new($_) };

declare 'RepeatedTranscriptNormalization',
    as ArrayRef[TranscriptNormalization()];

coerce 'RepeatedTranscriptNormalization',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Speech::V1::Resource::TranscriptNormalization'->new($_) } @$_ ] };

declare 'MapStringTranscriptNormalization',
    as HashRef[TranscriptNormalization()];

declare 'Entry',
    as InstanceOf['Google::Cloud::Speech::V1::Resource::TranscriptNormalization::Entry'];

coerce 'Entry',
    from HashRef, via { 'Google::Cloud::Speech::V1::Resource::TranscriptNormalization::Entry'->new($_) };

declare 'RepeatedEntry',
    as ArrayRef[Entry()];

coerce 'RepeatedEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Speech::V1::Resource::TranscriptNormalization::Entry'->new($_) } @$_ ] };

declare 'MapStringEntry',
    as HashRef[Entry()];

1;

__END__

=head1 NAME

Google::Cloud::Speech::V1::Resource::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
