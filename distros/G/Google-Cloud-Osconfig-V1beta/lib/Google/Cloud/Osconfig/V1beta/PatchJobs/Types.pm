package Google::Cloud::Osconfig::V1beta::PatchJobs::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ExecutePatchJobRequest',
    as InstanceOf['Google::Cloud::Osconfig::V1beta::PatchJobs::ExecutePatchJobRequest'];

coerce 'ExecutePatchJobRequest',
    from HashRef, via { 'Google::Cloud::Osconfig::V1beta::PatchJobs::ExecutePatchJobRequest'->new($_) };

declare 'RepeatedExecutePatchJobRequest',
    as ArrayRef[ExecutePatchJobRequest()];

coerce 'RepeatedExecutePatchJobRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::V1beta::PatchJobs::ExecutePatchJobRequest'->new($_) } @$_ ] };

declare 'MapStringExecutePatchJobRequest',
    as HashRef[ExecutePatchJobRequest()];

declare 'GetPatchJobRequest',
    as InstanceOf['Google::Cloud::Osconfig::V1beta::PatchJobs::GetPatchJobRequest'];

coerce 'GetPatchJobRequest',
    from HashRef, via { 'Google::Cloud::Osconfig::V1beta::PatchJobs::GetPatchJobRequest'->new($_) };

declare 'RepeatedGetPatchJobRequest',
    as ArrayRef[GetPatchJobRequest()];

coerce 'RepeatedGetPatchJobRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::V1beta::PatchJobs::GetPatchJobRequest'->new($_) } @$_ ] };

declare 'MapStringGetPatchJobRequest',
    as HashRef[GetPatchJobRequest()];

declare 'ListPatchJobInstanceDetailsRequest',
    as InstanceOf['Google::Cloud::Osconfig::V1beta::PatchJobs::ListPatchJobInstanceDetailsRequest'];

coerce 'ListPatchJobInstanceDetailsRequest',
    from HashRef, via { 'Google::Cloud::Osconfig::V1beta::PatchJobs::ListPatchJobInstanceDetailsRequest'->new($_) };

declare 'RepeatedListPatchJobInstanceDetailsRequest',
    as ArrayRef[ListPatchJobInstanceDetailsRequest()];

coerce 'RepeatedListPatchJobInstanceDetailsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::V1beta::PatchJobs::ListPatchJobInstanceDetailsRequest'->new($_) } @$_ ] };

declare 'MapStringListPatchJobInstanceDetailsRequest',
    as HashRef[ListPatchJobInstanceDetailsRequest()];

declare 'ListPatchJobInstanceDetailsResponse',
    as InstanceOf['Google::Cloud::Osconfig::V1beta::PatchJobs::ListPatchJobInstanceDetailsResponse'];

coerce 'ListPatchJobInstanceDetailsResponse',
    from HashRef, via { 'Google::Cloud::Osconfig::V1beta::PatchJobs::ListPatchJobInstanceDetailsResponse'->new($_) };

declare 'RepeatedListPatchJobInstanceDetailsResponse',
    as ArrayRef[ListPatchJobInstanceDetailsResponse()];

coerce 'RepeatedListPatchJobInstanceDetailsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::V1beta::PatchJobs::ListPatchJobInstanceDetailsResponse'->new($_) } @$_ ] };

declare 'MapStringListPatchJobInstanceDetailsResponse',
    as HashRef[ListPatchJobInstanceDetailsResponse()];

declare 'PatchJobInstanceDetails',
    as InstanceOf['Google::Cloud::Osconfig::V1beta::PatchJobs::PatchJobInstanceDetails'];

coerce 'PatchJobInstanceDetails',
    from HashRef, via { 'Google::Cloud::Osconfig::V1beta::PatchJobs::PatchJobInstanceDetails'->new($_) };

declare 'RepeatedPatchJobInstanceDetails',
    as ArrayRef[PatchJobInstanceDetails()];

coerce 'RepeatedPatchJobInstanceDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::V1beta::PatchJobs::PatchJobInstanceDetails'->new($_) } @$_ ] };

declare 'MapStringPatchJobInstanceDetails',
    as HashRef[PatchJobInstanceDetails()];

declare 'ListPatchJobsRequest',
    as InstanceOf['Google::Cloud::Osconfig::V1beta::PatchJobs::ListPatchJobsRequest'];

coerce 'ListPatchJobsRequest',
    from HashRef, via { 'Google::Cloud::Osconfig::V1beta::PatchJobs::ListPatchJobsRequest'->new($_) };

declare 'RepeatedListPatchJobsRequest',
    as ArrayRef[ListPatchJobsRequest()];

coerce 'RepeatedListPatchJobsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::V1beta::PatchJobs::ListPatchJobsRequest'->new($_) } @$_ ] };

declare 'MapStringListPatchJobsRequest',
    as HashRef[ListPatchJobsRequest()];

declare 'ListPatchJobsResponse',
    as InstanceOf['Google::Cloud::Osconfig::V1beta::PatchJobs::ListPatchJobsResponse'];

coerce 'ListPatchJobsResponse',
    from HashRef, via { 'Google::Cloud::Osconfig::V1beta::PatchJobs::ListPatchJobsResponse'->new($_) };

declare 'RepeatedListPatchJobsResponse',
    as ArrayRef[ListPatchJobsResponse()];

coerce 'RepeatedListPatchJobsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::V1beta::PatchJobs::ListPatchJobsResponse'->new($_) } @$_ ] };

declare 'MapStringListPatchJobsResponse',
    as HashRef[ListPatchJobsResponse()];

declare 'PatchJob',
    as InstanceOf['Google::Cloud::Osconfig::V1beta::PatchJobs::PatchJob'];

coerce 'PatchJob',
    from HashRef, via { 'Google::Cloud::Osconfig::V1beta::PatchJobs::PatchJob'->new($_) };

declare 'RepeatedPatchJob',
    as ArrayRef[PatchJob()];

coerce 'RepeatedPatchJob',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::V1beta::PatchJobs::PatchJob'->new($_) } @$_ ] };

declare 'MapStringPatchJob',
    as HashRef[PatchJob()];

declare 'State',
    as (Int | Str);

declare 'InstanceDetailsSummary',
    as InstanceOf['Google::Cloud::Osconfig::V1beta::PatchJobs::PatchJob::InstanceDetailsSummary'];

coerce 'InstanceDetailsSummary',
    from HashRef, via { 'Google::Cloud::Osconfig::V1beta::PatchJobs::PatchJob::InstanceDetailsSummary'->new($_) };

declare 'RepeatedInstanceDetailsSummary',
    as ArrayRef[InstanceDetailsSummary()];

coerce 'RepeatedInstanceDetailsSummary',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::V1beta::PatchJobs::PatchJob::InstanceDetailsSummary'->new($_) } @$_ ] };

declare 'MapStringInstanceDetailsSummary',
    as HashRef[InstanceDetailsSummary()];

declare 'PatchConfig',
    as InstanceOf['Google::Cloud::Osconfig::V1beta::PatchJobs::PatchConfig'];

coerce 'PatchConfig',
    from HashRef, via { 'Google::Cloud::Osconfig::V1beta::PatchJobs::PatchConfig'->new($_) };

declare 'RepeatedPatchConfig',
    as ArrayRef[PatchConfig()];

coerce 'RepeatedPatchConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::V1beta::PatchJobs::PatchConfig'->new($_) } @$_ ] };

declare 'MapStringPatchConfig',
    as HashRef[PatchConfig()];

declare 'RebootConfig',
    as (Int | Str);

declare 'Instance',
    as InstanceOf['Google::Cloud::Osconfig::V1beta::PatchJobs::Instance'];

coerce 'Instance',
    from HashRef, via { 'Google::Cloud::Osconfig::V1beta::PatchJobs::Instance'->new($_) };

declare 'RepeatedInstance',
    as ArrayRef[Instance()];

coerce 'RepeatedInstance',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::V1beta::PatchJobs::Instance'->new($_) } @$_ ] };

declare 'MapStringInstance',
    as HashRef[Instance()];

declare 'PatchState',
    as (Int | Str);

declare 'CancelPatchJobRequest',
    as InstanceOf['Google::Cloud::Osconfig::V1beta::PatchJobs::CancelPatchJobRequest'];

coerce 'CancelPatchJobRequest',
    from HashRef, via { 'Google::Cloud::Osconfig::V1beta::PatchJobs::CancelPatchJobRequest'->new($_) };

declare 'RepeatedCancelPatchJobRequest',
    as ArrayRef[CancelPatchJobRequest()];

coerce 'RepeatedCancelPatchJobRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::V1beta::PatchJobs::CancelPatchJobRequest'->new($_) } @$_ ] };

declare 'MapStringCancelPatchJobRequest',
    as HashRef[CancelPatchJobRequest()];

declare 'AptSettings',
    as InstanceOf['Google::Cloud::Osconfig::V1beta::PatchJobs::AptSettings'];

coerce 'AptSettings',
    from HashRef, via { 'Google::Cloud::Osconfig::V1beta::PatchJobs::AptSettings'->new($_) };

declare 'RepeatedAptSettings',
    as ArrayRef[AptSettings()];

coerce 'RepeatedAptSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::V1beta::PatchJobs::AptSettings'->new($_) } @$_ ] };

declare 'MapStringAptSettings',
    as HashRef[AptSettings()];

declare 'Type',
    as (Int | Str);

declare 'YumSettings',
    as InstanceOf['Google::Cloud::Osconfig::V1beta::PatchJobs::YumSettings'];

coerce 'YumSettings',
    from HashRef, via { 'Google::Cloud::Osconfig::V1beta::PatchJobs::YumSettings'->new($_) };

declare 'RepeatedYumSettings',
    as ArrayRef[YumSettings()];

coerce 'RepeatedYumSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::V1beta::PatchJobs::YumSettings'->new($_) } @$_ ] };

declare 'MapStringYumSettings',
    as HashRef[YumSettings()];

declare 'GooSettings',
    as InstanceOf['Google::Cloud::Osconfig::V1beta::PatchJobs::GooSettings'];

coerce 'GooSettings',
    from HashRef, via { 'Google::Cloud::Osconfig::V1beta::PatchJobs::GooSettings'->new($_) };

declare 'RepeatedGooSettings',
    as ArrayRef[GooSettings()];

coerce 'RepeatedGooSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::V1beta::PatchJobs::GooSettings'->new($_) } @$_ ] };

declare 'MapStringGooSettings',
    as HashRef[GooSettings()];

declare 'ZypperSettings',
    as InstanceOf['Google::Cloud::Osconfig::V1beta::PatchJobs::ZypperSettings'];

coerce 'ZypperSettings',
    from HashRef, via { 'Google::Cloud::Osconfig::V1beta::PatchJobs::ZypperSettings'->new($_) };

declare 'RepeatedZypperSettings',
    as ArrayRef[ZypperSettings()];

coerce 'RepeatedZypperSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::V1beta::PatchJobs::ZypperSettings'->new($_) } @$_ ] };

declare 'MapStringZypperSettings',
    as HashRef[ZypperSettings()];

declare 'WindowsUpdateSettings',
    as InstanceOf['Google::Cloud::Osconfig::V1beta::PatchJobs::WindowsUpdateSettings'];

coerce 'WindowsUpdateSettings',
    from HashRef, via { 'Google::Cloud::Osconfig::V1beta::PatchJobs::WindowsUpdateSettings'->new($_) };

declare 'RepeatedWindowsUpdateSettings',
    as ArrayRef[WindowsUpdateSettings()];

coerce 'RepeatedWindowsUpdateSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::V1beta::PatchJobs::WindowsUpdateSettings'->new($_) } @$_ ] };

declare 'MapStringWindowsUpdateSettings',
    as HashRef[WindowsUpdateSettings()];

declare 'Classification',
    as (Int | Str);

declare 'ExecStep',
    as InstanceOf['Google::Cloud::Osconfig::V1beta::PatchJobs::ExecStep'];

coerce 'ExecStep',
    from HashRef, via { 'Google::Cloud::Osconfig::V1beta::PatchJobs::ExecStep'->new($_) };

declare 'RepeatedExecStep',
    as ArrayRef[ExecStep()];

coerce 'RepeatedExecStep',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::V1beta::PatchJobs::ExecStep'->new($_) } @$_ ] };

declare 'MapStringExecStep',
    as HashRef[ExecStep()];

declare 'ExecStepConfig',
    as InstanceOf['Google::Cloud::Osconfig::V1beta::PatchJobs::ExecStepConfig'];

coerce 'ExecStepConfig',
    from HashRef, via { 'Google::Cloud::Osconfig::V1beta::PatchJobs::ExecStepConfig'->new($_) };

declare 'RepeatedExecStepConfig',
    as ArrayRef[ExecStepConfig()];

coerce 'RepeatedExecStepConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::V1beta::PatchJobs::ExecStepConfig'->new($_) } @$_ ] };

declare 'MapStringExecStepConfig',
    as HashRef[ExecStepConfig()];

declare 'Interpreter',
    as (Int | Str);

declare 'GcsObject',
    as InstanceOf['Google::Cloud::Osconfig::V1beta::PatchJobs::GcsObject'];

coerce 'GcsObject',
    from HashRef, via { 'Google::Cloud::Osconfig::V1beta::PatchJobs::GcsObject'->new($_) };

declare 'RepeatedGcsObject',
    as ArrayRef[GcsObject()];

coerce 'RepeatedGcsObject',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::V1beta::PatchJobs::GcsObject'->new($_) } @$_ ] };

declare 'MapStringGcsObject',
    as HashRef[GcsObject()];

declare 'PatchInstanceFilter',
    as InstanceOf['Google::Cloud::Osconfig::V1beta::PatchJobs::PatchInstanceFilter'];

coerce 'PatchInstanceFilter',
    from HashRef, via { 'Google::Cloud::Osconfig::V1beta::PatchJobs::PatchInstanceFilter'->new($_) };

declare 'RepeatedPatchInstanceFilter',
    as ArrayRef[PatchInstanceFilter()];

coerce 'RepeatedPatchInstanceFilter',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::V1beta::PatchJobs::PatchInstanceFilter'->new($_) } @$_ ] };

declare 'MapStringPatchInstanceFilter',
    as HashRef[PatchInstanceFilter()];

declare 'GroupLabel',
    as InstanceOf['Google::Cloud::Osconfig::V1beta::PatchJobs::PatchInstanceFilter::GroupLabel'];

coerce 'GroupLabel',
    from HashRef, via { 'Google::Cloud::Osconfig::V1beta::PatchJobs::PatchInstanceFilter::GroupLabel'->new($_) };

declare 'RepeatedGroupLabel',
    as ArrayRef[GroupLabel()];

coerce 'RepeatedGroupLabel',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::V1beta::PatchJobs::PatchInstanceFilter::GroupLabel'->new($_) } @$_ ] };

declare 'MapStringGroupLabel',
    as HashRef[GroupLabel()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Osconfig::V1beta::PatchJobs::PatchInstanceFilter::GroupLabel::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Osconfig::V1beta::PatchJobs::PatchInstanceFilter::GroupLabel::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::V1beta::PatchJobs::PatchInstanceFilter::GroupLabel::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'PatchRollout',
    as InstanceOf['Google::Cloud::Osconfig::V1beta::PatchJobs::PatchRollout'];

coerce 'PatchRollout',
    from HashRef, via { 'Google::Cloud::Osconfig::V1beta::PatchJobs::PatchRollout'->new($_) };

declare 'RepeatedPatchRollout',
    as ArrayRef[PatchRollout()];

coerce 'RepeatedPatchRollout',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::V1beta::PatchJobs::PatchRollout'->new($_) } @$_ ] };

declare 'MapStringPatchRollout',
    as HashRef[PatchRollout()];

declare 'Mode',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Osconfig::V1beta::PatchJobs::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
