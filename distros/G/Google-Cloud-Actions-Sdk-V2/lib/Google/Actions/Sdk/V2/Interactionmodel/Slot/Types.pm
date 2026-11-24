package Google::Actions::Sdk::V2::Interactionmodel::Slot::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Slot',
    as InstanceOf['Google::Actions::Sdk::V2::Interactionmodel::Slot::Slot'];

coerce 'Slot',
    from HashRef, via { 'Google::Actions::Sdk::V2::Interactionmodel::Slot::Slot'->new($_) };

declare 'RepeatedSlot',
    as ArrayRef[Slot()];

coerce 'RepeatedSlot',
    from ArrayRef[HashRef], via { [ map { 'Google::Actions::Sdk::V2::Interactionmodel::Slot::Slot'->new($_) } @$_ ] };

declare 'MapStringSlot',
    as HashRef[Slot()];

declare 'PromptSettings',
    as InstanceOf['Google::Actions::Sdk::V2::Interactionmodel::Slot::Slot::PromptSettings'];

coerce 'PromptSettings',
    from HashRef, via { 'Google::Actions::Sdk::V2::Interactionmodel::Slot::Slot::PromptSettings'->new($_) };

declare 'RepeatedPromptSettings',
    as ArrayRef[PromptSettings()];

coerce 'RepeatedPromptSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Actions::Sdk::V2::Interactionmodel::Slot::Slot::PromptSettings'->new($_) } @$_ ] };

declare 'MapStringPromptSettings',
    as HashRef[PromptSettings()];

declare 'CommitBehavior',
    as InstanceOf['Google::Actions::Sdk::V2::Interactionmodel::Slot::Slot::CommitBehavior'];

coerce 'CommitBehavior',
    from HashRef, via { 'Google::Actions::Sdk::V2::Interactionmodel::Slot::Slot::CommitBehavior'->new($_) };

declare 'RepeatedCommitBehavior',
    as ArrayRef[CommitBehavior()];

coerce 'RepeatedCommitBehavior',
    from ArrayRef[HashRef], via { [ map { 'Google::Actions::Sdk::V2::Interactionmodel::Slot::Slot::CommitBehavior'->new($_) } @$_ ] };

declare 'MapStringCommitBehavior',
    as HashRef[CommitBehavior()];

declare 'DefaultValue',
    as InstanceOf['Google::Actions::Sdk::V2::Interactionmodel::Slot::Slot::DefaultValue'];

coerce 'DefaultValue',
    from HashRef, via { 'Google::Actions::Sdk::V2::Interactionmodel::Slot::Slot::DefaultValue'->new($_) };

declare 'RepeatedDefaultValue',
    as ArrayRef[DefaultValue()];

coerce 'RepeatedDefaultValue',
    from ArrayRef[HashRef], via { [ map { 'Google::Actions::Sdk::V2::Interactionmodel::Slot::Slot::DefaultValue'->new($_) } @$_ ] };

declare 'MapStringDefaultValue',
    as HashRef[DefaultValue()];

1;

__END__

=head1 NAME

Google::Actions::Sdk::V2::Interactionmodel::Slot::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
