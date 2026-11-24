package Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticPrompt::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'StaticPrompt',
    as InstanceOf['Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticPrompt::StaticPrompt'];

coerce 'StaticPrompt',
    from HashRef, via { 'Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticPrompt::StaticPrompt'->new($_) };

declare 'RepeatedStaticPrompt',
    as ArrayRef[StaticPrompt()];

coerce 'RepeatedStaticPrompt',
    from ArrayRef[HashRef], via { [ map { 'Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticPrompt::StaticPrompt'->new($_) } @$_ ] };

declare 'MapStringStaticPrompt',
    as HashRef[StaticPrompt()];

declare 'StaticPromptCandidate',
    as InstanceOf['Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticPrompt::StaticPrompt::StaticPromptCandidate'];

coerce 'StaticPromptCandidate',
    from HashRef, via { 'Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticPrompt::StaticPrompt::StaticPromptCandidate'->new($_) };

declare 'RepeatedStaticPromptCandidate',
    as ArrayRef[StaticPromptCandidate()];

coerce 'RepeatedStaticPromptCandidate',
    from ArrayRef[HashRef], via { [ map { 'Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticPrompt::StaticPrompt::StaticPromptCandidate'->new($_) } @$_ ] };

declare 'MapStringStaticPromptCandidate',
    as HashRef[StaticPromptCandidate()];

declare 'StaticPromptResponse',
    as InstanceOf['Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticPrompt::StaticPrompt::StaticPromptCandidate::StaticPromptResponse'];

coerce 'StaticPromptResponse',
    from HashRef, via { 'Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticPrompt::StaticPrompt::StaticPromptCandidate::StaticPromptResponse'->new($_) };

declare 'RepeatedStaticPromptResponse',
    as ArrayRef[StaticPromptResponse()];

coerce 'RepeatedStaticPromptResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticPrompt::StaticPrompt::StaticPromptCandidate::StaticPromptResponse'->new($_) } @$_ ] };

declare 'MapStringStaticPromptResponse',
    as HashRef[StaticPromptResponse()];

declare 'Selector',
    as InstanceOf['Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticPrompt::StaticPrompt::Selector'];

coerce 'Selector',
    from HashRef, via { 'Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticPrompt::StaticPrompt::Selector'->new($_) };

declare 'RepeatedSelector',
    as ArrayRef[Selector()];

coerce 'RepeatedSelector',
    from ArrayRef[HashRef], via { [ map { 'Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticPrompt::StaticPrompt::Selector'->new($_) } @$_ ] };

declare 'MapStringSelector',
    as HashRef[Selector()];

1;

__END__

=head1 NAME

Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticPrompt::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
