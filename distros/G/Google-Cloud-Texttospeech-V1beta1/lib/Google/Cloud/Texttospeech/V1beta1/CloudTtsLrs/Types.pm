package Google::Cloud::Texttospeech::V1beta1::CloudTtsLrs::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'SynthesizeLongAudioRequest',
    as InstanceOf['Google::Cloud::Texttospeech::V1beta1::CloudTtsLrs::SynthesizeLongAudioRequest'];

coerce 'SynthesizeLongAudioRequest',
    from HashRef, via { 'Google::Cloud::Texttospeech::V1beta1::CloudTtsLrs::SynthesizeLongAudioRequest'->new($_) };

declare 'RepeatedSynthesizeLongAudioRequest',
    as ArrayRef[SynthesizeLongAudioRequest()];

coerce 'RepeatedSynthesizeLongAudioRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Texttospeech::V1beta1::CloudTtsLrs::SynthesizeLongAudioRequest'->new($_) } @$_ ] };

declare 'MapStringSynthesizeLongAudioRequest',
    as HashRef[SynthesizeLongAudioRequest()];

declare 'SynthesizeLongAudioResponse',
    as InstanceOf['Google::Cloud::Texttospeech::V1beta1::CloudTtsLrs::SynthesizeLongAudioResponse'];

coerce 'SynthesizeLongAudioResponse',
    from HashRef, via { 'Google::Cloud::Texttospeech::V1beta1::CloudTtsLrs::SynthesizeLongAudioResponse'->new($_) };

declare 'RepeatedSynthesizeLongAudioResponse',
    as ArrayRef[SynthesizeLongAudioResponse()];

coerce 'RepeatedSynthesizeLongAudioResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Texttospeech::V1beta1::CloudTtsLrs::SynthesizeLongAudioResponse'->new($_) } @$_ ] };

declare 'MapStringSynthesizeLongAudioResponse',
    as HashRef[SynthesizeLongAudioResponse()];

declare 'SynthesizeLongAudioMetadata',
    as InstanceOf['Google::Cloud::Texttospeech::V1beta1::CloudTtsLrs::SynthesizeLongAudioMetadata'];

coerce 'SynthesizeLongAudioMetadata',
    from HashRef, via { 'Google::Cloud::Texttospeech::V1beta1::CloudTtsLrs::SynthesizeLongAudioMetadata'->new($_) };

declare 'RepeatedSynthesizeLongAudioMetadata',
    as ArrayRef[SynthesizeLongAudioMetadata()];

coerce 'RepeatedSynthesizeLongAudioMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Texttospeech::V1beta1::CloudTtsLrs::SynthesizeLongAudioMetadata'->new($_) } @$_ ] };

declare 'MapStringSynthesizeLongAudioMetadata',
    as HashRef[SynthesizeLongAudioMetadata()];

1;

__END__

=head1 NAME

Google::Cloud::Texttospeech::V1beta1::CloudTtsLrs::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
