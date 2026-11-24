package Google::Cloud::Cloudcontrolspartner::V1::CustomerWorkloads::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Workload',
    as InstanceOf['Google::Cloud::Cloudcontrolspartner::V1::CustomerWorkloads::Workload'];

coerce 'Workload',
    from HashRef, via { 'Google::Cloud::Cloudcontrolspartner::V1::CustomerWorkloads::Workload'->new($_) };

declare 'RepeatedWorkload',
    as ArrayRef[Workload()];

coerce 'RepeatedWorkload',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Cloudcontrolspartner::V1::CustomerWorkloads::Workload'->new($_) } @$_ ] };

declare 'MapStringWorkload',
    as HashRef[Workload()];

declare 'Partner',
    as (Int | Str);

declare 'ListWorkloadsRequest',
    as InstanceOf['Google::Cloud::Cloudcontrolspartner::V1::CustomerWorkloads::ListWorkloadsRequest'];

coerce 'ListWorkloadsRequest',
    from HashRef, via { 'Google::Cloud::Cloudcontrolspartner::V1::CustomerWorkloads::ListWorkloadsRequest'->new($_) };

declare 'RepeatedListWorkloadsRequest',
    as ArrayRef[ListWorkloadsRequest()];

coerce 'RepeatedListWorkloadsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Cloudcontrolspartner::V1::CustomerWorkloads::ListWorkloadsRequest'->new($_) } @$_ ] };

declare 'MapStringListWorkloadsRequest',
    as HashRef[ListWorkloadsRequest()];

declare 'ListWorkloadsResponse',
    as InstanceOf['Google::Cloud::Cloudcontrolspartner::V1::CustomerWorkloads::ListWorkloadsResponse'];

coerce 'ListWorkloadsResponse',
    from HashRef, via { 'Google::Cloud::Cloudcontrolspartner::V1::CustomerWorkloads::ListWorkloadsResponse'->new($_) };

declare 'RepeatedListWorkloadsResponse',
    as ArrayRef[ListWorkloadsResponse()];

coerce 'RepeatedListWorkloadsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Cloudcontrolspartner::V1::CustomerWorkloads::ListWorkloadsResponse'->new($_) } @$_ ] };

declare 'MapStringListWorkloadsResponse',
    as HashRef[ListWorkloadsResponse()];

declare 'GetWorkloadRequest',
    as InstanceOf['Google::Cloud::Cloudcontrolspartner::V1::CustomerWorkloads::GetWorkloadRequest'];

coerce 'GetWorkloadRequest',
    from HashRef, via { 'Google::Cloud::Cloudcontrolspartner::V1::CustomerWorkloads::GetWorkloadRequest'->new($_) };

declare 'RepeatedGetWorkloadRequest',
    as ArrayRef[GetWorkloadRequest()];

coerce 'RepeatedGetWorkloadRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Cloudcontrolspartner::V1::CustomerWorkloads::GetWorkloadRequest'->new($_) } @$_ ] };

declare 'MapStringGetWorkloadRequest',
    as HashRef[GetWorkloadRequest()];

declare 'WorkloadOnboardingState',
    as InstanceOf['Google::Cloud::Cloudcontrolspartner::V1::CustomerWorkloads::WorkloadOnboardingState'];

coerce 'WorkloadOnboardingState',
    from HashRef, via { 'Google::Cloud::Cloudcontrolspartner::V1::CustomerWorkloads::WorkloadOnboardingState'->new($_) };

declare 'RepeatedWorkloadOnboardingState',
    as ArrayRef[WorkloadOnboardingState()];

coerce 'RepeatedWorkloadOnboardingState',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Cloudcontrolspartner::V1::CustomerWorkloads::WorkloadOnboardingState'->new($_) } @$_ ] };

declare 'MapStringWorkloadOnboardingState',
    as HashRef[WorkloadOnboardingState()];

declare 'WorkloadOnboardingStep',
    as InstanceOf['Google::Cloud::Cloudcontrolspartner::V1::CustomerWorkloads::WorkloadOnboardingStep'];

coerce 'WorkloadOnboardingStep',
    from HashRef, via { 'Google::Cloud::Cloudcontrolspartner::V1::CustomerWorkloads::WorkloadOnboardingStep'->new($_) };

declare 'RepeatedWorkloadOnboardingStep',
    as ArrayRef[WorkloadOnboardingStep()];

coerce 'RepeatedWorkloadOnboardingStep',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Cloudcontrolspartner::V1::CustomerWorkloads::WorkloadOnboardingStep'->new($_) } @$_ ] };

declare 'MapStringWorkloadOnboardingStep',
    as HashRef[WorkloadOnboardingStep()];

declare 'Step',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Cloudcontrolspartner::V1::CustomerWorkloads::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
