package Google::Cloud::Saasplatform::Saasservicemgmt::V1::RolloutsResources::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'RolloutAction',
    as (Int | Str);

declare 'Rollout',
    as InstanceOf['Google::Cloud::Saasplatform::Saasservicemgmt::V1::RolloutsResources::Rollout'];

coerce 'Rollout',
    from HashRef, via { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::RolloutsResources::Rollout'->new($_) };

declare 'RepeatedRollout',
    as ArrayRef[Rollout()];

coerce 'RepeatedRollout',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::RolloutsResources::Rollout'->new($_) } @$_ ] };

declare 'MapStringRollout',
    as HashRef[Rollout()];

declare 'RolloutState',
    as (Int | Str);

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Saasplatform::Saasservicemgmt::V1::RolloutsResources::Rollout::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::RolloutsResources::Rollout::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::RolloutsResources::Rollout::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'AnnotationsEntry',
    as InstanceOf['Google::Cloud::Saasplatform::Saasservicemgmt::V1::RolloutsResources::Rollout::AnnotationsEntry'];

coerce 'AnnotationsEntry',
    from HashRef, via { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::RolloutsResources::Rollout::AnnotationsEntry'->new($_) };

declare 'RepeatedAnnotationsEntry',
    as ArrayRef[AnnotationsEntry()];

coerce 'RepeatedAnnotationsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::RolloutsResources::Rollout::AnnotationsEntry'->new($_) } @$_ ] };

declare 'MapStringAnnotationsEntry',
    as HashRef[AnnotationsEntry()];

declare 'RolloutKind',
    as InstanceOf['Google::Cloud::Saasplatform::Saasservicemgmt::V1::RolloutsResources::RolloutKind'];

coerce 'RolloutKind',
    from HashRef, via { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::RolloutsResources::RolloutKind'->new($_) };

declare 'RepeatedRolloutKind',
    as ArrayRef[RolloutKind()];

coerce 'RepeatedRolloutKind',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::RolloutsResources::RolloutKind'->new($_) } @$_ ] };

declare 'MapStringRolloutKind',
    as HashRef[RolloutKind()];

declare 'UpdateUnitKindStrategy',
    as (Int | Str);

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Saasplatform::Saasservicemgmt::V1::RolloutsResources::RolloutKind::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::RolloutsResources::RolloutKind::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::RolloutsResources::RolloutKind::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'AnnotationsEntry',
    as InstanceOf['Google::Cloud::Saasplatform::Saasservicemgmt::V1::RolloutsResources::RolloutKind::AnnotationsEntry'];

coerce 'AnnotationsEntry',
    from HashRef, via { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::RolloutsResources::RolloutKind::AnnotationsEntry'->new($_) };

declare 'RepeatedAnnotationsEntry',
    as ArrayRef[AnnotationsEntry()];

coerce 'RepeatedAnnotationsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::RolloutsResources::RolloutKind::AnnotationsEntry'->new($_) } @$_ ] };

declare 'MapStringAnnotationsEntry',
    as HashRef[AnnotationsEntry()];

declare 'ErrorBudget',
    as InstanceOf['Google::Cloud::Saasplatform::Saasservicemgmt::V1::RolloutsResources::ErrorBudget'];

coerce 'ErrorBudget',
    from HashRef, via { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::RolloutsResources::ErrorBudget'->new($_) };

declare 'RepeatedErrorBudget',
    as ArrayRef[ErrorBudget()];

coerce 'RepeatedErrorBudget',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::RolloutsResources::ErrorBudget'->new($_) } @$_ ] };

declare 'MapStringErrorBudget',
    as HashRef[ErrorBudget()];

declare 'UnitUpdatePacing',
    as InstanceOf['Google::Cloud::Saasplatform::Saasservicemgmt::V1::RolloutsResources::UnitUpdatePacing'];

coerce 'UnitUpdatePacing',
    from HashRef, via { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::RolloutsResources::UnitUpdatePacing'->new($_) };

declare 'RepeatedUnitUpdatePacing',
    as ArrayRef[UnitUpdatePacing()];

coerce 'RepeatedUnitUpdatePacing',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::RolloutsResources::UnitUpdatePacing'->new($_) } @$_ ] };

declare 'MapStringUnitUpdatePacing',
    as HashRef[UnitUpdatePacing()];

declare 'RolloutStats',
    as InstanceOf['Google::Cloud::Saasplatform::Saasservicemgmt::V1::RolloutsResources::RolloutStats'];

coerce 'RolloutStats',
    from HashRef, via { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::RolloutsResources::RolloutStats'->new($_) };

declare 'RepeatedRolloutStats',
    as ArrayRef[RolloutStats()];

coerce 'RepeatedRolloutStats',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::RolloutsResources::RolloutStats'->new($_) } @$_ ] };

declare 'MapStringRolloutStats',
    as HashRef[RolloutStats()];

declare 'RolloutControl',
    as InstanceOf['Google::Cloud::Saasplatform::Saasservicemgmt::V1::RolloutsResources::RolloutControl'];

coerce 'RolloutControl',
    from HashRef, via { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::RolloutsResources::RolloutControl'->new($_) };

declare 'RepeatedRolloutControl',
    as ArrayRef[RolloutControl()];

coerce 'RepeatedRolloutControl',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::RolloutsResources::RolloutControl'->new($_) } @$_ ] };

declare 'MapStringRolloutControl',
    as HashRef[RolloutControl()];

declare 'RunRolloutActionParams',
    as InstanceOf['Google::Cloud::Saasplatform::Saasservicemgmt::V1::RolloutsResources::RolloutControl::RunRolloutActionParams'];

coerce 'RunRolloutActionParams',
    from HashRef, via { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::RolloutsResources::RolloutControl::RunRolloutActionParams'->new($_) };

declare 'RepeatedRunRolloutActionParams',
    as ArrayRef[RunRolloutActionParams()];

coerce 'RepeatedRunRolloutActionParams',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::RolloutsResources::RolloutControl::RunRolloutActionParams'->new($_) } @$_ ] };

declare 'MapStringRunRolloutActionParams',
    as HashRef[RunRolloutActionParams()];

1;

__END__

=head1 NAME

Google::Cloud::Saasplatform::Saasservicemgmt::V1::RolloutsResources::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
