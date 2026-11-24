package Google::Cloud::Discoveryengine::V1beta::Assistant::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Assistant',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::Assistant::Assistant'];

coerce 'Assistant',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::Assistant::Assistant'->new($_) };

declare 'RepeatedAssistant',
    as ArrayRef[Assistant()];

coerce 'RepeatedAssistant',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::Assistant::Assistant'->new($_) } @$_ ] };

declare 'MapStringAssistant',
    as HashRef[Assistant()];

declare 'WebGroundingType',
    as (Int | Str);

declare 'GenerationConfig',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::Assistant::Assistant::GenerationConfig'];

coerce 'GenerationConfig',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::Assistant::Assistant::GenerationConfig'->new($_) };

declare 'RepeatedGenerationConfig',
    as ArrayRef[GenerationConfig()];

coerce 'RepeatedGenerationConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::Assistant::Assistant::GenerationConfig'->new($_) } @$_ ] };

declare 'MapStringGenerationConfig',
    as HashRef[GenerationConfig()];

declare 'SystemInstruction',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::Assistant::Assistant::GenerationConfig::SystemInstruction'];

coerce 'SystemInstruction',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::Assistant::Assistant::GenerationConfig::SystemInstruction'->new($_) };

declare 'RepeatedSystemInstruction',
    as ArrayRef[SystemInstruction()];

coerce 'RepeatedSystemInstruction',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::Assistant::Assistant::GenerationConfig::SystemInstruction'->new($_) } @$_ ] };

declare 'MapStringSystemInstruction',
    as HashRef[SystemInstruction()];

declare 'ToolInfo',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::Assistant::Assistant::ToolInfo'];

coerce 'ToolInfo',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::Assistant::Assistant::ToolInfo'->new($_) };

declare 'RepeatedToolInfo',
    as ArrayRef[ToolInfo()];

coerce 'RepeatedToolInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::Assistant::Assistant::ToolInfo'->new($_) } @$_ ] };

declare 'MapStringToolInfo',
    as HashRef[ToolInfo()];

declare 'ToolList',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::Assistant::Assistant::ToolList'];

coerce 'ToolList',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::Assistant::Assistant::ToolList'->new($_) };

declare 'RepeatedToolList',
    as ArrayRef[ToolList()];

coerce 'RepeatedToolList',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::Assistant::Assistant::ToolList'->new($_) } @$_ ] };

declare 'MapStringToolList',
    as HashRef[ToolList()];

declare 'CustomerPolicy',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::Assistant::Assistant::CustomerPolicy'];

coerce 'CustomerPolicy',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::Assistant::Assistant::CustomerPolicy'->new($_) };

declare 'RepeatedCustomerPolicy',
    as ArrayRef[CustomerPolicy()];

coerce 'RepeatedCustomerPolicy',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::Assistant::Assistant::CustomerPolicy'->new($_) } @$_ ] };

declare 'MapStringCustomerPolicy',
    as HashRef[CustomerPolicy()];

declare 'BannedPhrase',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::Assistant::Assistant::CustomerPolicy::BannedPhrase'];

coerce 'BannedPhrase',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::Assistant::Assistant::CustomerPolicy::BannedPhrase'->new($_) };

declare 'RepeatedBannedPhrase',
    as ArrayRef[BannedPhrase()];

coerce 'RepeatedBannedPhrase',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::Assistant::Assistant::CustomerPolicy::BannedPhrase'->new($_) } @$_ ] };

declare 'MapStringBannedPhrase',
    as HashRef[BannedPhrase()];

declare 'BannedPhraseMatchType',
    as (Int | Str);

declare 'ModelArmorConfig',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::Assistant::Assistant::CustomerPolicy::ModelArmorConfig'];

coerce 'ModelArmorConfig',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::Assistant::Assistant::CustomerPolicy::ModelArmorConfig'->new($_) };

declare 'RepeatedModelArmorConfig',
    as ArrayRef[ModelArmorConfig()];

coerce 'RepeatedModelArmorConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::Assistant::Assistant::CustomerPolicy::ModelArmorConfig'->new($_) } @$_ ] };

declare 'MapStringModelArmorConfig',
    as HashRef[ModelArmorConfig()];

declare 'FailureMode',
    as (Int | Str);

declare 'EnabledToolsEntry',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::Assistant::Assistant::EnabledToolsEntry'];

coerce 'EnabledToolsEntry',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::Assistant::Assistant::EnabledToolsEntry'->new($_) };

declare 'RepeatedEnabledToolsEntry',
    as ArrayRef[EnabledToolsEntry()];

coerce 'RepeatedEnabledToolsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::Assistant::Assistant::EnabledToolsEntry'->new($_) } @$_ ] };

declare 'MapStringEnabledToolsEntry',
    as HashRef[EnabledToolsEntry()];

1;

__END__

=head1 NAME

Google::Cloud::Discoveryengine::V1beta::Assistant::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
