package Google::Cloud::Ces::V1::AgentTransfers::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ExpressionCondition',
    as InstanceOf['Google::Cloud::Ces::V1::AgentTransfers::ExpressionCondition'];

coerce 'ExpressionCondition',
    from HashRef, via { 'Google::Cloud::Ces::V1::AgentTransfers::ExpressionCondition'->new($_) };

declare 'RepeatedExpressionCondition',
    as ArrayRef[ExpressionCondition()];

coerce 'RepeatedExpressionCondition',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::AgentTransfers::ExpressionCondition'->new($_) } @$_ ] };

declare 'MapStringExpressionCondition',
    as HashRef[ExpressionCondition()];

declare 'PythonCodeCondition',
    as InstanceOf['Google::Cloud::Ces::V1::AgentTransfers::PythonCodeCondition'];

coerce 'PythonCodeCondition',
    from HashRef, via { 'Google::Cloud::Ces::V1::AgentTransfers::PythonCodeCondition'->new($_) };

declare 'RepeatedPythonCodeCondition',
    as ArrayRef[PythonCodeCondition()];

coerce 'RepeatedPythonCodeCondition',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::AgentTransfers::PythonCodeCondition'->new($_) } @$_ ] };

declare 'MapStringPythonCodeCondition',
    as HashRef[PythonCodeCondition()];

declare 'TransferRule',
    as InstanceOf['Google::Cloud::Ces::V1::AgentTransfers::TransferRule'];

coerce 'TransferRule',
    from HashRef, via { 'Google::Cloud::Ces::V1::AgentTransfers::TransferRule'->new($_) };

declare 'RepeatedTransferRule',
    as ArrayRef[TransferRule()];

coerce 'RepeatedTransferRule',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::AgentTransfers::TransferRule'->new($_) } @$_ ] };

declare 'MapStringTransferRule',
    as HashRef[TransferRule()];

declare 'Direction',
    as (Int | Str);

declare 'DeterministicTransfer',
    as InstanceOf['Google::Cloud::Ces::V1::AgentTransfers::TransferRule::DeterministicTransfer'];

coerce 'DeterministicTransfer',
    from HashRef, via { 'Google::Cloud::Ces::V1::AgentTransfers::TransferRule::DeterministicTransfer'->new($_) };

declare 'RepeatedDeterministicTransfer',
    as ArrayRef[DeterministicTransfer()];

coerce 'RepeatedDeterministicTransfer',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::AgentTransfers::TransferRule::DeterministicTransfer'->new($_) } @$_ ] };

declare 'MapStringDeterministicTransfer',
    as HashRef[DeterministicTransfer()];

declare 'DisablePlannerTransfer',
    as InstanceOf['Google::Cloud::Ces::V1::AgentTransfers::TransferRule::DisablePlannerTransfer'];

coerce 'DisablePlannerTransfer',
    from HashRef, via { 'Google::Cloud::Ces::V1::AgentTransfers::TransferRule::DisablePlannerTransfer'->new($_) };

declare 'RepeatedDisablePlannerTransfer',
    as ArrayRef[DisablePlannerTransfer()];

coerce 'RepeatedDisablePlannerTransfer',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::AgentTransfers::TransferRule::DisablePlannerTransfer'->new($_) } @$_ ] };

declare 'MapStringDisablePlannerTransfer',
    as HashRef[DisablePlannerTransfer()];

1;

__END__

=head1 NAME

Google::Cloud::Ces::V1::AgentTransfers::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
