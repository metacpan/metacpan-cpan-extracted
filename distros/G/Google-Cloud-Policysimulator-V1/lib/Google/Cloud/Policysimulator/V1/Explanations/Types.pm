package Google::Cloud::Policysimulator::V1::Explanations::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'AccessState',
    as (Int | Str);

declare 'HeuristicRelevance',
    as (Int | Str);

declare 'AccessTuple',
    as InstanceOf['Google::Cloud::Policysimulator::V1::Explanations::AccessTuple'];

coerce 'AccessTuple',
    from HashRef, via { 'Google::Cloud::Policysimulator::V1::Explanations::AccessTuple'->new($_) };

declare 'RepeatedAccessTuple',
    as ArrayRef[AccessTuple()];

coerce 'RepeatedAccessTuple',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Policysimulator::V1::Explanations::AccessTuple'->new($_) } @$_ ] };

declare 'MapStringAccessTuple',
    as HashRef[AccessTuple()];

declare 'ExplainedPolicy',
    as InstanceOf['Google::Cloud::Policysimulator::V1::Explanations::ExplainedPolicy'];

coerce 'ExplainedPolicy',
    from HashRef, via { 'Google::Cloud::Policysimulator::V1::Explanations::ExplainedPolicy'->new($_) };

declare 'RepeatedExplainedPolicy',
    as ArrayRef[ExplainedPolicy()];

coerce 'RepeatedExplainedPolicy',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Policysimulator::V1::Explanations::ExplainedPolicy'->new($_) } @$_ ] };

declare 'MapStringExplainedPolicy',
    as HashRef[ExplainedPolicy()];

declare 'BindingExplanation',
    as InstanceOf['Google::Cloud::Policysimulator::V1::Explanations::BindingExplanation'];

coerce 'BindingExplanation',
    from HashRef, via { 'Google::Cloud::Policysimulator::V1::Explanations::BindingExplanation'->new($_) };

declare 'RepeatedBindingExplanation',
    as ArrayRef[BindingExplanation()];

coerce 'RepeatedBindingExplanation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Policysimulator::V1::Explanations::BindingExplanation'->new($_) } @$_ ] };

declare 'MapStringBindingExplanation',
    as HashRef[BindingExplanation()];

declare 'RolePermission',
    as (Int | Str);

declare 'Membership',
    as (Int | Str);

declare 'AnnotatedMembership',
    as InstanceOf['Google::Cloud::Policysimulator::V1::Explanations::BindingExplanation::AnnotatedMembership'];

coerce 'AnnotatedMembership',
    from HashRef, via { 'Google::Cloud::Policysimulator::V1::Explanations::BindingExplanation::AnnotatedMembership'->new($_) };

declare 'RepeatedAnnotatedMembership',
    as ArrayRef[AnnotatedMembership()];

coerce 'RepeatedAnnotatedMembership',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Policysimulator::V1::Explanations::BindingExplanation::AnnotatedMembership'->new($_) } @$_ ] };

declare 'MapStringAnnotatedMembership',
    as HashRef[AnnotatedMembership()];

declare 'MembershipsEntry',
    as InstanceOf['Google::Cloud::Policysimulator::V1::Explanations::BindingExplanation::MembershipsEntry'];

coerce 'MembershipsEntry',
    from HashRef, via { 'Google::Cloud::Policysimulator::V1::Explanations::BindingExplanation::MembershipsEntry'->new($_) };

declare 'RepeatedMembershipsEntry',
    as ArrayRef[MembershipsEntry()];

coerce 'RepeatedMembershipsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Policysimulator::V1::Explanations::BindingExplanation::MembershipsEntry'->new($_) } @$_ ] };

declare 'MapStringMembershipsEntry',
    as HashRef[MembershipsEntry()];

1;

__END__

=head1 NAME

Google::Cloud::Policysimulator::V1::Explanations::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
