package Google::Cloud::Chronicle::V1::RuleExecutionError::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ListRuleExecutionErrorsRequest',
    as InstanceOf['Google::Cloud::Chronicle::V1::RuleExecutionError::ListRuleExecutionErrorsRequest'];

coerce 'ListRuleExecutionErrorsRequest',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::RuleExecutionError::ListRuleExecutionErrorsRequest'->new($_) };

declare 'RepeatedListRuleExecutionErrorsRequest',
    as ArrayRef[ListRuleExecutionErrorsRequest()];

coerce 'RepeatedListRuleExecutionErrorsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::RuleExecutionError::ListRuleExecutionErrorsRequest'->new($_) } @$_ ] };

declare 'MapStringListRuleExecutionErrorsRequest',
    as HashRef[ListRuleExecutionErrorsRequest()];

declare 'ListRuleExecutionErrorsResponse',
    as InstanceOf['Google::Cloud::Chronicle::V1::RuleExecutionError::ListRuleExecutionErrorsResponse'];

coerce 'ListRuleExecutionErrorsResponse',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::RuleExecutionError::ListRuleExecutionErrorsResponse'->new($_) };

declare 'RepeatedListRuleExecutionErrorsResponse',
    as ArrayRef[ListRuleExecutionErrorsResponse()];

coerce 'RepeatedListRuleExecutionErrorsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::RuleExecutionError::ListRuleExecutionErrorsResponse'->new($_) } @$_ ] };

declare 'MapStringListRuleExecutionErrorsResponse',
    as HashRef[ListRuleExecutionErrorsResponse()];

declare 'RuleExecutionError',
    as InstanceOf['Google::Cloud::Chronicle::V1::RuleExecutionError::RuleExecutionError'];

coerce 'RuleExecutionError',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::RuleExecutionError::RuleExecutionError'->new($_) };

declare 'RepeatedRuleExecutionError',
    as ArrayRef[RuleExecutionError()];

coerce 'RepeatedRuleExecutionError',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::RuleExecutionError::RuleExecutionError'->new($_) } @$_ ] };

declare 'MapStringRuleExecutionError',
    as HashRef[RuleExecutionError()];

1;

__END__

=head1 NAME

Google::Cloud::Chronicle::V1::RuleExecutionError::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
