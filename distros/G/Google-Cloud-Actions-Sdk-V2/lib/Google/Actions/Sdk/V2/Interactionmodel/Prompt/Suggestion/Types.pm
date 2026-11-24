package Google::Actions::Sdk::V2::Interactionmodel::Prompt::Suggestion::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Suggestion',
    as InstanceOf['Google::Actions::Sdk::V2::Interactionmodel::Prompt::Suggestion::Suggestion'];

coerce 'Suggestion',
    from HashRef, via { 'Google::Actions::Sdk::V2::Interactionmodel::Prompt::Suggestion::Suggestion'->new($_) };

declare 'RepeatedSuggestion',
    as ArrayRef[Suggestion()];

coerce 'RepeatedSuggestion',
    from ArrayRef[HashRef], via { [ map { 'Google::Actions::Sdk::V2::Interactionmodel::Prompt::Suggestion::Suggestion'->new($_) } @$_ ] };

declare 'MapStringSuggestion',
    as HashRef[Suggestion()];

1;

__END__

=head1 NAME

Google::Actions::Sdk::V2::Interactionmodel::Prompt::Suggestion::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
