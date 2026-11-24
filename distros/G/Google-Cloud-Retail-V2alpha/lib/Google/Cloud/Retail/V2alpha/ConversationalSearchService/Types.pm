package Google::Cloud::Retail::V2alpha::ConversationalSearchService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ConversationalSearchRequest',
    as InstanceOf['Google::Cloud::Retail::V2alpha::ConversationalSearchService::ConversationalSearchRequest'];

coerce 'ConversationalSearchRequest',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::ConversationalSearchService::ConversationalSearchRequest'->new($_) };

declare 'RepeatedConversationalSearchRequest',
    as ArrayRef[ConversationalSearchRequest()];

coerce 'RepeatedConversationalSearchRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::ConversationalSearchService::ConversationalSearchRequest'->new($_) } @$_ ] };

declare 'MapStringConversationalSearchRequest',
    as HashRef[ConversationalSearchRequest()];

declare 'SearchParams',
    as InstanceOf['Google::Cloud::Retail::V2alpha::ConversationalSearchService::ConversationalSearchRequest::SearchParams'];

coerce 'SearchParams',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::ConversationalSearchService::ConversationalSearchRequest::SearchParams'->new($_) };

declare 'RepeatedSearchParams',
    as ArrayRef[SearchParams()];

coerce 'RepeatedSearchParams',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::ConversationalSearchService::ConversationalSearchRequest::SearchParams'->new($_) } @$_ ] };

declare 'MapStringSearchParams',
    as HashRef[SearchParams()];

declare 'UserAnswer',
    as InstanceOf['Google::Cloud::Retail::V2alpha::ConversationalSearchService::ConversationalSearchRequest::UserAnswer'];

coerce 'UserAnswer',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::ConversationalSearchService::ConversationalSearchRequest::UserAnswer'->new($_) };

declare 'RepeatedUserAnswer',
    as ArrayRef[UserAnswer()];

coerce 'RepeatedUserAnswer',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::ConversationalSearchService::ConversationalSearchRequest::UserAnswer'->new($_) } @$_ ] };

declare 'MapStringUserAnswer',
    as HashRef[UserAnswer()];

declare 'SelectedAnswer',
    as InstanceOf['Google::Cloud::Retail::V2alpha::ConversationalSearchService::ConversationalSearchRequest::UserAnswer::SelectedAnswer'];

coerce 'SelectedAnswer',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::ConversationalSearchService::ConversationalSearchRequest::UserAnswer::SelectedAnswer'->new($_) };

declare 'RepeatedSelectedAnswer',
    as ArrayRef[SelectedAnswer()];

coerce 'RepeatedSelectedAnswer',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::ConversationalSearchService::ConversationalSearchRequest::UserAnswer::SelectedAnswer'->new($_) } @$_ ] };

declare 'MapStringSelectedAnswer',
    as HashRef[SelectedAnswer()];

declare 'ConversationalFilteringSpec',
    as InstanceOf['Google::Cloud::Retail::V2alpha::ConversationalSearchService::ConversationalSearchRequest::ConversationalFilteringSpec'];

coerce 'ConversationalFilteringSpec',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::ConversationalSearchService::ConversationalSearchRequest::ConversationalFilteringSpec'->new($_) };

declare 'RepeatedConversationalFilteringSpec',
    as ArrayRef[ConversationalFilteringSpec()];

coerce 'RepeatedConversationalFilteringSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::ConversationalSearchService::ConversationalSearchRequest::ConversationalFilteringSpec'->new($_) } @$_ ] };

declare 'MapStringConversationalFilteringSpec',
    as HashRef[ConversationalFilteringSpec()];

declare 'Mode',
    as (Int | Str);

declare 'UserLabelsEntry',
    as InstanceOf['Google::Cloud::Retail::V2alpha::ConversationalSearchService::ConversationalSearchRequest::UserLabelsEntry'];

coerce 'UserLabelsEntry',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::ConversationalSearchService::ConversationalSearchRequest::UserLabelsEntry'->new($_) };

declare 'RepeatedUserLabelsEntry',
    as ArrayRef[UserLabelsEntry()];

coerce 'RepeatedUserLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::ConversationalSearchService::ConversationalSearchRequest::UserLabelsEntry'->new($_) } @$_ ] };

declare 'MapStringUserLabelsEntry',
    as HashRef[UserLabelsEntry()];

declare 'ConversationalSearchResponse',
    as InstanceOf['Google::Cloud::Retail::V2alpha::ConversationalSearchService::ConversationalSearchResponse'];

coerce 'ConversationalSearchResponse',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::ConversationalSearchService::ConversationalSearchResponse'->new($_) };

declare 'RepeatedConversationalSearchResponse',
    as ArrayRef[ConversationalSearchResponse()];

coerce 'RepeatedConversationalSearchResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::ConversationalSearchService::ConversationalSearchResponse'->new($_) } @$_ ] };

declare 'MapStringConversationalSearchResponse',
    as HashRef[ConversationalSearchResponse()];

declare 'State',
    as (Int | Str);

declare 'FollowupQuestion',
    as InstanceOf['Google::Cloud::Retail::V2alpha::ConversationalSearchService::ConversationalSearchResponse::FollowupQuestion'];

coerce 'FollowupQuestion',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::ConversationalSearchService::ConversationalSearchResponse::FollowupQuestion'->new($_) };

declare 'RepeatedFollowupQuestion',
    as ArrayRef[FollowupQuestion()];

coerce 'RepeatedFollowupQuestion',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::ConversationalSearchService::ConversationalSearchResponse::FollowupQuestion'->new($_) } @$_ ] };

declare 'MapStringFollowupQuestion',
    as HashRef[FollowupQuestion()];

declare 'SuggestedAnswer',
    as InstanceOf['Google::Cloud::Retail::V2alpha::ConversationalSearchService::ConversationalSearchResponse::FollowupQuestion::SuggestedAnswer'];

coerce 'SuggestedAnswer',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::ConversationalSearchService::ConversationalSearchResponse::FollowupQuestion::SuggestedAnswer'->new($_) };

declare 'RepeatedSuggestedAnswer',
    as ArrayRef[SuggestedAnswer()];

coerce 'RepeatedSuggestedAnswer',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::ConversationalSearchService::ConversationalSearchResponse::FollowupQuestion::SuggestedAnswer'->new($_) } @$_ ] };

declare 'MapStringSuggestedAnswer',
    as HashRef[SuggestedAnswer()];

declare 'RefinedSearch',
    as InstanceOf['Google::Cloud::Retail::V2alpha::ConversationalSearchService::ConversationalSearchResponse::RefinedSearch'];

coerce 'RefinedSearch',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::ConversationalSearchService::ConversationalSearchResponse::RefinedSearch'->new($_) };

declare 'RepeatedRefinedSearch',
    as ArrayRef[RefinedSearch()];

coerce 'RepeatedRefinedSearch',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::ConversationalSearchService::ConversationalSearchResponse::RefinedSearch'->new($_) } @$_ ] };

declare 'MapStringRefinedSearch',
    as HashRef[RefinedSearch()];

declare 'ConversationalFilteringResult',
    as InstanceOf['Google::Cloud::Retail::V2alpha::ConversationalSearchService::ConversationalSearchResponse::ConversationalFilteringResult'];

coerce 'ConversationalFilteringResult',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::ConversationalSearchService::ConversationalSearchResponse::ConversationalFilteringResult'->new($_) };

declare 'RepeatedConversationalFilteringResult',
    as ArrayRef[ConversationalFilteringResult()];

coerce 'RepeatedConversationalFilteringResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::ConversationalSearchService::ConversationalSearchResponse::ConversationalFilteringResult'->new($_) } @$_ ] };

declare 'MapStringConversationalFilteringResult',
    as HashRef[ConversationalFilteringResult()];

declare 'AdditionalFilter',
    as InstanceOf['Google::Cloud::Retail::V2alpha::ConversationalSearchService::ConversationalSearchResponse::ConversationalFilteringResult::AdditionalFilter'];

coerce 'AdditionalFilter',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::ConversationalSearchService::ConversationalSearchResponse::ConversationalFilteringResult::AdditionalFilter'->new($_) };

declare 'RepeatedAdditionalFilter',
    as ArrayRef[AdditionalFilter()];

coerce 'RepeatedAdditionalFilter',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::ConversationalSearchService::ConversationalSearchResponse::ConversationalFilteringResult::AdditionalFilter'->new($_) } @$_ ] };

declare 'MapStringAdditionalFilter',
    as HashRef[AdditionalFilter()];

1;

__END__

=head1 NAME

Google::Cloud::Retail::V2alpha::ConversationalSearchService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
