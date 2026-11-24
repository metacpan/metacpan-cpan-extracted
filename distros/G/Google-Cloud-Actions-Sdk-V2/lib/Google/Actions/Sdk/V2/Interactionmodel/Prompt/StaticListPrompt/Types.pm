package Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticListPrompt::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'StaticListPrompt',
    as InstanceOf['Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticListPrompt::StaticListPrompt'];

coerce 'StaticListPrompt',
    from HashRef, via { 'Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticListPrompt::StaticListPrompt'->new($_) };

declare 'RepeatedStaticListPrompt',
    as ArrayRef[StaticListPrompt()];

coerce 'RepeatedStaticListPrompt',
    from ArrayRef[HashRef], via { [ map { 'Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticListPrompt::StaticListPrompt'->new($_) } @$_ ] };

declare 'MapStringStaticListPrompt',
    as HashRef[StaticListPrompt()];

declare 'ListItem',
    as InstanceOf['Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticListPrompt::StaticListPrompt::ListItem'];

coerce 'ListItem',
    from HashRef, via { 'Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticListPrompt::StaticListPrompt::ListItem'->new($_) };

declare 'RepeatedListItem',
    as ArrayRef[ListItem()];

coerce 'RepeatedListItem',
    from ArrayRef[HashRef], via { [ map { 'Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticListPrompt::StaticListPrompt::ListItem'->new($_) } @$_ ] };

declare 'MapStringListItem',
    as HashRef[ListItem()];

1;

__END__

=head1 NAME

Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticListPrompt::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
