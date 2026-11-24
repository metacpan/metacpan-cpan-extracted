package Google::Cloud::Discoveryengine::V1alpha::PurgeConfig::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'PurgeUserEventsRequest',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::PurgeConfig::PurgeUserEventsRequest'];

coerce 'PurgeUserEventsRequest',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::PurgeConfig::PurgeUserEventsRequest'->new($_) };

declare 'RepeatedPurgeUserEventsRequest',
    as ArrayRef[PurgeUserEventsRequest()];

coerce 'RepeatedPurgeUserEventsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::PurgeConfig::PurgeUserEventsRequest'->new($_) } @$_ ] };

declare 'MapStringPurgeUserEventsRequest',
    as HashRef[PurgeUserEventsRequest()];

declare 'PurgeUserEventsResponse',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::PurgeConfig::PurgeUserEventsResponse'];

coerce 'PurgeUserEventsResponse',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::PurgeConfig::PurgeUserEventsResponse'->new($_) };

declare 'RepeatedPurgeUserEventsResponse',
    as ArrayRef[PurgeUserEventsResponse()];

coerce 'RepeatedPurgeUserEventsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::PurgeConfig::PurgeUserEventsResponse'->new($_) } @$_ ] };

declare 'MapStringPurgeUserEventsResponse',
    as HashRef[PurgeUserEventsResponse()];

declare 'PurgeUserEventsMetadata',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::PurgeConfig::PurgeUserEventsMetadata'];

coerce 'PurgeUserEventsMetadata',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::PurgeConfig::PurgeUserEventsMetadata'->new($_) };

declare 'RepeatedPurgeUserEventsMetadata',
    as ArrayRef[PurgeUserEventsMetadata()];

coerce 'RepeatedPurgeUserEventsMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::PurgeConfig::PurgeUserEventsMetadata'->new($_) } @$_ ] };

declare 'MapStringPurgeUserEventsMetadata',
    as HashRef[PurgeUserEventsMetadata()];

declare 'PurgeErrorConfig',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::PurgeConfig::PurgeErrorConfig'];

coerce 'PurgeErrorConfig',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::PurgeConfig::PurgeErrorConfig'->new($_) };

declare 'RepeatedPurgeErrorConfig',
    as ArrayRef[PurgeErrorConfig()];

coerce 'RepeatedPurgeErrorConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::PurgeConfig::PurgeErrorConfig'->new($_) } @$_ ] };

declare 'MapStringPurgeErrorConfig',
    as HashRef[PurgeErrorConfig()];

declare 'PurgeDocumentsRequest',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::PurgeConfig::PurgeDocumentsRequest'];

coerce 'PurgeDocumentsRequest',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::PurgeConfig::PurgeDocumentsRequest'->new($_) };

declare 'RepeatedPurgeDocumentsRequest',
    as ArrayRef[PurgeDocumentsRequest()];

coerce 'RepeatedPurgeDocumentsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::PurgeConfig::PurgeDocumentsRequest'->new($_) } @$_ ] };

declare 'MapStringPurgeDocumentsRequest',
    as HashRef[PurgeDocumentsRequest()];

declare 'InlineSource',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::PurgeConfig::PurgeDocumentsRequest::InlineSource'];

coerce 'InlineSource',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::PurgeConfig::PurgeDocumentsRequest::InlineSource'->new($_) };

declare 'RepeatedInlineSource',
    as ArrayRef[InlineSource()];

coerce 'RepeatedInlineSource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::PurgeConfig::PurgeDocumentsRequest::InlineSource'->new($_) } @$_ ] };

declare 'MapStringInlineSource',
    as HashRef[InlineSource()];

declare 'PurgeDocumentsResponse',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::PurgeConfig::PurgeDocumentsResponse'];

coerce 'PurgeDocumentsResponse',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::PurgeConfig::PurgeDocumentsResponse'->new($_) };

declare 'RepeatedPurgeDocumentsResponse',
    as ArrayRef[PurgeDocumentsResponse()];

coerce 'RepeatedPurgeDocumentsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::PurgeConfig::PurgeDocumentsResponse'->new($_) } @$_ ] };

declare 'MapStringPurgeDocumentsResponse',
    as HashRef[PurgeDocumentsResponse()];

declare 'PurgeDocumentsMetadata',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::PurgeConfig::PurgeDocumentsMetadata'];

coerce 'PurgeDocumentsMetadata',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::PurgeConfig::PurgeDocumentsMetadata'->new($_) };

declare 'RepeatedPurgeDocumentsMetadata',
    as ArrayRef[PurgeDocumentsMetadata()];

coerce 'RepeatedPurgeDocumentsMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::PurgeConfig::PurgeDocumentsMetadata'->new($_) } @$_ ] };

declare 'MapStringPurgeDocumentsMetadata',
    as HashRef[PurgeDocumentsMetadata()];

declare 'PurgeSuggestionDenyListEntriesRequest',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::PurgeConfig::PurgeSuggestionDenyListEntriesRequest'];

coerce 'PurgeSuggestionDenyListEntriesRequest',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::PurgeConfig::PurgeSuggestionDenyListEntriesRequest'->new($_) };

declare 'RepeatedPurgeSuggestionDenyListEntriesRequest',
    as ArrayRef[PurgeSuggestionDenyListEntriesRequest()];

coerce 'RepeatedPurgeSuggestionDenyListEntriesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::PurgeConfig::PurgeSuggestionDenyListEntriesRequest'->new($_) } @$_ ] };

declare 'MapStringPurgeSuggestionDenyListEntriesRequest',
    as HashRef[PurgeSuggestionDenyListEntriesRequest()];

declare 'PurgeSuggestionDenyListEntriesResponse',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::PurgeConfig::PurgeSuggestionDenyListEntriesResponse'];

coerce 'PurgeSuggestionDenyListEntriesResponse',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::PurgeConfig::PurgeSuggestionDenyListEntriesResponse'->new($_) };

declare 'RepeatedPurgeSuggestionDenyListEntriesResponse',
    as ArrayRef[PurgeSuggestionDenyListEntriesResponse()];

coerce 'RepeatedPurgeSuggestionDenyListEntriesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::PurgeConfig::PurgeSuggestionDenyListEntriesResponse'->new($_) } @$_ ] };

declare 'MapStringPurgeSuggestionDenyListEntriesResponse',
    as HashRef[PurgeSuggestionDenyListEntriesResponse()];

declare 'PurgeSuggestionDenyListEntriesMetadata',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::PurgeConfig::PurgeSuggestionDenyListEntriesMetadata'];

coerce 'PurgeSuggestionDenyListEntriesMetadata',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::PurgeConfig::PurgeSuggestionDenyListEntriesMetadata'->new($_) };

declare 'RepeatedPurgeSuggestionDenyListEntriesMetadata',
    as ArrayRef[PurgeSuggestionDenyListEntriesMetadata()];

coerce 'RepeatedPurgeSuggestionDenyListEntriesMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::PurgeConfig::PurgeSuggestionDenyListEntriesMetadata'->new($_) } @$_ ] };

declare 'MapStringPurgeSuggestionDenyListEntriesMetadata',
    as HashRef[PurgeSuggestionDenyListEntriesMetadata()];

declare 'PurgeCompletionSuggestionsRequest',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::PurgeConfig::PurgeCompletionSuggestionsRequest'];

coerce 'PurgeCompletionSuggestionsRequest',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::PurgeConfig::PurgeCompletionSuggestionsRequest'->new($_) };

declare 'RepeatedPurgeCompletionSuggestionsRequest',
    as ArrayRef[PurgeCompletionSuggestionsRequest()];

coerce 'RepeatedPurgeCompletionSuggestionsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::PurgeConfig::PurgeCompletionSuggestionsRequest'->new($_) } @$_ ] };

declare 'MapStringPurgeCompletionSuggestionsRequest',
    as HashRef[PurgeCompletionSuggestionsRequest()];

declare 'PurgeCompletionSuggestionsResponse',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::PurgeConfig::PurgeCompletionSuggestionsResponse'];

coerce 'PurgeCompletionSuggestionsResponse',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::PurgeConfig::PurgeCompletionSuggestionsResponse'->new($_) };

declare 'RepeatedPurgeCompletionSuggestionsResponse',
    as ArrayRef[PurgeCompletionSuggestionsResponse()];

coerce 'RepeatedPurgeCompletionSuggestionsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::PurgeConfig::PurgeCompletionSuggestionsResponse'->new($_) } @$_ ] };

declare 'MapStringPurgeCompletionSuggestionsResponse',
    as HashRef[PurgeCompletionSuggestionsResponse()];

declare 'PurgeCompletionSuggestionsMetadata',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::PurgeConfig::PurgeCompletionSuggestionsMetadata'];

coerce 'PurgeCompletionSuggestionsMetadata',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::PurgeConfig::PurgeCompletionSuggestionsMetadata'->new($_) };

declare 'RepeatedPurgeCompletionSuggestionsMetadata',
    as ArrayRef[PurgeCompletionSuggestionsMetadata()];

coerce 'RepeatedPurgeCompletionSuggestionsMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::PurgeConfig::PurgeCompletionSuggestionsMetadata'->new($_) } @$_ ] };

declare 'MapStringPurgeCompletionSuggestionsMetadata',
    as HashRef[PurgeCompletionSuggestionsMetadata()];

1;

__END__

=head1 NAME

Google::Cloud::Discoveryengine::V1alpha::PurgeConfig::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
