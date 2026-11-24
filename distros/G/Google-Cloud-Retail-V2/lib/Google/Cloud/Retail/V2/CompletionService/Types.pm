package Google::Cloud::Retail::V2::CompletionService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'CompleteQueryRequest',
    as InstanceOf['Google::Cloud::Retail::V2::CompletionService::CompleteQueryRequest'];

coerce 'CompleteQueryRequest',
    from HashRef, via { 'Google::Cloud::Retail::V2::CompletionService::CompleteQueryRequest'->new($_) };

declare 'RepeatedCompleteQueryRequest',
    as ArrayRef[CompleteQueryRequest()];

coerce 'RepeatedCompleteQueryRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2::CompletionService::CompleteQueryRequest'->new($_) } @$_ ] };

declare 'MapStringCompleteQueryRequest',
    as HashRef[CompleteQueryRequest()];

declare 'CompleteQueryResponse',
    as InstanceOf['Google::Cloud::Retail::V2::CompletionService::CompleteQueryResponse'];

coerce 'CompleteQueryResponse',
    from HashRef, via { 'Google::Cloud::Retail::V2::CompletionService::CompleteQueryResponse'->new($_) };

declare 'RepeatedCompleteQueryResponse',
    as ArrayRef[CompleteQueryResponse()];

coerce 'RepeatedCompleteQueryResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2::CompletionService::CompleteQueryResponse'->new($_) } @$_ ] };

declare 'MapStringCompleteQueryResponse',
    as HashRef[CompleteQueryResponse()];

declare 'CompletionResult',
    as InstanceOf['Google::Cloud::Retail::V2::CompletionService::CompleteQueryResponse::CompletionResult'];

coerce 'CompletionResult',
    from HashRef, via { 'Google::Cloud::Retail::V2::CompletionService::CompleteQueryResponse::CompletionResult'->new($_) };

declare 'RepeatedCompletionResult',
    as ArrayRef[CompletionResult()];

coerce 'RepeatedCompletionResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2::CompletionService::CompleteQueryResponse::CompletionResult'->new($_) } @$_ ] };

declare 'MapStringCompletionResult',
    as HashRef[CompletionResult()];

declare 'AttributesEntry',
    as InstanceOf['Google::Cloud::Retail::V2::CompletionService::CompleteQueryResponse::CompletionResult::AttributesEntry'];

coerce 'AttributesEntry',
    from HashRef, via { 'Google::Cloud::Retail::V2::CompletionService::CompleteQueryResponse::CompletionResult::AttributesEntry'->new($_) };

declare 'RepeatedAttributesEntry',
    as ArrayRef[AttributesEntry()];

coerce 'RepeatedAttributesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2::CompletionService::CompleteQueryResponse::CompletionResult::AttributesEntry'->new($_) } @$_ ] };

declare 'MapStringAttributesEntry',
    as HashRef[AttributesEntry()];

declare 'RecentSearchResult',
    as InstanceOf['Google::Cloud::Retail::V2::CompletionService::CompleteQueryResponse::RecentSearchResult'];

coerce 'RecentSearchResult',
    from HashRef, via { 'Google::Cloud::Retail::V2::CompletionService::CompleteQueryResponse::RecentSearchResult'->new($_) };

declare 'RepeatedRecentSearchResult',
    as ArrayRef[RecentSearchResult()];

coerce 'RepeatedRecentSearchResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2::CompletionService::CompleteQueryResponse::RecentSearchResult'->new($_) } @$_ ] };

declare 'MapStringRecentSearchResult',
    as HashRef[RecentSearchResult()];

declare 'AttributeResult',
    as InstanceOf['Google::Cloud::Retail::V2::CompletionService::CompleteQueryResponse::AttributeResult'];

coerce 'AttributeResult',
    from HashRef, via { 'Google::Cloud::Retail::V2::CompletionService::CompleteQueryResponse::AttributeResult'->new($_) };

declare 'RepeatedAttributeResult',
    as ArrayRef[AttributeResult()];

coerce 'RepeatedAttributeResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2::CompletionService::CompleteQueryResponse::AttributeResult'->new($_) } @$_ ] };

declare 'MapStringAttributeResult',
    as HashRef[AttributeResult()];

declare 'AttributeResultsEntry',
    as InstanceOf['Google::Cloud::Retail::V2::CompletionService::CompleteQueryResponse::AttributeResultsEntry'];

coerce 'AttributeResultsEntry',
    from HashRef, via { 'Google::Cloud::Retail::V2::CompletionService::CompleteQueryResponse::AttributeResultsEntry'->new($_) };

declare 'RepeatedAttributeResultsEntry',
    as ArrayRef[AttributeResultsEntry()];

coerce 'RepeatedAttributeResultsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2::CompletionService::CompleteQueryResponse::AttributeResultsEntry'->new($_) } @$_ ] };

declare 'MapStringAttributeResultsEntry',
    as HashRef[AttributeResultsEntry()];

1;

__END__

=head1 NAME

Google::Cloud::Retail::V2::CompletionService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
