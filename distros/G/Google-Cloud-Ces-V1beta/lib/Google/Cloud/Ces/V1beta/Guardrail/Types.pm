package Google::Cloud::Ces::V1beta::Guardrail::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Guardrail',
    as InstanceOf['Google::Cloud::Ces::V1beta::Guardrail::Guardrail'];

coerce 'Guardrail',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::Guardrail::Guardrail'->new($_) };

declare 'RepeatedGuardrail',
    as ArrayRef[Guardrail()];

coerce 'RepeatedGuardrail',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::Guardrail::Guardrail'->new($_) } @$_ ] };

declare 'MapStringGuardrail',
    as HashRef[Guardrail()];

declare 'ContentFilter',
    as InstanceOf['Google::Cloud::Ces::V1beta::Guardrail::Guardrail::ContentFilter'];

coerce 'ContentFilter',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::Guardrail::Guardrail::ContentFilter'->new($_) };

declare 'RepeatedContentFilter',
    as ArrayRef[ContentFilter()];

coerce 'RepeatedContentFilter',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::Guardrail::Guardrail::ContentFilter'->new($_) } @$_ ] };

declare 'MapStringContentFilter',
    as HashRef[ContentFilter()];

declare 'MatchType',
    as (Int | Str);

declare 'LlmPromptSecurity',
    as InstanceOf['Google::Cloud::Ces::V1beta::Guardrail::Guardrail::LlmPromptSecurity'];

coerce 'LlmPromptSecurity',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::Guardrail::Guardrail::LlmPromptSecurity'->new($_) };

declare 'RepeatedLlmPromptSecurity',
    as ArrayRef[LlmPromptSecurity()];

coerce 'RepeatedLlmPromptSecurity',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::Guardrail::Guardrail::LlmPromptSecurity'->new($_) } @$_ ] };

declare 'MapStringLlmPromptSecurity',
    as HashRef[LlmPromptSecurity()];

declare 'DefaultSecuritySettings',
    as InstanceOf['Google::Cloud::Ces::V1beta::Guardrail::Guardrail::LlmPromptSecurity::DefaultSecuritySettings'];

coerce 'DefaultSecuritySettings',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::Guardrail::Guardrail::LlmPromptSecurity::DefaultSecuritySettings'->new($_) };

declare 'RepeatedDefaultSecuritySettings',
    as ArrayRef[DefaultSecuritySettings()];

coerce 'RepeatedDefaultSecuritySettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::Guardrail::Guardrail::LlmPromptSecurity::DefaultSecuritySettings'->new($_) } @$_ ] };

declare 'MapStringDefaultSecuritySettings',
    as HashRef[DefaultSecuritySettings()];

declare 'LlmPolicy',
    as InstanceOf['Google::Cloud::Ces::V1beta::Guardrail::Guardrail::LlmPolicy'];

coerce 'LlmPolicy',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::Guardrail::Guardrail::LlmPolicy'->new($_) };

declare 'RepeatedLlmPolicy',
    as ArrayRef[LlmPolicy()];

coerce 'RepeatedLlmPolicy',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::Guardrail::Guardrail::LlmPolicy'->new($_) } @$_ ] };

declare 'MapStringLlmPolicy',
    as HashRef[LlmPolicy()];

declare 'PolicyScope',
    as (Int | Str);

declare 'ModelSafety',
    as InstanceOf['Google::Cloud::Ces::V1beta::Guardrail::Guardrail::ModelSafety'];

coerce 'ModelSafety',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::Guardrail::Guardrail::ModelSafety'->new($_) };

declare 'RepeatedModelSafety',
    as ArrayRef[ModelSafety()];

coerce 'RepeatedModelSafety',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::Guardrail::Guardrail::ModelSafety'->new($_) } @$_ ] };

declare 'MapStringModelSafety',
    as HashRef[ModelSafety()];

declare 'HarmCategory',
    as (Int | Str);

declare 'HarmBlockThreshold',
    as (Int | Str);

declare 'SafetySetting',
    as InstanceOf['Google::Cloud::Ces::V1beta::Guardrail::Guardrail::ModelSafety::SafetySetting'];

coerce 'SafetySetting',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::Guardrail::Guardrail::ModelSafety::SafetySetting'->new($_) };

declare 'RepeatedSafetySetting',
    as ArrayRef[SafetySetting()];

coerce 'RepeatedSafetySetting',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::Guardrail::Guardrail::ModelSafety::SafetySetting'->new($_) } @$_ ] };

declare 'MapStringSafetySetting',
    as HashRef[SafetySetting()];

declare 'CodeCallback',
    as InstanceOf['Google::Cloud::Ces::V1beta::Guardrail::Guardrail::CodeCallback'];

coerce 'CodeCallback',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::Guardrail::Guardrail::CodeCallback'->new($_) };

declare 'RepeatedCodeCallback',
    as ArrayRef[CodeCallback()];

coerce 'RepeatedCodeCallback',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::Guardrail::Guardrail::CodeCallback'->new($_) } @$_ ] };

declare 'MapStringCodeCallback',
    as HashRef[CodeCallback()];

declare 'Supervisor',
    as InstanceOf['Google::Cloud::Ces::V1beta::Guardrail::Guardrail::Supervisor'];

coerce 'Supervisor',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::Guardrail::Guardrail::Supervisor'->new($_) };

declare 'RepeatedSupervisor',
    as ArrayRef[Supervisor()];

coerce 'RepeatedSupervisor',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::Guardrail::Guardrail::Supervisor'->new($_) } @$_ ] };

declare 'MapStringSupervisor',
    as HashRef[Supervisor()];

declare 'Type',
    as (Int | Str);

declare 'DetectionMode',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Ces::V1beta::Guardrail::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
