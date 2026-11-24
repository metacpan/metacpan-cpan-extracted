package Google::Cloud::Discoveryengine::V1::Completion::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'SuggestionDenyListEntry',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::Completion::SuggestionDenyListEntry'];

coerce 'SuggestionDenyListEntry',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::Completion::SuggestionDenyListEntry'->new($_) };

declare 'RepeatedSuggestionDenyListEntry',
    as ArrayRef[SuggestionDenyListEntry()];

coerce 'RepeatedSuggestionDenyListEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::Completion::SuggestionDenyListEntry'->new($_) } @$_ ] };

declare 'MapStringSuggestionDenyListEntry',
    as HashRef[SuggestionDenyListEntry()];

declare 'MatchOperator',
    as (Int | Str);

declare 'CompletionSuggestion',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::Completion::CompletionSuggestion'];

coerce 'CompletionSuggestion',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::Completion::CompletionSuggestion'->new($_) };

declare 'RepeatedCompletionSuggestion',
    as ArrayRef[CompletionSuggestion()];

coerce 'RepeatedCompletionSuggestion',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::Completion::CompletionSuggestion'->new($_) } @$_ ] };

declare 'MapStringCompletionSuggestion',
    as HashRef[CompletionSuggestion()];

1;

__END__

=head1 NAME

Google::Cloud::Discoveryengine::V1::Completion::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
