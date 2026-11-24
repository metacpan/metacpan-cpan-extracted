package Google::Cloud::Dialogflow::Cx::V3::GenerativeSettings::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'GenerativeSettings',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::GenerativeSettings::GenerativeSettings'];

coerce 'GenerativeSettings',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::GenerativeSettings::GenerativeSettings'->new($_) };

declare 'RepeatedGenerativeSettings',
    as ArrayRef[GenerativeSettings()];

coerce 'RepeatedGenerativeSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::GenerativeSettings::GenerativeSettings'->new($_) } @$_ ] };

declare 'MapStringGenerativeSettings',
    as HashRef[GenerativeSettings()];

declare 'FallbackSettings',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::GenerativeSettings::GenerativeSettings::FallbackSettings'];

coerce 'FallbackSettings',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::GenerativeSettings::GenerativeSettings::FallbackSettings'->new($_) };

declare 'RepeatedFallbackSettings',
    as ArrayRef[FallbackSettings()];

coerce 'RepeatedFallbackSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::GenerativeSettings::GenerativeSettings::FallbackSettings'->new($_) } @$_ ] };

declare 'MapStringFallbackSettings',
    as HashRef[FallbackSettings()];

declare 'PromptTemplate',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::GenerativeSettings::GenerativeSettings::FallbackSettings::PromptTemplate'];

coerce 'PromptTemplate',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::GenerativeSettings::GenerativeSettings::FallbackSettings::PromptTemplate'->new($_) };

declare 'RepeatedPromptTemplate',
    as ArrayRef[PromptTemplate()];

coerce 'RepeatedPromptTemplate',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::GenerativeSettings::GenerativeSettings::FallbackSettings::PromptTemplate'->new($_) } @$_ ] };

declare 'MapStringPromptTemplate',
    as HashRef[PromptTemplate()];

declare 'KnowledgeConnectorSettings',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::GenerativeSettings::GenerativeSettings::KnowledgeConnectorSettings'];

coerce 'KnowledgeConnectorSettings',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::GenerativeSettings::GenerativeSettings::KnowledgeConnectorSettings'->new($_) };

declare 'RepeatedKnowledgeConnectorSettings',
    as ArrayRef[KnowledgeConnectorSettings()];

coerce 'RepeatedKnowledgeConnectorSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::GenerativeSettings::GenerativeSettings::KnowledgeConnectorSettings'->new($_) } @$_ ] };

declare 'MapStringKnowledgeConnectorSettings',
    as HashRef[KnowledgeConnectorSettings()];

declare 'LlmModelSettings',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::GenerativeSettings::LlmModelSettings'];

coerce 'LlmModelSettings',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::GenerativeSettings::LlmModelSettings'->new($_) };

declare 'RepeatedLlmModelSettings',
    as ArrayRef[LlmModelSettings()];

coerce 'RepeatedLlmModelSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::GenerativeSettings::LlmModelSettings'->new($_) } @$_ ] };

declare 'MapStringLlmModelSettings',
    as HashRef[LlmModelSettings()];

1;

__END__

=head1 NAME

Google::Cloud::Dialogflow::Cx::V3::GenerativeSettings::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
