package Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticCanvasPrompt::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'StaticCanvasPrompt',
    as InstanceOf['Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticCanvasPrompt::StaticCanvasPrompt'];

coerce 'StaticCanvasPrompt',
    from HashRef, via { 'Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticCanvasPrompt::StaticCanvasPrompt'->new($_) };

declare 'RepeatedStaticCanvasPrompt',
    as ArrayRef[StaticCanvasPrompt()];

coerce 'RepeatedStaticCanvasPrompt',
    from ArrayRef[HashRef], via { [ map { 'Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticCanvasPrompt::StaticCanvasPrompt'->new($_) } @$_ ] };

declare 'MapStringStaticCanvasPrompt',
    as HashRef[StaticCanvasPrompt()];

1;

__END__

=head1 NAME

Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticCanvasPrompt::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
