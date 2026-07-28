package Google::Cloud::Dataproc::V1::AutoscalingPolicies::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'AutoscalingPolicy',
    as InstanceOf['Google::Cloud::Dataproc::V1::AutoscalingPolicies::AutoscalingPolicy'];

coerce 'AutoscalingPolicy',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::AutoscalingPolicies::AutoscalingPolicy'->new($_) };

declare 'RepeatedAutoscalingPolicy',
    as ArrayRef[AutoscalingPolicy()];

coerce 'RepeatedAutoscalingPolicy',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::AutoscalingPolicies::AutoscalingPolicy'->new($_) } @$_ ] };

declare 'MapStringAutoscalingPolicy',
    as HashRef[AutoscalingPolicy()];

declare 'ClusterType',
    as (Int | Str);

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Dataproc::V1::AutoscalingPolicies::AutoscalingPolicy::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::AutoscalingPolicies::AutoscalingPolicy::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::AutoscalingPolicies::AutoscalingPolicy::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'BasicAutoscalingAlgorithm',
    as InstanceOf['Google::Cloud::Dataproc::V1::AutoscalingPolicies::BasicAutoscalingAlgorithm'];

coerce 'BasicAutoscalingAlgorithm',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::AutoscalingPolicies::BasicAutoscalingAlgorithm'->new($_) };

declare 'RepeatedBasicAutoscalingAlgorithm',
    as ArrayRef[BasicAutoscalingAlgorithm()];

coerce 'RepeatedBasicAutoscalingAlgorithm',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::AutoscalingPolicies::BasicAutoscalingAlgorithm'->new($_) } @$_ ] };

declare 'MapStringBasicAutoscalingAlgorithm',
    as HashRef[BasicAutoscalingAlgorithm()];

declare 'BasicYarnAutoscalingConfig',
    as InstanceOf['Google::Cloud::Dataproc::V1::AutoscalingPolicies::BasicYarnAutoscalingConfig'];

coerce 'BasicYarnAutoscalingConfig',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::AutoscalingPolicies::BasicYarnAutoscalingConfig'->new($_) };

declare 'RepeatedBasicYarnAutoscalingConfig',
    as ArrayRef[BasicYarnAutoscalingConfig()];

coerce 'RepeatedBasicYarnAutoscalingConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::AutoscalingPolicies::BasicYarnAutoscalingConfig'->new($_) } @$_ ] };

declare 'MapStringBasicYarnAutoscalingConfig',
    as HashRef[BasicYarnAutoscalingConfig()];

declare 'InstanceGroupAutoscalingPolicyConfig',
    as InstanceOf['Google::Cloud::Dataproc::V1::AutoscalingPolicies::InstanceGroupAutoscalingPolicyConfig'];

coerce 'InstanceGroupAutoscalingPolicyConfig',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::AutoscalingPolicies::InstanceGroupAutoscalingPolicyConfig'->new($_) };

declare 'RepeatedInstanceGroupAutoscalingPolicyConfig',
    as ArrayRef[InstanceGroupAutoscalingPolicyConfig()];

coerce 'RepeatedInstanceGroupAutoscalingPolicyConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::AutoscalingPolicies::InstanceGroupAutoscalingPolicyConfig'->new($_) } @$_ ] };

declare 'MapStringInstanceGroupAutoscalingPolicyConfig',
    as HashRef[InstanceGroupAutoscalingPolicyConfig()];

declare 'CreateAutoscalingPolicyRequest',
    as InstanceOf['Google::Cloud::Dataproc::V1::AutoscalingPolicies::CreateAutoscalingPolicyRequest'];

coerce 'CreateAutoscalingPolicyRequest',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::AutoscalingPolicies::CreateAutoscalingPolicyRequest'->new($_) };

declare 'RepeatedCreateAutoscalingPolicyRequest',
    as ArrayRef[CreateAutoscalingPolicyRequest()];

coerce 'RepeatedCreateAutoscalingPolicyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::AutoscalingPolicies::CreateAutoscalingPolicyRequest'->new($_) } @$_ ] };

declare 'MapStringCreateAutoscalingPolicyRequest',
    as HashRef[CreateAutoscalingPolicyRequest()];

declare 'GetAutoscalingPolicyRequest',
    as InstanceOf['Google::Cloud::Dataproc::V1::AutoscalingPolicies::GetAutoscalingPolicyRequest'];

coerce 'GetAutoscalingPolicyRequest',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::AutoscalingPolicies::GetAutoscalingPolicyRequest'->new($_) };

declare 'RepeatedGetAutoscalingPolicyRequest',
    as ArrayRef[GetAutoscalingPolicyRequest()];

coerce 'RepeatedGetAutoscalingPolicyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::AutoscalingPolicies::GetAutoscalingPolicyRequest'->new($_) } @$_ ] };

declare 'MapStringGetAutoscalingPolicyRequest',
    as HashRef[GetAutoscalingPolicyRequest()];

declare 'UpdateAutoscalingPolicyRequest',
    as InstanceOf['Google::Cloud::Dataproc::V1::AutoscalingPolicies::UpdateAutoscalingPolicyRequest'];

coerce 'UpdateAutoscalingPolicyRequest',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::AutoscalingPolicies::UpdateAutoscalingPolicyRequest'->new($_) };

declare 'RepeatedUpdateAutoscalingPolicyRequest',
    as ArrayRef[UpdateAutoscalingPolicyRequest()];

coerce 'RepeatedUpdateAutoscalingPolicyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::AutoscalingPolicies::UpdateAutoscalingPolicyRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateAutoscalingPolicyRequest',
    as HashRef[UpdateAutoscalingPolicyRequest()];

declare 'DeleteAutoscalingPolicyRequest',
    as InstanceOf['Google::Cloud::Dataproc::V1::AutoscalingPolicies::DeleteAutoscalingPolicyRequest'];

coerce 'DeleteAutoscalingPolicyRequest',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::AutoscalingPolicies::DeleteAutoscalingPolicyRequest'->new($_) };

declare 'RepeatedDeleteAutoscalingPolicyRequest',
    as ArrayRef[DeleteAutoscalingPolicyRequest()];

coerce 'RepeatedDeleteAutoscalingPolicyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::AutoscalingPolicies::DeleteAutoscalingPolicyRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteAutoscalingPolicyRequest',
    as HashRef[DeleteAutoscalingPolicyRequest()];

declare 'ListAutoscalingPoliciesRequest',
    as InstanceOf['Google::Cloud::Dataproc::V1::AutoscalingPolicies::ListAutoscalingPoliciesRequest'];

coerce 'ListAutoscalingPoliciesRequest',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::AutoscalingPolicies::ListAutoscalingPoliciesRequest'->new($_) };

declare 'RepeatedListAutoscalingPoliciesRequest',
    as ArrayRef[ListAutoscalingPoliciesRequest()];

coerce 'RepeatedListAutoscalingPoliciesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::AutoscalingPolicies::ListAutoscalingPoliciesRequest'->new($_) } @$_ ] };

declare 'MapStringListAutoscalingPoliciesRequest',
    as HashRef[ListAutoscalingPoliciesRequest()];

declare 'ListAutoscalingPoliciesResponse',
    as InstanceOf['Google::Cloud::Dataproc::V1::AutoscalingPolicies::ListAutoscalingPoliciesResponse'];

coerce 'ListAutoscalingPoliciesResponse',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::AutoscalingPolicies::ListAutoscalingPoliciesResponse'->new($_) };

declare 'RepeatedListAutoscalingPoliciesResponse',
    as ArrayRef[ListAutoscalingPoliciesResponse()];

coerce 'RepeatedListAutoscalingPoliciesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::AutoscalingPolicies::ListAutoscalingPoliciesResponse'->new($_) } @$_ ] };

declare 'MapStringListAutoscalingPoliciesResponse',
    as HashRef[ListAutoscalingPoliciesResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Dataproc::V1::AutoscalingPolicies::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
