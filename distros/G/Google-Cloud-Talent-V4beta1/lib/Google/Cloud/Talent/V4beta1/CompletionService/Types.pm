package Google::Cloud::Talent::V4beta1::CompletionService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'CompleteQueryRequest',
    as InstanceOf['Google::Cloud::Talent::V4beta1::CompletionService::CompleteQueryRequest'];

coerce 'CompleteQueryRequest',
    from HashRef, via { 'Google::Cloud::Talent::V4beta1::CompletionService::CompleteQueryRequest'->new($_) };

declare 'RepeatedCompleteQueryRequest',
    as ArrayRef[CompleteQueryRequest()];

coerce 'RepeatedCompleteQueryRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Talent::V4beta1::CompletionService::CompleteQueryRequest'->new($_) } @$_ ] };

declare 'MapStringCompleteQueryRequest',
    as HashRef[CompleteQueryRequest()];

declare 'CompletionScope',
    as (Int | Str);

declare 'CompletionType',
    as (Int | Str);

declare 'CompleteQueryResponse',
    as InstanceOf['Google::Cloud::Talent::V4beta1::CompletionService::CompleteQueryResponse'];

coerce 'CompleteQueryResponse',
    from HashRef, via { 'Google::Cloud::Talent::V4beta1::CompletionService::CompleteQueryResponse'->new($_) };

declare 'RepeatedCompleteQueryResponse',
    as ArrayRef[CompleteQueryResponse()];

coerce 'RepeatedCompleteQueryResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Talent::V4beta1::CompletionService::CompleteQueryResponse'->new($_) } @$_ ] };

declare 'MapStringCompleteQueryResponse',
    as HashRef[CompleteQueryResponse()];

declare 'CompletionResult',
    as InstanceOf['Google::Cloud::Talent::V4beta1::CompletionService::CompleteQueryResponse::CompletionResult'];

coerce 'CompletionResult',
    from HashRef, via { 'Google::Cloud::Talent::V4beta1::CompletionService::CompleteQueryResponse::CompletionResult'->new($_) };

declare 'RepeatedCompletionResult',
    as ArrayRef[CompletionResult()];

coerce 'RepeatedCompletionResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Talent::V4beta1::CompletionService::CompleteQueryResponse::CompletionResult'->new($_) } @$_ ] };

declare 'MapStringCompletionResult',
    as HashRef[CompletionResult()];

1;

__END__

=head1 NAME

Google::Cloud::Talent::V4beta1::CompletionService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
