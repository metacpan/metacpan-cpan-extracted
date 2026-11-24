package Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticCardPrompt::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'StaticCardPrompt',
    as InstanceOf['Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticCardPrompt::StaticCardPrompt'];

coerce 'StaticCardPrompt',
    from HashRef, via { 'Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticCardPrompt::StaticCardPrompt'->new($_) };

declare 'RepeatedStaticCardPrompt',
    as ArrayRef[StaticCardPrompt()];

coerce 'RepeatedStaticCardPrompt',
    from ArrayRef[HashRef], via { [ map { 'Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticCardPrompt::StaticCardPrompt'->new($_) } @$_ ] };

declare 'MapStringStaticCardPrompt',
    as HashRef[StaticCardPrompt()];

1;

__END__

=head1 NAME

Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticCardPrompt::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
