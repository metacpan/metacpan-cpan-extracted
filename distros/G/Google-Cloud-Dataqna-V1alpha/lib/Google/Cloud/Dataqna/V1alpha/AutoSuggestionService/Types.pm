package Google::Cloud::Dataqna::V1alpha::AutoSuggestionService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'SuggestionType',
    as (Int | Str);

declare 'SuggestQueriesRequest',
    as InstanceOf['Google::Cloud::Dataqna::V1alpha::AutoSuggestionService::SuggestQueriesRequest'];

coerce 'SuggestQueriesRequest',
    from HashRef, via { 'Google::Cloud::Dataqna::V1alpha::AutoSuggestionService::SuggestQueriesRequest'->new($_) };

declare 'RepeatedSuggestQueriesRequest',
    as ArrayRef[SuggestQueriesRequest()];

coerce 'RepeatedSuggestQueriesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataqna::V1alpha::AutoSuggestionService::SuggestQueriesRequest'->new($_) } @$_ ] };

declare 'MapStringSuggestQueriesRequest',
    as HashRef[SuggestQueriesRequest()];

declare 'Suggestion',
    as InstanceOf['Google::Cloud::Dataqna::V1alpha::AutoSuggestionService::Suggestion'];

coerce 'Suggestion',
    from HashRef, via { 'Google::Cloud::Dataqna::V1alpha::AutoSuggestionService::Suggestion'->new($_) };

declare 'RepeatedSuggestion',
    as ArrayRef[Suggestion()];

coerce 'RepeatedSuggestion',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataqna::V1alpha::AutoSuggestionService::Suggestion'->new($_) } @$_ ] };

declare 'MapStringSuggestion',
    as HashRef[Suggestion()];

declare 'SuggestionInfo',
    as InstanceOf['Google::Cloud::Dataqna::V1alpha::AutoSuggestionService::SuggestionInfo'];

coerce 'SuggestionInfo',
    from HashRef, via { 'Google::Cloud::Dataqna::V1alpha::AutoSuggestionService::SuggestionInfo'->new($_) };

declare 'RepeatedSuggestionInfo',
    as ArrayRef[SuggestionInfo()];

coerce 'RepeatedSuggestionInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataqna::V1alpha::AutoSuggestionService::SuggestionInfo'->new($_) } @$_ ] };

declare 'MapStringSuggestionInfo',
    as HashRef[SuggestionInfo()];

declare 'MatchInfo',
    as InstanceOf['Google::Cloud::Dataqna::V1alpha::AutoSuggestionService::SuggestionInfo::MatchInfo'];

coerce 'MatchInfo',
    from HashRef, via { 'Google::Cloud::Dataqna::V1alpha::AutoSuggestionService::SuggestionInfo::MatchInfo'->new($_) };

declare 'RepeatedMatchInfo',
    as ArrayRef[MatchInfo()];

coerce 'RepeatedMatchInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataqna::V1alpha::AutoSuggestionService::SuggestionInfo::MatchInfo'->new($_) } @$_ ] };

declare 'MapStringMatchInfo',
    as HashRef[MatchInfo()];

declare 'SuggestQueriesResponse',
    as InstanceOf['Google::Cloud::Dataqna::V1alpha::AutoSuggestionService::SuggestQueriesResponse'];

coerce 'SuggestQueriesResponse',
    from HashRef, via { 'Google::Cloud::Dataqna::V1alpha::AutoSuggestionService::SuggestQueriesResponse'->new($_) };

declare 'RepeatedSuggestQueriesResponse',
    as ArrayRef[SuggestQueriesResponse()];

coerce 'RepeatedSuggestQueriesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataqna::V1alpha::AutoSuggestionService::SuggestQueriesResponse'->new($_) } @$_ ] };

declare 'MapStringSuggestQueriesResponse',
    as HashRef[SuggestQueriesResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Dataqna::V1alpha::AutoSuggestionService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
