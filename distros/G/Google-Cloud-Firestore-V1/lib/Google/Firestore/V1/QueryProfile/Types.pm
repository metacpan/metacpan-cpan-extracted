package Google::Firestore::V1::QueryProfile::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ExplainOptions',
    as InstanceOf['Google::Firestore::V1::QueryProfile::ExplainOptions'];

coerce 'ExplainOptions',
    from HashRef, via { 'Google::Firestore::V1::QueryProfile::ExplainOptions'->new($_) };

declare 'RepeatedExplainOptions',
    as ArrayRef[ExplainOptions()];

coerce 'RepeatedExplainOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::V1::QueryProfile::ExplainOptions'->new($_) } @$_ ] };

declare 'MapStringExplainOptions',
    as HashRef[ExplainOptions()];

declare 'ExplainMetrics',
    as InstanceOf['Google::Firestore::V1::QueryProfile::ExplainMetrics'];

coerce 'ExplainMetrics',
    from HashRef, via { 'Google::Firestore::V1::QueryProfile::ExplainMetrics'->new($_) };

declare 'RepeatedExplainMetrics',
    as ArrayRef[ExplainMetrics()];

coerce 'RepeatedExplainMetrics',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::V1::QueryProfile::ExplainMetrics'->new($_) } @$_ ] };

declare 'MapStringExplainMetrics',
    as HashRef[ExplainMetrics()];

declare 'PlanSummary',
    as InstanceOf['Google::Firestore::V1::QueryProfile::PlanSummary'];

coerce 'PlanSummary',
    from HashRef, via { 'Google::Firestore::V1::QueryProfile::PlanSummary'->new($_) };

declare 'RepeatedPlanSummary',
    as ArrayRef[PlanSummary()];

coerce 'RepeatedPlanSummary',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::V1::QueryProfile::PlanSummary'->new($_) } @$_ ] };

declare 'MapStringPlanSummary',
    as HashRef[PlanSummary()];

declare 'ExecutionStats',
    as InstanceOf['Google::Firestore::V1::QueryProfile::ExecutionStats'];

coerce 'ExecutionStats',
    from HashRef, via { 'Google::Firestore::V1::QueryProfile::ExecutionStats'->new($_) };

declare 'RepeatedExecutionStats',
    as ArrayRef[ExecutionStats()];

coerce 'RepeatedExecutionStats',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::V1::QueryProfile::ExecutionStats'->new($_) } @$_ ] };

declare 'MapStringExecutionStats',
    as HashRef[ExecutionStats()];

1;

__END__

=head1 NAME

Google::Firestore::V1::QueryProfile::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
