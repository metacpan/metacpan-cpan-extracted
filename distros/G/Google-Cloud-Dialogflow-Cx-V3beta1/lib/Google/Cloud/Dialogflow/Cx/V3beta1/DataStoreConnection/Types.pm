package Google::Cloud::Dialogflow::Cx::V3beta1::DataStoreConnection::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'DataStoreType',
    as (Int | Str);

declare 'DocumentProcessingMode',
    as (Int | Str);

declare 'DataStoreConnection',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::DataStoreConnection::DataStoreConnection'];

coerce 'DataStoreConnection',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::DataStoreConnection::DataStoreConnection'->new($_) };

declare 'RepeatedDataStoreConnection',
    as ArrayRef[DataStoreConnection()];

coerce 'RepeatedDataStoreConnection',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::DataStoreConnection::DataStoreConnection'->new($_) } @$_ ] };

declare 'MapStringDataStoreConnection',
    as HashRef[DataStoreConnection()];

declare 'DataStoreConnectionSignals',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::DataStoreConnection::DataStoreConnectionSignals'];

coerce 'DataStoreConnectionSignals',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::DataStoreConnection::DataStoreConnectionSignals'->new($_) };

declare 'RepeatedDataStoreConnectionSignals',
    as ArrayRef[DataStoreConnectionSignals()];

coerce 'RepeatedDataStoreConnectionSignals',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::DataStoreConnection::DataStoreConnectionSignals'->new($_) } @$_ ] };

declare 'MapStringDataStoreConnectionSignals',
    as HashRef[DataStoreConnectionSignals()];

declare 'RewriterModelCallSignals',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::DataStoreConnection::DataStoreConnectionSignals::RewriterModelCallSignals'];

coerce 'RewriterModelCallSignals',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::DataStoreConnection::DataStoreConnectionSignals::RewriterModelCallSignals'->new($_) };

declare 'RepeatedRewriterModelCallSignals',
    as ArrayRef[RewriterModelCallSignals()];

coerce 'RepeatedRewriterModelCallSignals',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::DataStoreConnection::DataStoreConnectionSignals::RewriterModelCallSignals'->new($_) } @$_ ] };

declare 'MapStringRewriterModelCallSignals',
    as HashRef[RewriterModelCallSignals()];

declare 'SearchSnippet',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::DataStoreConnection::DataStoreConnectionSignals::SearchSnippet'];

coerce 'SearchSnippet',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::DataStoreConnection::DataStoreConnectionSignals::SearchSnippet'->new($_) };

declare 'RepeatedSearchSnippet',
    as ArrayRef[SearchSnippet()];

coerce 'RepeatedSearchSnippet',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::DataStoreConnection::DataStoreConnectionSignals::SearchSnippet'->new($_) } @$_ ] };

declare 'MapStringSearchSnippet',
    as HashRef[SearchSnippet()];

declare 'AnswerGenerationModelCallSignals',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::DataStoreConnection::DataStoreConnectionSignals::AnswerGenerationModelCallSignals'];

coerce 'AnswerGenerationModelCallSignals',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::DataStoreConnection::DataStoreConnectionSignals::AnswerGenerationModelCallSignals'->new($_) };

declare 'RepeatedAnswerGenerationModelCallSignals',
    as ArrayRef[AnswerGenerationModelCallSignals()];

coerce 'RepeatedAnswerGenerationModelCallSignals',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::DataStoreConnection::DataStoreConnectionSignals::AnswerGenerationModelCallSignals'->new($_) } @$_ ] };

declare 'MapStringAnswerGenerationModelCallSignals',
    as HashRef[AnswerGenerationModelCallSignals()];

declare 'AnswerPart',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::DataStoreConnection::DataStoreConnectionSignals::AnswerPart'];

coerce 'AnswerPart',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::DataStoreConnection::DataStoreConnectionSignals::AnswerPart'->new($_) };

declare 'RepeatedAnswerPart',
    as ArrayRef[AnswerPart()];

coerce 'RepeatedAnswerPart',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::DataStoreConnection::DataStoreConnectionSignals::AnswerPart'->new($_) } @$_ ] };

declare 'MapStringAnswerPart',
    as HashRef[AnswerPart()];

declare 'CitedSnippet',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::DataStoreConnection::DataStoreConnectionSignals::CitedSnippet'];

coerce 'CitedSnippet',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::DataStoreConnection::DataStoreConnectionSignals::CitedSnippet'->new($_) };

declare 'RepeatedCitedSnippet',
    as ArrayRef[CitedSnippet()];

coerce 'RepeatedCitedSnippet',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::DataStoreConnection::DataStoreConnectionSignals::CitedSnippet'->new($_) } @$_ ] };

declare 'MapStringCitedSnippet',
    as HashRef[CitedSnippet()];

declare 'GroundingSignals',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::DataStoreConnection::DataStoreConnectionSignals::GroundingSignals'];

coerce 'GroundingSignals',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::DataStoreConnection::DataStoreConnectionSignals::GroundingSignals'->new($_) };

declare 'RepeatedGroundingSignals',
    as ArrayRef[GroundingSignals()];

coerce 'RepeatedGroundingSignals',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::DataStoreConnection::DataStoreConnectionSignals::GroundingSignals'->new($_) } @$_ ] };

declare 'MapStringGroundingSignals',
    as HashRef[GroundingSignals()];

declare 'GroundingDecision',
    as (Int | Str);

declare 'GroundingScoreBucket',
    as (Int | Str);

declare 'SafetySignals',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::DataStoreConnection::DataStoreConnectionSignals::SafetySignals'];

coerce 'SafetySignals',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::DataStoreConnection::DataStoreConnectionSignals::SafetySignals'->new($_) };

declare 'RepeatedSafetySignals',
    as ArrayRef[SafetySignals()];

coerce 'RepeatedSafetySignals',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::DataStoreConnection::DataStoreConnectionSignals::SafetySignals'->new($_) } @$_ ] };

declare 'MapStringSafetySignals',
    as HashRef[SafetySignals()];

declare 'SafetyDecision',
    as (Int | Str);

declare 'BannedPhraseMatch',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Dialogflow::Cx::V3beta1::DataStoreConnection::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
