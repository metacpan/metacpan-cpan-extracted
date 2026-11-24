package Google::Cloud::Batch::V1alpha::ResourceAllowance::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'CalendarPeriod',
    as (Int | Str);

declare 'ResourceAllowanceState',
    as (Int | Str);

declare 'ResourceAllowance',
    as InstanceOf['Google::Cloud::Batch::V1alpha::ResourceAllowance::ResourceAllowance'];

coerce 'ResourceAllowance',
    from HashRef, via { 'Google::Cloud::Batch::V1alpha::ResourceAllowance::ResourceAllowance'->new($_) };

declare 'RepeatedResourceAllowance',
    as ArrayRef[ResourceAllowance()];

coerce 'RepeatedResourceAllowance',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Batch::V1alpha::ResourceAllowance::ResourceAllowance'->new($_) } @$_ ] };

declare 'MapStringResourceAllowance',
    as HashRef[ResourceAllowance()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Batch::V1alpha::ResourceAllowance::ResourceAllowance::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Batch::V1alpha::ResourceAllowance::ResourceAllowance::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Batch::V1alpha::ResourceAllowance::ResourceAllowance::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'UsageResourceAllowance',
    as InstanceOf['Google::Cloud::Batch::V1alpha::ResourceAllowance::UsageResourceAllowance'];

coerce 'UsageResourceAllowance',
    from HashRef, via { 'Google::Cloud::Batch::V1alpha::ResourceAllowance::UsageResourceAllowance'->new($_) };

declare 'RepeatedUsageResourceAllowance',
    as ArrayRef[UsageResourceAllowance()];

coerce 'RepeatedUsageResourceAllowance',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Batch::V1alpha::ResourceAllowance::UsageResourceAllowance'->new($_) } @$_ ] };

declare 'MapStringUsageResourceAllowance',
    as HashRef[UsageResourceAllowance()];

declare 'UsageResourceAllowanceSpec',
    as InstanceOf['Google::Cloud::Batch::V1alpha::ResourceAllowance::UsageResourceAllowanceSpec'];

coerce 'UsageResourceAllowanceSpec',
    from HashRef, via { 'Google::Cloud::Batch::V1alpha::ResourceAllowance::UsageResourceAllowanceSpec'->new($_) };

declare 'RepeatedUsageResourceAllowanceSpec',
    as ArrayRef[UsageResourceAllowanceSpec()];

coerce 'RepeatedUsageResourceAllowanceSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Batch::V1alpha::ResourceAllowance::UsageResourceAllowanceSpec'->new($_) } @$_ ] };

declare 'MapStringUsageResourceAllowanceSpec',
    as HashRef[UsageResourceAllowanceSpec()];

declare 'Limit',
    as InstanceOf['Google::Cloud::Batch::V1alpha::ResourceAllowance::UsageResourceAllowanceSpec::Limit'];

coerce 'Limit',
    from HashRef, via { 'Google::Cloud::Batch::V1alpha::ResourceAllowance::UsageResourceAllowanceSpec::Limit'->new($_) };

declare 'RepeatedLimit',
    as ArrayRef[Limit()];

coerce 'RepeatedLimit',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Batch::V1alpha::ResourceAllowance::UsageResourceAllowanceSpec::Limit'->new($_) } @$_ ] };

declare 'MapStringLimit',
    as HashRef[Limit()];

declare 'UsageResourceAllowanceStatus',
    as InstanceOf['Google::Cloud::Batch::V1alpha::ResourceAllowance::UsageResourceAllowanceStatus'];

coerce 'UsageResourceAllowanceStatus',
    from HashRef, via { 'Google::Cloud::Batch::V1alpha::ResourceAllowance::UsageResourceAllowanceStatus'->new($_) };

declare 'RepeatedUsageResourceAllowanceStatus',
    as ArrayRef[UsageResourceAllowanceStatus()];

coerce 'RepeatedUsageResourceAllowanceStatus',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Batch::V1alpha::ResourceAllowance::UsageResourceAllowanceStatus'->new($_) } @$_ ] };

declare 'MapStringUsageResourceAllowanceStatus',
    as HashRef[UsageResourceAllowanceStatus()];

declare 'LimitStatus',
    as InstanceOf['Google::Cloud::Batch::V1alpha::ResourceAllowance::UsageResourceAllowanceStatus::LimitStatus'];

coerce 'LimitStatus',
    from HashRef, via { 'Google::Cloud::Batch::V1alpha::ResourceAllowance::UsageResourceAllowanceStatus::LimitStatus'->new($_) };

declare 'RepeatedLimitStatus',
    as ArrayRef[LimitStatus()];

coerce 'RepeatedLimitStatus',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Batch::V1alpha::ResourceAllowance::UsageResourceAllowanceStatus::LimitStatus'->new($_) } @$_ ] };

declare 'MapStringLimitStatus',
    as HashRef[LimitStatus()];

declare 'PeriodConsumption',
    as InstanceOf['Google::Cloud::Batch::V1alpha::ResourceAllowance::UsageResourceAllowanceStatus::PeriodConsumption'];

coerce 'PeriodConsumption',
    from HashRef, via { 'Google::Cloud::Batch::V1alpha::ResourceAllowance::UsageResourceAllowanceStatus::PeriodConsumption'->new($_) };

declare 'RepeatedPeriodConsumption',
    as ArrayRef[PeriodConsumption()];

coerce 'RepeatedPeriodConsumption',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Batch::V1alpha::ResourceAllowance::UsageResourceAllowanceStatus::PeriodConsumption'->new($_) } @$_ ] };

declare 'MapStringPeriodConsumption',
    as HashRef[PeriodConsumption()];

declare 'ConsumptionReport',
    as InstanceOf['Google::Cloud::Batch::V1alpha::ResourceAllowance::UsageResourceAllowanceStatus::ConsumptionReport'];

coerce 'ConsumptionReport',
    from HashRef, via { 'Google::Cloud::Batch::V1alpha::ResourceAllowance::UsageResourceAllowanceStatus::ConsumptionReport'->new($_) };

declare 'RepeatedConsumptionReport',
    as ArrayRef[ConsumptionReport()];

coerce 'RepeatedConsumptionReport',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Batch::V1alpha::ResourceAllowance::UsageResourceAllowanceStatus::ConsumptionReport'->new($_) } @$_ ] };

declare 'MapStringConsumptionReport',
    as HashRef[ConsumptionReport()];

declare 'LatestPeriodConsumptionsEntry',
    as InstanceOf['Google::Cloud::Batch::V1alpha::ResourceAllowance::UsageResourceAllowanceStatus::ConsumptionReport::LatestPeriodConsumptionsEntry'];

coerce 'LatestPeriodConsumptionsEntry',
    from HashRef, via { 'Google::Cloud::Batch::V1alpha::ResourceAllowance::UsageResourceAllowanceStatus::ConsumptionReport::LatestPeriodConsumptionsEntry'->new($_) };

declare 'RepeatedLatestPeriodConsumptionsEntry',
    as ArrayRef[LatestPeriodConsumptionsEntry()];

coerce 'RepeatedLatestPeriodConsumptionsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Batch::V1alpha::ResourceAllowance::UsageResourceAllowanceStatus::ConsumptionReport::LatestPeriodConsumptionsEntry'->new($_) } @$_ ] };

declare 'MapStringLatestPeriodConsumptionsEntry',
    as HashRef[LatestPeriodConsumptionsEntry()];

1;

__END__

=head1 NAME

Google::Cloud::Batch::V1alpha::ResourceAllowance::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
