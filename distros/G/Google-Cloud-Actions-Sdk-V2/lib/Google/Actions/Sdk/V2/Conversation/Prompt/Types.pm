package Google::Actions::Sdk::V2::Conversation::Prompt::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Prompt',
    as InstanceOf['Google::Actions::Sdk::V2::Conversation::Prompt::Prompt'];

coerce 'Prompt',
    from HashRef, via { 'Google::Actions::Sdk::V2::Conversation::Prompt::Prompt'->new($_) };

declare 'RepeatedPrompt',
    as ArrayRef[Prompt()];

coerce 'RepeatedPrompt',
    from ArrayRef[HashRef], via { [ map { 'Google::Actions::Sdk::V2::Conversation::Prompt::Prompt'->new($_) } @$_ ] };

declare 'MapStringPrompt',
    as HashRef[Prompt()];

1;

__END__

=head1 NAME

Google::Actions::Sdk::V2::Conversation::Prompt::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
