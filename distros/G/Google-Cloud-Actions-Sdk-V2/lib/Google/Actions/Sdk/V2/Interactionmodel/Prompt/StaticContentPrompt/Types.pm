package Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticContentPrompt::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'StaticContentPrompt',
    as InstanceOf['Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticContentPrompt::StaticContentPrompt'];

coerce 'StaticContentPrompt',
    from HashRef, via { 'Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticContentPrompt::StaticContentPrompt'->new($_) };

declare 'RepeatedStaticContentPrompt',
    as ArrayRef[StaticContentPrompt()];

coerce 'RepeatedStaticContentPrompt',
    from ArrayRef[HashRef], via { [ map { 'Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticContentPrompt::StaticContentPrompt'->new($_) } @$_ ] };

declare 'MapStringStaticContentPrompt',
    as HashRef[StaticContentPrompt()];

1;

__END__

=head1 NAME

Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticContentPrompt::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
