package Google::Cloud::Dialogflow::Cx::V3beta1::AdvancedSettings::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'AdvancedSettings',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::AdvancedSettings::AdvancedSettings'];

coerce 'AdvancedSettings',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::AdvancedSettings::AdvancedSettings'->new($_) };

declare 'RepeatedAdvancedSettings',
    as ArrayRef[AdvancedSettings()];

coerce 'RepeatedAdvancedSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::AdvancedSettings::AdvancedSettings'->new($_) } @$_ ] };

declare 'MapStringAdvancedSettings',
    as HashRef[AdvancedSettings()];

declare 'SpeechSettings',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::AdvancedSettings::AdvancedSettings::SpeechSettings'];

coerce 'SpeechSettings',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::AdvancedSettings::AdvancedSettings::SpeechSettings'->new($_) };

declare 'RepeatedSpeechSettings',
    as ArrayRef[SpeechSettings()];

coerce 'RepeatedSpeechSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::AdvancedSettings::AdvancedSettings::SpeechSettings'->new($_) } @$_ ] };

declare 'MapStringSpeechSettings',
    as HashRef[SpeechSettings()];

declare 'ModelsEntry',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::AdvancedSettings::AdvancedSettings::SpeechSettings::ModelsEntry'];

coerce 'ModelsEntry',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::AdvancedSettings::AdvancedSettings::SpeechSettings::ModelsEntry'->new($_) };

declare 'RepeatedModelsEntry',
    as ArrayRef[ModelsEntry()];

coerce 'RepeatedModelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::AdvancedSettings::AdvancedSettings::SpeechSettings::ModelsEntry'->new($_) } @$_ ] };

declare 'MapStringModelsEntry',
    as HashRef[ModelsEntry()];

declare 'DtmfSettings',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::AdvancedSettings::AdvancedSettings::DtmfSettings'];

coerce 'DtmfSettings',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::AdvancedSettings::AdvancedSettings::DtmfSettings'->new($_) };

declare 'RepeatedDtmfSettings',
    as ArrayRef[DtmfSettings()];

coerce 'RepeatedDtmfSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::AdvancedSettings::AdvancedSettings::DtmfSettings'->new($_) } @$_ ] };

declare 'MapStringDtmfSettings',
    as HashRef[DtmfSettings()];

declare 'LoggingSettings',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::AdvancedSettings::AdvancedSettings::LoggingSettings'];

coerce 'LoggingSettings',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::AdvancedSettings::AdvancedSettings::LoggingSettings'->new($_) };

declare 'RepeatedLoggingSettings',
    as ArrayRef[LoggingSettings()];

coerce 'RepeatedLoggingSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::AdvancedSettings::AdvancedSettings::LoggingSettings'->new($_) } @$_ ] };

declare 'MapStringLoggingSettings',
    as HashRef[LoggingSettings()];

1;

__END__

=head1 NAME

Google::Cloud::Dialogflow::Cx::V3beta1::AdvancedSettings::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
