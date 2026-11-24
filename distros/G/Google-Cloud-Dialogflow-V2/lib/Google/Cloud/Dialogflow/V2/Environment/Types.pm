package Google::Cloud::Dialogflow::V2::Environment::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Environment',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Environment::Environment'];

coerce 'Environment',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Environment::Environment'->new($_) };

declare 'RepeatedEnvironment',
    as ArrayRef[Environment()];

coerce 'RepeatedEnvironment',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Environment::Environment'->new($_) } @$_ ] };

declare 'MapStringEnvironment',
    as HashRef[Environment()];

declare 'State',
    as (Int | Str);

declare 'TextToSpeechSettings',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Environment::TextToSpeechSettings'];

coerce 'TextToSpeechSettings',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Environment::TextToSpeechSettings'->new($_) };

declare 'RepeatedTextToSpeechSettings',
    as ArrayRef[TextToSpeechSettings()];

coerce 'RepeatedTextToSpeechSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Environment::TextToSpeechSettings'->new($_) } @$_ ] };

declare 'MapStringTextToSpeechSettings',
    as HashRef[TextToSpeechSettings()];

declare 'SynthesizeSpeechConfigsEntry',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Environment::TextToSpeechSettings::SynthesizeSpeechConfigsEntry'];

coerce 'SynthesizeSpeechConfigsEntry',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Environment::TextToSpeechSettings::SynthesizeSpeechConfigsEntry'->new($_) };

declare 'RepeatedSynthesizeSpeechConfigsEntry',
    as ArrayRef[SynthesizeSpeechConfigsEntry()];

coerce 'RepeatedSynthesizeSpeechConfigsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Environment::TextToSpeechSettings::SynthesizeSpeechConfigsEntry'->new($_) } @$_ ] };

declare 'MapStringSynthesizeSpeechConfigsEntry',
    as HashRef[SynthesizeSpeechConfigsEntry()];

declare 'ListEnvironmentsRequest',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Environment::ListEnvironmentsRequest'];

coerce 'ListEnvironmentsRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Environment::ListEnvironmentsRequest'->new($_) };

declare 'RepeatedListEnvironmentsRequest',
    as ArrayRef[ListEnvironmentsRequest()];

coerce 'RepeatedListEnvironmentsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Environment::ListEnvironmentsRequest'->new($_) } @$_ ] };

declare 'MapStringListEnvironmentsRequest',
    as HashRef[ListEnvironmentsRequest()];

declare 'ListEnvironmentsResponse',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Environment::ListEnvironmentsResponse'];

coerce 'ListEnvironmentsResponse',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Environment::ListEnvironmentsResponse'->new($_) };

declare 'RepeatedListEnvironmentsResponse',
    as ArrayRef[ListEnvironmentsResponse()];

coerce 'RepeatedListEnvironmentsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Environment::ListEnvironmentsResponse'->new($_) } @$_ ] };

declare 'MapStringListEnvironmentsResponse',
    as HashRef[ListEnvironmentsResponse()];

declare 'GetEnvironmentRequest',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Environment::GetEnvironmentRequest'];

coerce 'GetEnvironmentRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Environment::GetEnvironmentRequest'->new($_) };

declare 'RepeatedGetEnvironmentRequest',
    as ArrayRef[GetEnvironmentRequest()];

coerce 'RepeatedGetEnvironmentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Environment::GetEnvironmentRequest'->new($_) } @$_ ] };

declare 'MapStringGetEnvironmentRequest',
    as HashRef[GetEnvironmentRequest()];

declare 'CreateEnvironmentRequest',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Environment::CreateEnvironmentRequest'];

coerce 'CreateEnvironmentRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Environment::CreateEnvironmentRequest'->new($_) };

declare 'RepeatedCreateEnvironmentRequest',
    as ArrayRef[CreateEnvironmentRequest()];

coerce 'RepeatedCreateEnvironmentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Environment::CreateEnvironmentRequest'->new($_) } @$_ ] };

declare 'MapStringCreateEnvironmentRequest',
    as HashRef[CreateEnvironmentRequest()];

declare 'UpdateEnvironmentRequest',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Environment::UpdateEnvironmentRequest'];

coerce 'UpdateEnvironmentRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Environment::UpdateEnvironmentRequest'->new($_) };

declare 'RepeatedUpdateEnvironmentRequest',
    as ArrayRef[UpdateEnvironmentRequest()];

coerce 'RepeatedUpdateEnvironmentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Environment::UpdateEnvironmentRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateEnvironmentRequest',
    as HashRef[UpdateEnvironmentRequest()];

declare 'DeleteEnvironmentRequest',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Environment::DeleteEnvironmentRequest'];

coerce 'DeleteEnvironmentRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Environment::DeleteEnvironmentRequest'->new($_) };

declare 'RepeatedDeleteEnvironmentRequest',
    as ArrayRef[DeleteEnvironmentRequest()];

coerce 'RepeatedDeleteEnvironmentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Environment::DeleteEnvironmentRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteEnvironmentRequest',
    as HashRef[DeleteEnvironmentRequest()];

declare 'GetEnvironmentHistoryRequest',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Environment::GetEnvironmentHistoryRequest'];

coerce 'GetEnvironmentHistoryRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Environment::GetEnvironmentHistoryRequest'->new($_) };

declare 'RepeatedGetEnvironmentHistoryRequest',
    as ArrayRef[GetEnvironmentHistoryRequest()];

coerce 'RepeatedGetEnvironmentHistoryRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Environment::GetEnvironmentHistoryRequest'->new($_) } @$_ ] };

declare 'MapStringGetEnvironmentHistoryRequest',
    as HashRef[GetEnvironmentHistoryRequest()];

declare 'EnvironmentHistory',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Environment::EnvironmentHistory'];

coerce 'EnvironmentHistory',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Environment::EnvironmentHistory'->new($_) };

declare 'RepeatedEnvironmentHistory',
    as ArrayRef[EnvironmentHistory()];

coerce 'RepeatedEnvironmentHistory',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Environment::EnvironmentHistory'->new($_) } @$_ ] };

declare 'MapStringEnvironmentHistory',
    as HashRef[EnvironmentHistory()];

declare 'Entry',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Environment::EnvironmentHistory::Entry'];

coerce 'Entry',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Environment::EnvironmentHistory::Entry'->new($_) };

declare 'RepeatedEntry',
    as ArrayRef[Entry()];

coerce 'RepeatedEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Environment::EnvironmentHistory::Entry'->new($_) } @$_ ] };

declare 'MapStringEntry',
    as HashRef[Entry()];

1;

__END__

=head1 NAME

Google::Cloud::Dialogflow::V2::Environment::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
