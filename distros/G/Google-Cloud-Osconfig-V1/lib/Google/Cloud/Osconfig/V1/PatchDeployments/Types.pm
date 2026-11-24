package Google::Cloud::Osconfig::V1::PatchDeployments::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'PatchDeployment',
    as InstanceOf['Google::Cloud::Osconfig::V1::PatchDeployments::PatchDeployment'];

coerce 'PatchDeployment',
    from HashRef, via { 'Google::Cloud::Osconfig::V1::PatchDeployments::PatchDeployment'->new($_) };

declare 'RepeatedPatchDeployment',
    as ArrayRef[PatchDeployment()];

coerce 'RepeatedPatchDeployment',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::V1::PatchDeployments::PatchDeployment'->new($_) } @$_ ] };

declare 'MapStringPatchDeployment',
    as HashRef[PatchDeployment()];

declare 'State',
    as (Int | Str);

declare 'OneTimeSchedule',
    as InstanceOf['Google::Cloud::Osconfig::V1::PatchDeployments::OneTimeSchedule'];

coerce 'OneTimeSchedule',
    from HashRef, via { 'Google::Cloud::Osconfig::V1::PatchDeployments::OneTimeSchedule'->new($_) };

declare 'RepeatedOneTimeSchedule',
    as ArrayRef[OneTimeSchedule()];

coerce 'RepeatedOneTimeSchedule',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::V1::PatchDeployments::OneTimeSchedule'->new($_) } @$_ ] };

declare 'MapStringOneTimeSchedule',
    as HashRef[OneTimeSchedule()];

declare 'RecurringSchedule',
    as InstanceOf['Google::Cloud::Osconfig::V1::PatchDeployments::RecurringSchedule'];

coerce 'RecurringSchedule',
    from HashRef, via { 'Google::Cloud::Osconfig::V1::PatchDeployments::RecurringSchedule'->new($_) };

declare 'RepeatedRecurringSchedule',
    as ArrayRef[RecurringSchedule()];

coerce 'RepeatedRecurringSchedule',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::V1::PatchDeployments::RecurringSchedule'->new($_) } @$_ ] };

declare 'MapStringRecurringSchedule',
    as HashRef[RecurringSchedule()];

declare 'Frequency',
    as (Int | Str);

declare 'WeeklySchedule',
    as InstanceOf['Google::Cloud::Osconfig::V1::PatchDeployments::WeeklySchedule'];

coerce 'WeeklySchedule',
    from HashRef, via { 'Google::Cloud::Osconfig::V1::PatchDeployments::WeeklySchedule'->new($_) };

declare 'RepeatedWeeklySchedule',
    as ArrayRef[WeeklySchedule()];

coerce 'RepeatedWeeklySchedule',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::V1::PatchDeployments::WeeklySchedule'->new($_) } @$_ ] };

declare 'MapStringWeeklySchedule',
    as HashRef[WeeklySchedule()];

declare 'MonthlySchedule',
    as InstanceOf['Google::Cloud::Osconfig::V1::PatchDeployments::MonthlySchedule'];

coerce 'MonthlySchedule',
    from HashRef, via { 'Google::Cloud::Osconfig::V1::PatchDeployments::MonthlySchedule'->new($_) };

declare 'RepeatedMonthlySchedule',
    as ArrayRef[MonthlySchedule()];

coerce 'RepeatedMonthlySchedule',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::V1::PatchDeployments::MonthlySchedule'->new($_) } @$_ ] };

declare 'MapStringMonthlySchedule',
    as HashRef[MonthlySchedule()];

declare 'WeekDayOfMonth',
    as InstanceOf['Google::Cloud::Osconfig::V1::PatchDeployments::WeekDayOfMonth'];

coerce 'WeekDayOfMonth',
    from HashRef, via { 'Google::Cloud::Osconfig::V1::PatchDeployments::WeekDayOfMonth'->new($_) };

declare 'RepeatedWeekDayOfMonth',
    as ArrayRef[WeekDayOfMonth()];

coerce 'RepeatedWeekDayOfMonth',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::V1::PatchDeployments::WeekDayOfMonth'->new($_) } @$_ ] };

declare 'MapStringWeekDayOfMonth',
    as HashRef[WeekDayOfMonth()];

declare 'CreatePatchDeploymentRequest',
    as InstanceOf['Google::Cloud::Osconfig::V1::PatchDeployments::CreatePatchDeploymentRequest'];

coerce 'CreatePatchDeploymentRequest',
    from HashRef, via { 'Google::Cloud::Osconfig::V1::PatchDeployments::CreatePatchDeploymentRequest'->new($_) };

declare 'RepeatedCreatePatchDeploymentRequest',
    as ArrayRef[CreatePatchDeploymentRequest()];

coerce 'RepeatedCreatePatchDeploymentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::V1::PatchDeployments::CreatePatchDeploymentRequest'->new($_) } @$_ ] };

declare 'MapStringCreatePatchDeploymentRequest',
    as HashRef[CreatePatchDeploymentRequest()];

declare 'GetPatchDeploymentRequest',
    as InstanceOf['Google::Cloud::Osconfig::V1::PatchDeployments::GetPatchDeploymentRequest'];

coerce 'GetPatchDeploymentRequest',
    from HashRef, via { 'Google::Cloud::Osconfig::V1::PatchDeployments::GetPatchDeploymentRequest'->new($_) };

declare 'RepeatedGetPatchDeploymentRequest',
    as ArrayRef[GetPatchDeploymentRequest()];

coerce 'RepeatedGetPatchDeploymentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::V1::PatchDeployments::GetPatchDeploymentRequest'->new($_) } @$_ ] };

declare 'MapStringGetPatchDeploymentRequest',
    as HashRef[GetPatchDeploymentRequest()];

declare 'ListPatchDeploymentsRequest',
    as InstanceOf['Google::Cloud::Osconfig::V1::PatchDeployments::ListPatchDeploymentsRequest'];

coerce 'ListPatchDeploymentsRequest',
    from HashRef, via { 'Google::Cloud::Osconfig::V1::PatchDeployments::ListPatchDeploymentsRequest'->new($_) };

declare 'RepeatedListPatchDeploymentsRequest',
    as ArrayRef[ListPatchDeploymentsRequest()];

coerce 'RepeatedListPatchDeploymentsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::V1::PatchDeployments::ListPatchDeploymentsRequest'->new($_) } @$_ ] };

declare 'MapStringListPatchDeploymentsRequest',
    as HashRef[ListPatchDeploymentsRequest()];

declare 'ListPatchDeploymentsResponse',
    as InstanceOf['Google::Cloud::Osconfig::V1::PatchDeployments::ListPatchDeploymentsResponse'];

coerce 'ListPatchDeploymentsResponse',
    from HashRef, via { 'Google::Cloud::Osconfig::V1::PatchDeployments::ListPatchDeploymentsResponse'->new($_) };

declare 'RepeatedListPatchDeploymentsResponse',
    as ArrayRef[ListPatchDeploymentsResponse()];

coerce 'RepeatedListPatchDeploymentsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::V1::PatchDeployments::ListPatchDeploymentsResponse'->new($_) } @$_ ] };

declare 'MapStringListPatchDeploymentsResponse',
    as HashRef[ListPatchDeploymentsResponse()];

declare 'DeletePatchDeploymentRequest',
    as InstanceOf['Google::Cloud::Osconfig::V1::PatchDeployments::DeletePatchDeploymentRequest'];

coerce 'DeletePatchDeploymentRequest',
    from HashRef, via { 'Google::Cloud::Osconfig::V1::PatchDeployments::DeletePatchDeploymentRequest'->new($_) };

declare 'RepeatedDeletePatchDeploymentRequest',
    as ArrayRef[DeletePatchDeploymentRequest()];

coerce 'RepeatedDeletePatchDeploymentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::V1::PatchDeployments::DeletePatchDeploymentRequest'->new($_) } @$_ ] };

declare 'MapStringDeletePatchDeploymentRequest',
    as HashRef[DeletePatchDeploymentRequest()];

declare 'UpdatePatchDeploymentRequest',
    as InstanceOf['Google::Cloud::Osconfig::V1::PatchDeployments::UpdatePatchDeploymentRequest'];

coerce 'UpdatePatchDeploymentRequest',
    from HashRef, via { 'Google::Cloud::Osconfig::V1::PatchDeployments::UpdatePatchDeploymentRequest'->new($_) };

declare 'RepeatedUpdatePatchDeploymentRequest',
    as ArrayRef[UpdatePatchDeploymentRequest()];

coerce 'RepeatedUpdatePatchDeploymentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::V1::PatchDeployments::UpdatePatchDeploymentRequest'->new($_) } @$_ ] };

declare 'MapStringUpdatePatchDeploymentRequest',
    as HashRef[UpdatePatchDeploymentRequest()];

declare 'PausePatchDeploymentRequest',
    as InstanceOf['Google::Cloud::Osconfig::V1::PatchDeployments::PausePatchDeploymentRequest'];

coerce 'PausePatchDeploymentRequest',
    from HashRef, via { 'Google::Cloud::Osconfig::V1::PatchDeployments::PausePatchDeploymentRequest'->new($_) };

declare 'RepeatedPausePatchDeploymentRequest',
    as ArrayRef[PausePatchDeploymentRequest()];

coerce 'RepeatedPausePatchDeploymentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::V1::PatchDeployments::PausePatchDeploymentRequest'->new($_) } @$_ ] };

declare 'MapStringPausePatchDeploymentRequest',
    as HashRef[PausePatchDeploymentRequest()];

declare 'ResumePatchDeploymentRequest',
    as InstanceOf['Google::Cloud::Osconfig::V1::PatchDeployments::ResumePatchDeploymentRequest'];

coerce 'ResumePatchDeploymentRequest',
    from HashRef, via { 'Google::Cloud::Osconfig::V1::PatchDeployments::ResumePatchDeploymentRequest'->new($_) };

declare 'RepeatedResumePatchDeploymentRequest',
    as ArrayRef[ResumePatchDeploymentRequest()];

coerce 'RepeatedResumePatchDeploymentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::V1::PatchDeployments::ResumePatchDeploymentRequest'->new($_) } @$_ ] };

declare 'MapStringResumePatchDeploymentRequest',
    as HashRef[ResumePatchDeploymentRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Osconfig::V1::PatchDeployments::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
