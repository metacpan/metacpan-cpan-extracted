package Google::Cloud::Policysimulator::V1::Simulator::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Replay',
    as InstanceOf['Google::Cloud::Policysimulator::V1::Simulator::Replay'];

coerce 'Replay',
    from HashRef, via { 'Google::Cloud::Policysimulator::V1::Simulator::Replay'->new($_) };

declare 'RepeatedReplay',
    as ArrayRef[Replay()];

coerce 'RepeatedReplay',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Policysimulator::V1::Simulator::Replay'->new($_) } @$_ ] };

declare 'MapStringReplay',
    as HashRef[Replay()];

declare 'State',
    as (Int | Str);

declare 'ResultsSummary',
    as InstanceOf['Google::Cloud::Policysimulator::V1::Simulator::Replay::ResultsSummary'];

coerce 'ResultsSummary',
    from HashRef, via { 'Google::Cloud::Policysimulator::V1::Simulator::Replay::ResultsSummary'->new($_) };

declare 'RepeatedResultsSummary',
    as ArrayRef[ResultsSummary()];

coerce 'RepeatedResultsSummary',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Policysimulator::V1::Simulator::Replay::ResultsSummary'->new($_) } @$_ ] };

declare 'MapStringResultsSummary',
    as HashRef[ResultsSummary()];

declare 'ReplayResult',
    as InstanceOf['Google::Cloud::Policysimulator::V1::Simulator::ReplayResult'];

coerce 'ReplayResult',
    from HashRef, via { 'Google::Cloud::Policysimulator::V1::Simulator::ReplayResult'->new($_) };

declare 'RepeatedReplayResult',
    as ArrayRef[ReplayResult()];

coerce 'RepeatedReplayResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Policysimulator::V1::Simulator::ReplayResult'->new($_) } @$_ ] };

declare 'MapStringReplayResult',
    as HashRef[ReplayResult()];

declare 'CreateReplayRequest',
    as InstanceOf['Google::Cloud::Policysimulator::V1::Simulator::CreateReplayRequest'];

coerce 'CreateReplayRequest',
    from HashRef, via { 'Google::Cloud::Policysimulator::V1::Simulator::CreateReplayRequest'->new($_) };

declare 'RepeatedCreateReplayRequest',
    as ArrayRef[CreateReplayRequest()];

coerce 'RepeatedCreateReplayRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Policysimulator::V1::Simulator::CreateReplayRequest'->new($_) } @$_ ] };

declare 'MapStringCreateReplayRequest',
    as HashRef[CreateReplayRequest()];

declare 'ReplayOperationMetadata',
    as InstanceOf['Google::Cloud::Policysimulator::V1::Simulator::ReplayOperationMetadata'];

coerce 'ReplayOperationMetadata',
    from HashRef, via { 'Google::Cloud::Policysimulator::V1::Simulator::ReplayOperationMetadata'->new($_) };

declare 'RepeatedReplayOperationMetadata',
    as ArrayRef[ReplayOperationMetadata()];

coerce 'RepeatedReplayOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Policysimulator::V1::Simulator::ReplayOperationMetadata'->new($_) } @$_ ] };

declare 'MapStringReplayOperationMetadata',
    as HashRef[ReplayOperationMetadata()];

declare 'GetReplayRequest',
    as InstanceOf['Google::Cloud::Policysimulator::V1::Simulator::GetReplayRequest'];

coerce 'GetReplayRequest',
    from HashRef, via { 'Google::Cloud::Policysimulator::V1::Simulator::GetReplayRequest'->new($_) };

declare 'RepeatedGetReplayRequest',
    as ArrayRef[GetReplayRequest()];

coerce 'RepeatedGetReplayRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Policysimulator::V1::Simulator::GetReplayRequest'->new($_) } @$_ ] };

declare 'MapStringGetReplayRequest',
    as HashRef[GetReplayRequest()];

declare 'ListReplayResultsRequest',
    as InstanceOf['Google::Cloud::Policysimulator::V1::Simulator::ListReplayResultsRequest'];

coerce 'ListReplayResultsRequest',
    from HashRef, via { 'Google::Cloud::Policysimulator::V1::Simulator::ListReplayResultsRequest'->new($_) };

declare 'RepeatedListReplayResultsRequest',
    as ArrayRef[ListReplayResultsRequest()];

coerce 'RepeatedListReplayResultsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Policysimulator::V1::Simulator::ListReplayResultsRequest'->new($_) } @$_ ] };

declare 'MapStringListReplayResultsRequest',
    as HashRef[ListReplayResultsRequest()];

declare 'ListReplayResultsResponse',
    as InstanceOf['Google::Cloud::Policysimulator::V1::Simulator::ListReplayResultsResponse'];

coerce 'ListReplayResultsResponse',
    from HashRef, via { 'Google::Cloud::Policysimulator::V1::Simulator::ListReplayResultsResponse'->new($_) };

declare 'RepeatedListReplayResultsResponse',
    as ArrayRef[ListReplayResultsResponse()];

coerce 'RepeatedListReplayResultsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Policysimulator::V1::Simulator::ListReplayResultsResponse'->new($_) } @$_ ] };

declare 'MapStringListReplayResultsResponse',
    as HashRef[ListReplayResultsResponse()];

declare 'ReplayConfig',
    as InstanceOf['Google::Cloud::Policysimulator::V1::Simulator::ReplayConfig'];

coerce 'ReplayConfig',
    from HashRef, via { 'Google::Cloud::Policysimulator::V1::Simulator::ReplayConfig'->new($_) };

declare 'RepeatedReplayConfig',
    as ArrayRef[ReplayConfig()];

coerce 'RepeatedReplayConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Policysimulator::V1::Simulator::ReplayConfig'->new($_) } @$_ ] };

declare 'MapStringReplayConfig',
    as HashRef[ReplayConfig()];

declare 'LogSource',
    as (Int | Str);

declare 'PolicyOverlayEntry',
    as InstanceOf['Google::Cloud::Policysimulator::V1::Simulator::ReplayConfig::PolicyOverlayEntry'];

coerce 'PolicyOverlayEntry',
    from HashRef, via { 'Google::Cloud::Policysimulator::V1::Simulator::ReplayConfig::PolicyOverlayEntry'->new($_) };

declare 'RepeatedPolicyOverlayEntry',
    as ArrayRef[PolicyOverlayEntry()];

coerce 'RepeatedPolicyOverlayEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Policysimulator::V1::Simulator::ReplayConfig::PolicyOverlayEntry'->new($_) } @$_ ] };

declare 'MapStringPolicyOverlayEntry',
    as HashRef[PolicyOverlayEntry()];

declare 'ReplayDiff',
    as InstanceOf['Google::Cloud::Policysimulator::V1::Simulator::ReplayDiff'];

coerce 'ReplayDiff',
    from HashRef, via { 'Google::Cloud::Policysimulator::V1::Simulator::ReplayDiff'->new($_) };

declare 'RepeatedReplayDiff',
    as ArrayRef[ReplayDiff()];

coerce 'RepeatedReplayDiff',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Policysimulator::V1::Simulator::ReplayDiff'->new($_) } @$_ ] };

declare 'MapStringReplayDiff',
    as HashRef[ReplayDiff()];

declare 'AccessStateDiff',
    as InstanceOf['Google::Cloud::Policysimulator::V1::Simulator::AccessStateDiff'];

coerce 'AccessStateDiff',
    from HashRef, via { 'Google::Cloud::Policysimulator::V1::Simulator::AccessStateDiff'->new($_) };

declare 'RepeatedAccessStateDiff',
    as ArrayRef[AccessStateDiff()];

coerce 'RepeatedAccessStateDiff',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Policysimulator::V1::Simulator::AccessStateDiff'->new($_) } @$_ ] };

declare 'MapStringAccessStateDiff',
    as HashRef[AccessStateDiff()];

declare 'AccessChangeType',
    as (Int | Str);

declare 'ExplainedAccess',
    as InstanceOf['Google::Cloud::Policysimulator::V1::Simulator::ExplainedAccess'];

coerce 'ExplainedAccess',
    from HashRef, via { 'Google::Cloud::Policysimulator::V1::Simulator::ExplainedAccess'->new($_) };

declare 'RepeatedExplainedAccess',
    as ArrayRef[ExplainedAccess()];

coerce 'RepeatedExplainedAccess',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Policysimulator::V1::Simulator::ExplainedAccess'->new($_) } @$_ ] };

declare 'MapStringExplainedAccess',
    as HashRef[ExplainedAccess()];

1;

__END__

=head1 NAME

Google::Cloud::Policysimulator::V1::Simulator::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
