package Google::Cloud::Saasplatform::Saasservicemgmt::V1::Common::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'UnitOperationErrorCategory',
    as (Int | Str);

declare 'Blueprint',
    as InstanceOf['Google::Cloud::Saasplatform::Saasservicemgmt::V1::Common::Blueprint'];

coerce 'Blueprint',
    from HashRef, via { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::Common::Blueprint'->new($_) };

declare 'RepeatedBlueprint',
    as ArrayRef[Blueprint()];

coerce 'RepeatedBlueprint',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::Common::Blueprint'->new($_) } @$_ ] };

declare 'MapStringBlueprint',
    as HashRef[Blueprint()];

declare 'UnitVariable',
    as InstanceOf['Google::Cloud::Saasplatform::Saasservicemgmt::V1::Common::UnitVariable'];

coerce 'UnitVariable',
    from HashRef, via { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::Common::UnitVariable'->new($_) };

declare 'RepeatedUnitVariable',
    as ArrayRef[UnitVariable()];

coerce 'RepeatedUnitVariable',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::Common::UnitVariable'->new($_) } @$_ ] };

declare 'MapStringUnitVariable',
    as HashRef[UnitVariable()];

declare 'Type',
    as (Int | Str);

declare 'UnitCondition',
    as InstanceOf['Google::Cloud::Saasplatform::Saasservicemgmt::V1::Common::UnitCondition'];

coerce 'UnitCondition',
    from HashRef, via { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::Common::UnitCondition'->new($_) };

declare 'RepeatedUnitCondition',
    as ArrayRef[UnitCondition()];

coerce 'RepeatedUnitCondition',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::Common::UnitCondition'->new($_) } @$_ ] };

declare 'MapStringUnitCondition',
    as HashRef[UnitCondition()];

declare 'Status',
    as (Int | Str);

declare 'Type',
    as (Int | Str);

declare 'UnitOperationCondition',
    as InstanceOf['Google::Cloud::Saasplatform::Saasservicemgmt::V1::Common::UnitOperationCondition'];

coerce 'UnitOperationCondition',
    from HashRef, via { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::Common::UnitOperationCondition'->new($_) };

declare 'RepeatedUnitOperationCondition',
    as ArrayRef[UnitOperationCondition()];

coerce 'RepeatedUnitOperationCondition',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::Common::UnitOperationCondition'->new($_) } @$_ ] };

declare 'MapStringUnitOperationCondition',
    as HashRef[UnitOperationCondition()];

declare 'Status',
    as (Int | Str);

declare 'Type',
    as (Int | Str);

declare 'SaasCondition',
    as InstanceOf['Google::Cloud::Saasplatform::Saasservicemgmt::V1::Common::SaasCondition'];

coerce 'SaasCondition',
    from HashRef, via { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::Common::SaasCondition'->new($_) };

declare 'RepeatedSaasCondition',
    as ArrayRef[SaasCondition()];

coerce 'RepeatedSaasCondition',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::Common::SaasCondition'->new($_) } @$_ ] };

declare 'MapStringSaasCondition',
    as HashRef[SaasCondition()];

declare 'Status',
    as (Int | Str);

declare 'Type',
    as (Int | Str);

declare 'Aggregate',
    as InstanceOf['Google::Cloud::Saasplatform::Saasservicemgmt::V1::Common::Aggregate'];

coerce 'Aggregate',
    from HashRef, via { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::Common::Aggregate'->new($_) };

declare 'RepeatedAggregate',
    as ArrayRef[Aggregate()];

coerce 'RepeatedAggregate',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::Common::Aggregate'->new($_) } @$_ ] };

declare 'MapStringAggregate',
    as HashRef[Aggregate()];

declare 'DurationLimits',
    as InstanceOf['Google::Cloud::Saasplatform::Saasservicemgmt::V1::Common::DurationLimits'];

coerce 'DurationLimits',
    from HashRef, via { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::Common::DurationLimits'->new($_) };

declare 'RepeatedDurationLimits',
    as ArrayRef[DurationLimits()];

coerce 'RepeatedDurationLimits',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::Common::DurationLimits'->new($_) } @$_ ] };

declare 'MapStringDurationLimits',
    as HashRef[DurationLimits()];

1;

__END__

=head1 NAME

Google::Cloud::Saasplatform::Saasservicemgmt::V1::Common::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
