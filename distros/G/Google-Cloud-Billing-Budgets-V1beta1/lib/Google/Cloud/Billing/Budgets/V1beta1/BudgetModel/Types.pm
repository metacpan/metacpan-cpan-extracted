package Google::Cloud::Billing::Budgets::V1beta1::BudgetModel::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'CalendarPeriod',
    as (Int | Str);

declare 'Budget',
    as InstanceOf['Google::Cloud::Billing::Budgets::V1beta1::BudgetModel::Budget'];

coerce 'Budget',
    from HashRef, via { 'Google::Cloud::Billing::Budgets::V1beta1::BudgetModel::Budget'->new($_) };

declare 'RepeatedBudget',
    as ArrayRef[Budget()];

coerce 'RepeatedBudget',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Billing::Budgets::V1beta1::BudgetModel::Budget'->new($_) } @$_ ] };

declare 'MapStringBudget',
    as HashRef[Budget()];

declare 'BudgetAmount',
    as InstanceOf['Google::Cloud::Billing::Budgets::V1beta1::BudgetModel::BudgetAmount'];

coerce 'BudgetAmount',
    from HashRef, via { 'Google::Cloud::Billing::Budgets::V1beta1::BudgetModel::BudgetAmount'->new($_) };

declare 'RepeatedBudgetAmount',
    as ArrayRef[BudgetAmount()];

coerce 'RepeatedBudgetAmount',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Billing::Budgets::V1beta1::BudgetModel::BudgetAmount'->new($_) } @$_ ] };

declare 'MapStringBudgetAmount',
    as HashRef[BudgetAmount()];

declare 'LastPeriodAmount',
    as InstanceOf['Google::Cloud::Billing::Budgets::V1beta1::BudgetModel::LastPeriodAmount'];

coerce 'LastPeriodAmount',
    from HashRef, via { 'Google::Cloud::Billing::Budgets::V1beta1::BudgetModel::LastPeriodAmount'->new($_) };

declare 'RepeatedLastPeriodAmount',
    as ArrayRef[LastPeriodAmount()];

coerce 'RepeatedLastPeriodAmount',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Billing::Budgets::V1beta1::BudgetModel::LastPeriodAmount'->new($_) } @$_ ] };

declare 'MapStringLastPeriodAmount',
    as HashRef[LastPeriodAmount()];

declare 'ThresholdRule',
    as InstanceOf['Google::Cloud::Billing::Budgets::V1beta1::BudgetModel::ThresholdRule'];

coerce 'ThresholdRule',
    from HashRef, via { 'Google::Cloud::Billing::Budgets::V1beta1::BudgetModel::ThresholdRule'->new($_) };

declare 'RepeatedThresholdRule',
    as ArrayRef[ThresholdRule()];

coerce 'RepeatedThresholdRule',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Billing::Budgets::V1beta1::BudgetModel::ThresholdRule'->new($_) } @$_ ] };

declare 'MapStringThresholdRule',
    as HashRef[ThresholdRule()];

declare 'Basis',
    as (Int | Str);

declare 'AllUpdatesRule',
    as InstanceOf['Google::Cloud::Billing::Budgets::V1beta1::BudgetModel::AllUpdatesRule'];

coerce 'AllUpdatesRule',
    from HashRef, via { 'Google::Cloud::Billing::Budgets::V1beta1::BudgetModel::AllUpdatesRule'->new($_) };

declare 'RepeatedAllUpdatesRule',
    as ArrayRef[AllUpdatesRule()];

coerce 'RepeatedAllUpdatesRule',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Billing::Budgets::V1beta1::BudgetModel::AllUpdatesRule'->new($_) } @$_ ] };

declare 'MapStringAllUpdatesRule',
    as HashRef[AllUpdatesRule()];

declare 'Filter',
    as InstanceOf['Google::Cloud::Billing::Budgets::V1beta1::BudgetModel::Filter'];

coerce 'Filter',
    from HashRef, via { 'Google::Cloud::Billing::Budgets::V1beta1::BudgetModel::Filter'->new($_) };

declare 'RepeatedFilter',
    as ArrayRef[Filter()];

coerce 'RepeatedFilter',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Billing::Budgets::V1beta1::BudgetModel::Filter'->new($_) } @$_ ] };

declare 'MapStringFilter',
    as HashRef[Filter()];

declare 'CreditTypesTreatment',
    as (Int | Str);

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Billing::Budgets::V1beta1::BudgetModel::Filter::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Billing::Budgets::V1beta1::BudgetModel::Filter::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Billing::Budgets::V1beta1::BudgetModel::Filter::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'CustomPeriod',
    as InstanceOf['Google::Cloud::Billing::Budgets::V1beta1::BudgetModel::CustomPeriod'];

coerce 'CustomPeriod',
    from HashRef, via { 'Google::Cloud::Billing::Budgets::V1beta1::BudgetModel::CustomPeriod'->new($_) };

declare 'RepeatedCustomPeriod',
    as ArrayRef[CustomPeriod()];

coerce 'RepeatedCustomPeriod',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Billing::Budgets::V1beta1::BudgetModel::CustomPeriod'->new($_) } @$_ ] };

declare 'MapStringCustomPeriod',
    as HashRef[CustomPeriod()];

1;

__END__

=head1 NAME

Google::Cloud::Billing::Budgets::V1beta1::BudgetModel::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
