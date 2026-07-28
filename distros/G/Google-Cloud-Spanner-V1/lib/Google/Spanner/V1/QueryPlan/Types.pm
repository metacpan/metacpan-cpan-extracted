package Google::Spanner::V1::QueryPlan::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'PlanNode',
    as InstanceOf['Google::Spanner::V1::QueryPlan::PlanNode'];

coerce 'PlanNode',
    from HashRef, via { 'Google::Spanner::V1::QueryPlan::PlanNode'->new($_) };

declare 'RepeatedPlanNode',
    as ArrayRef[PlanNode()];

coerce 'RepeatedPlanNode',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::V1::QueryPlan::PlanNode'->new($_) } @$_ ] };

declare 'MapStringPlanNode',
    as HashRef[PlanNode()];

declare 'Kind',
    as (Int | Str);

declare 'ChildLink',
    as InstanceOf['Google::Spanner::V1::QueryPlan::PlanNode::ChildLink'];

coerce 'ChildLink',
    from HashRef, via { 'Google::Spanner::V1::QueryPlan::PlanNode::ChildLink'->new($_) };

declare 'RepeatedChildLink',
    as ArrayRef[ChildLink()];

coerce 'RepeatedChildLink',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::V1::QueryPlan::PlanNode::ChildLink'->new($_) } @$_ ] };

declare 'MapStringChildLink',
    as HashRef[ChildLink()];

declare 'ShortRepresentation',
    as InstanceOf['Google::Spanner::V1::QueryPlan::PlanNode::ShortRepresentation'];

coerce 'ShortRepresentation',
    from HashRef, via { 'Google::Spanner::V1::QueryPlan::PlanNode::ShortRepresentation'->new($_) };

declare 'RepeatedShortRepresentation',
    as ArrayRef[ShortRepresentation()];

coerce 'RepeatedShortRepresentation',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::V1::QueryPlan::PlanNode::ShortRepresentation'->new($_) } @$_ ] };

declare 'MapStringShortRepresentation',
    as HashRef[ShortRepresentation()];

declare 'SubqueriesEntry',
    as InstanceOf['Google::Spanner::V1::QueryPlan::PlanNode::ShortRepresentation::SubqueriesEntry'];

coerce 'SubqueriesEntry',
    from HashRef, via { 'Google::Spanner::V1::QueryPlan::PlanNode::ShortRepresentation::SubqueriesEntry'->new($_) };

declare 'RepeatedSubqueriesEntry',
    as ArrayRef[SubqueriesEntry()];

coerce 'RepeatedSubqueriesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::V1::QueryPlan::PlanNode::ShortRepresentation::SubqueriesEntry'->new($_) } @$_ ] };

declare 'MapStringSubqueriesEntry',
    as HashRef[SubqueriesEntry()];

declare 'QueryAdvisorResult',
    as InstanceOf['Google::Spanner::V1::QueryPlan::QueryAdvisorResult'];

coerce 'QueryAdvisorResult',
    from HashRef, via { 'Google::Spanner::V1::QueryPlan::QueryAdvisorResult'->new($_) };

declare 'RepeatedQueryAdvisorResult',
    as ArrayRef[QueryAdvisorResult()];

coerce 'RepeatedQueryAdvisorResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::V1::QueryPlan::QueryAdvisorResult'->new($_) } @$_ ] };

declare 'MapStringQueryAdvisorResult',
    as HashRef[QueryAdvisorResult()];

declare 'IndexAdvice',
    as InstanceOf['Google::Spanner::V1::QueryPlan::QueryAdvisorResult::IndexAdvice'];

coerce 'IndexAdvice',
    from HashRef, via { 'Google::Spanner::V1::QueryPlan::QueryAdvisorResult::IndexAdvice'->new($_) };

declare 'RepeatedIndexAdvice',
    as ArrayRef[IndexAdvice()];

coerce 'RepeatedIndexAdvice',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::V1::QueryPlan::QueryAdvisorResult::IndexAdvice'->new($_) } @$_ ] };

declare 'MapStringIndexAdvice',
    as HashRef[IndexAdvice()];

declare 'QueryPlan',
    as InstanceOf['Google::Spanner::V1::QueryPlan::QueryPlan'];

coerce 'QueryPlan',
    from HashRef, via { 'Google::Spanner::V1::QueryPlan::QueryPlan'->new($_) };

declare 'RepeatedQueryPlan',
    as ArrayRef[QueryPlan()];

coerce 'RepeatedQueryPlan',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::V1::QueryPlan::QueryPlan'->new($_) } @$_ ] };

declare 'MapStringQueryPlan',
    as HashRef[QueryPlan()];

1;

__END__

=head1 NAME

Google::Spanner::V1::QueryPlan::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
