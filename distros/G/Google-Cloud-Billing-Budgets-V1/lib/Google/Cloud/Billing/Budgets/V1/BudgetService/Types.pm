package Google::Cloud::Billing::Budgets::V1::BudgetService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'CreateBudgetRequest',
    as InstanceOf['Google::Cloud::Billing::Budgets::V1::BudgetService::CreateBudgetRequest'];

coerce 'CreateBudgetRequest',
    from HashRef, via { 'Google::Cloud::Billing::Budgets::V1::BudgetService::CreateBudgetRequest'->new($_) };

declare 'RepeatedCreateBudgetRequest',
    as ArrayRef[CreateBudgetRequest()];

coerce 'RepeatedCreateBudgetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Billing::Budgets::V1::BudgetService::CreateBudgetRequest'->new($_) } @$_ ] };

declare 'MapStringCreateBudgetRequest',
    as HashRef[CreateBudgetRequest()];

declare 'UpdateBudgetRequest',
    as InstanceOf['Google::Cloud::Billing::Budgets::V1::BudgetService::UpdateBudgetRequest'];

coerce 'UpdateBudgetRequest',
    from HashRef, via { 'Google::Cloud::Billing::Budgets::V1::BudgetService::UpdateBudgetRequest'->new($_) };

declare 'RepeatedUpdateBudgetRequest',
    as ArrayRef[UpdateBudgetRequest()];

coerce 'RepeatedUpdateBudgetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Billing::Budgets::V1::BudgetService::UpdateBudgetRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateBudgetRequest',
    as HashRef[UpdateBudgetRequest()];

declare 'GetBudgetRequest',
    as InstanceOf['Google::Cloud::Billing::Budgets::V1::BudgetService::GetBudgetRequest'];

coerce 'GetBudgetRequest',
    from HashRef, via { 'Google::Cloud::Billing::Budgets::V1::BudgetService::GetBudgetRequest'->new($_) };

declare 'RepeatedGetBudgetRequest',
    as ArrayRef[GetBudgetRequest()];

coerce 'RepeatedGetBudgetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Billing::Budgets::V1::BudgetService::GetBudgetRequest'->new($_) } @$_ ] };

declare 'MapStringGetBudgetRequest',
    as HashRef[GetBudgetRequest()];

declare 'ListBudgetsRequest',
    as InstanceOf['Google::Cloud::Billing::Budgets::V1::BudgetService::ListBudgetsRequest'];

coerce 'ListBudgetsRequest',
    from HashRef, via { 'Google::Cloud::Billing::Budgets::V1::BudgetService::ListBudgetsRequest'->new($_) };

declare 'RepeatedListBudgetsRequest',
    as ArrayRef[ListBudgetsRequest()];

coerce 'RepeatedListBudgetsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Billing::Budgets::V1::BudgetService::ListBudgetsRequest'->new($_) } @$_ ] };

declare 'MapStringListBudgetsRequest',
    as HashRef[ListBudgetsRequest()];

declare 'ListBudgetsResponse',
    as InstanceOf['Google::Cloud::Billing::Budgets::V1::BudgetService::ListBudgetsResponse'];

coerce 'ListBudgetsResponse',
    from HashRef, via { 'Google::Cloud::Billing::Budgets::V1::BudgetService::ListBudgetsResponse'->new($_) };

declare 'RepeatedListBudgetsResponse',
    as ArrayRef[ListBudgetsResponse()];

coerce 'RepeatedListBudgetsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Billing::Budgets::V1::BudgetService::ListBudgetsResponse'->new($_) } @$_ ] };

declare 'MapStringListBudgetsResponse',
    as HashRef[ListBudgetsResponse()];

declare 'DeleteBudgetRequest',
    as InstanceOf['Google::Cloud::Billing::Budgets::V1::BudgetService::DeleteBudgetRequest'];

coerce 'DeleteBudgetRequest',
    from HashRef, via { 'Google::Cloud::Billing::Budgets::V1::BudgetService::DeleteBudgetRequest'->new($_) };

declare 'RepeatedDeleteBudgetRequest',
    as ArrayRef[DeleteBudgetRequest()];

coerce 'RepeatedDeleteBudgetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Billing::Budgets::V1::BudgetService::DeleteBudgetRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteBudgetRequest',
    as HashRef[DeleteBudgetRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Billing::Budgets::V1::BudgetService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
