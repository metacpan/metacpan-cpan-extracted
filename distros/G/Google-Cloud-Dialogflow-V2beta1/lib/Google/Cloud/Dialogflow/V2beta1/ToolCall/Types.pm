package Google::Cloud::Dialogflow::V2beta1::ToolCall::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ToolCall',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::ToolCall::ToolCall'];

coerce 'ToolCall',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::ToolCall::ToolCall'->new($_) };

declare 'RepeatedToolCall',
    as ArrayRef[ToolCall()];

coerce 'RepeatedToolCall',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::ToolCall::ToolCall'->new($_) } @$_ ] };

declare 'MapStringToolCall',
    as HashRef[ToolCall()];

declare 'State',
    as (Int | Str);

declare 'ToolCallResult',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::ToolCall::ToolCallResult'];

coerce 'ToolCallResult',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::ToolCall::ToolCallResult'->new($_) };

declare 'RepeatedToolCallResult',
    as ArrayRef[ToolCallResult()];

coerce 'RepeatedToolCallResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::ToolCall::ToolCallResult'->new($_) } @$_ ] };

declare 'MapStringToolCallResult',
    as HashRef[ToolCallResult()];

declare 'Error',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::ToolCall::ToolCallResult::Error'];

coerce 'Error',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::ToolCall::ToolCallResult::Error'->new($_) };

declare 'RepeatedError',
    as ArrayRef[Error()];

coerce 'RepeatedError',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::ToolCall::ToolCallResult::Error'->new($_) } @$_ ] };

declare 'MapStringError',
    as HashRef[Error()];

1;

__END__

=head1 NAME

Google::Cloud::Dialogflow::V2beta1::ToolCall::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
