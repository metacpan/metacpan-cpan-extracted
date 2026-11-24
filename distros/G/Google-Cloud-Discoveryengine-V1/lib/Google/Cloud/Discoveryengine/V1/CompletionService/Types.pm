package Google::Cloud::Discoveryengine::V1::CompletionService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'CompleteQueryRequest',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::CompletionService::CompleteQueryRequest'];

coerce 'CompleteQueryRequest',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::CompletionService::CompleteQueryRequest'->new($_) };

declare 'RepeatedCompleteQueryRequest',
    as ArrayRef[CompleteQueryRequest()];

coerce 'RepeatedCompleteQueryRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::CompletionService::CompleteQueryRequest'->new($_) } @$_ ] };

declare 'MapStringCompleteQueryRequest',
    as HashRef[CompleteQueryRequest()];

declare 'CompleteQueryResponse',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::CompletionService::CompleteQueryResponse'];

coerce 'CompleteQueryResponse',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::CompletionService::CompleteQueryResponse'->new($_) };

declare 'RepeatedCompleteQueryResponse',
    as ArrayRef[CompleteQueryResponse()];

coerce 'RepeatedCompleteQueryResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::CompletionService::CompleteQueryResponse'->new($_) } @$_ ] };

declare 'MapStringCompleteQueryResponse',
    as HashRef[CompleteQueryResponse()];

declare 'QuerySuggestion',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::CompletionService::CompleteQueryResponse::QuerySuggestion'];

coerce 'QuerySuggestion',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::CompletionService::CompleteQueryResponse::QuerySuggestion'->new($_) };

declare 'RepeatedQuerySuggestion',
    as ArrayRef[QuerySuggestion()];

coerce 'RepeatedQuerySuggestion',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::CompletionService::CompleteQueryResponse::QuerySuggestion'->new($_) } @$_ ] };

declare 'MapStringQuerySuggestion',
    as HashRef[QuerySuggestion()];

declare 'AdvancedCompleteQueryRequest',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::CompletionService::AdvancedCompleteQueryRequest'];

coerce 'AdvancedCompleteQueryRequest',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::CompletionService::AdvancedCompleteQueryRequest'->new($_) };

declare 'RepeatedAdvancedCompleteQueryRequest',
    as ArrayRef[AdvancedCompleteQueryRequest()];

coerce 'RepeatedAdvancedCompleteQueryRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::CompletionService::AdvancedCompleteQueryRequest'->new($_) } @$_ ] };

declare 'MapStringAdvancedCompleteQueryRequest',
    as HashRef[AdvancedCompleteQueryRequest()];

declare 'SuggestionType',
    as (Int | Str);

declare 'BoostSpec',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::CompletionService::AdvancedCompleteQueryRequest::BoostSpec'];

coerce 'BoostSpec',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::CompletionService::AdvancedCompleteQueryRequest::BoostSpec'->new($_) };

declare 'RepeatedBoostSpec',
    as ArrayRef[BoostSpec()];

coerce 'RepeatedBoostSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::CompletionService::AdvancedCompleteQueryRequest::BoostSpec'->new($_) } @$_ ] };

declare 'MapStringBoostSpec',
    as HashRef[BoostSpec()];

declare 'ConditionBoostSpec',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::CompletionService::AdvancedCompleteQueryRequest::BoostSpec::ConditionBoostSpec'];

coerce 'ConditionBoostSpec',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::CompletionService::AdvancedCompleteQueryRequest::BoostSpec::ConditionBoostSpec'->new($_) };

declare 'RepeatedConditionBoostSpec',
    as ArrayRef[ConditionBoostSpec()];

coerce 'RepeatedConditionBoostSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::CompletionService::AdvancedCompleteQueryRequest::BoostSpec::ConditionBoostSpec'->new($_) } @$_ ] };

declare 'MapStringConditionBoostSpec',
    as HashRef[ConditionBoostSpec()];

declare 'SuggestionTypeSpec',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::CompletionService::AdvancedCompleteQueryRequest::SuggestionTypeSpec'];

coerce 'SuggestionTypeSpec',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::CompletionService::AdvancedCompleteQueryRequest::SuggestionTypeSpec'->new($_) };

declare 'RepeatedSuggestionTypeSpec',
    as ArrayRef[SuggestionTypeSpec()];

coerce 'RepeatedSuggestionTypeSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::CompletionService::AdvancedCompleteQueryRequest::SuggestionTypeSpec'->new($_) } @$_ ] };

declare 'MapStringSuggestionTypeSpec',
    as HashRef[SuggestionTypeSpec()];

declare 'AdvancedCompleteQueryResponse',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::CompletionService::AdvancedCompleteQueryResponse'];

coerce 'AdvancedCompleteQueryResponse',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::CompletionService::AdvancedCompleteQueryResponse'->new($_) };

declare 'RepeatedAdvancedCompleteQueryResponse',
    as ArrayRef[AdvancedCompleteQueryResponse()];

coerce 'RepeatedAdvancedCompleteQueryResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::CompletionService::AdvancedCompleteQueryResponse'->new($_) } @$_ ] };

declare 'MapStringAdvancedCompleteQueryResponse',
    as HashRef[AdvancedCompleteQueryResponse()];

declare 'QuerySuggestion',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::CompletionService::AdvancedCompleteQueryResponse::QuerySuggestion'];

coerce 'QuerySuggestion',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::CompletionService::AdvancedCompleteQueryResponse::QuerySuggestion'->new($_) };

declare 'RepeatedQuerySuggestion',
    as ArrayRef[QuerySuggestion()];

coerce 'RepeatedQuerySuggestion',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::CompletionService::AdvancedCompleteQueryResponse::QuerySuggestion'->new($_) } @$_ ] };

declare 'MapStringQuerySuggestion',
    as HashRef[QuerySuggestion()];

declare 'PersonSuggestion',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::CompletionService::AdvancedCompleteQueryResponse::PersonSuggestion'];

coerce 'PersonSuggestion',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::CompletionService::AdvancedCompleteQueryResponse::PersonSuggestion'->new($_) };

declare 'RepeatedPersonSuggestion',
    as ArrayRef[PersonSuggestion()];

coerce 'RepeatedPersonSuggestion',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::CompletionService::AdvancedCompleteQueryResponse::PersonSuggestion'->new($_) } @$_ ] };

declare 'MapStringPersonSuggestion',
    as HashRef[PersonSuggestion()];

declare 'PersonType',
    as (Int | Str);

declare 'ContentSuggestion',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::CompletionService::AdvancedCompleteQueryResponse::ContentSuggestion'];

coerce 'ContentSuggestion',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::CompletionService::AdvancedCompleteQueryResponse::ContentSuggestion'->new($_) };

declare 'RepeatedContentSuggestion',
    as ArrayRef[ContentSuggestion()];

coerce 'RepeatedContentSuggestion',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::CompletionService::AdvancedCompleteQueryResponse::ContentSuggestion'->new($_) } @$_ ] };

declare 'MapStringContentSuggestion',
    as HashRef[ContentSuggestion()];

declare 'ContentType',
    as (Int | Str);

declare 'RecentSearchSuggestion',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::CompletionService::AdvancedCompleteQueryResponse::RecentSearchSuggestion'];

coerce 'RecentSearchSuggestion',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::CompletionService::AdvancedCompleteQueryResponse::RecentSearchSuggestion'->new($_) };

declare 'RepeatedRecentSearchSuggestion',
    as ArrayRef[RecentSearchSuggestion()];

coerce 'RepeatedRecentSearchSuggestion',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::CompletionService::AdvancedCompleteQueryResponse::RecentSearchSuggestion'->new($_) } @$_ ] };

declare 'MapStringRecentSearchSuggestion',
    as HashRef[RecentSearchSuggestion()];

1;

__END__

=head1 NAME

Google::Cloud::Discoveryengine::V1::CompletionService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
