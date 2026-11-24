package Google::Cloud::Discoveryengine::V1alpha::CompletionService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'CompleteQueryRequest',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::CompletionService::CompleteQueryRequest'];

coerce 'CompleteQueryRequest',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::CompletionService::CompleteQueryRequest'->new($_) };

declare 'RepeatedCompleteQueryRequest',
    as ArrayRef[CompleteQueryRequest()];

coerce 'RepeatedCompleteQueryRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::CompletionService::CompleteQueryRequest'->new($_) } @$_ ] };

declare 'MapStringCompleteQueryRequest',
    as HashRef[CompleteQueryRequest()];

declare 'CompleteQueryResponse',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::CompletionService::CompleteQueryResponse'];

coerce 'CompleteQueryResponse',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::CompletionService::CompleteQueryResponse'->new($_) };

declare 'RepeatedCompleteQueryResponse',
    as ArrayRef[CompleteQueryResponse()];

coerce 'RepeatedCompleteQueryResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::CompletionService::CompleteQueryResponse'->new($_) } @$_ ] };

declare 'MapStringCompleteQueryResponse',
    as HashRef[CompleteQueryResponse()];

declare 'QuerySuggestion',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::CompletionService::CompleteQueryResponse::QuerySuggestion'];

coerce 'QuerySuggestion',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::CompletionService::CompleteQueryResponse::QuerySuggestion'->new($_) };

declare 'RepeatedQuerySuggestion',
    as ArrayRef[QuerySuggestion()];

coerce 'RepeatedQuerySuggestion',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::CompletionService::CompleteQueryResponse::QuerySuggestion'->new($_) } @$_ ] };

declare 'MapStringQuerySuggestion',
    as HashRef[QuerySuggestion()];

1;

__END__

=head1 NAME

Google::Cloud::Discoveryengine::V1alpha::CompletionService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
