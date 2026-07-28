package Google::Cloud::Networkservices::V1::ServiceLbPolicy::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ServiceLbPolicy',
    as InstanceOf['Google::Cloud::Networkservices::V1::ServiceLbPolicy::ServiceLbPolicy'];

coerce 'ServiceLbPolicy',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::ServiceLbPolicy::ServiceLbPolicy'->new($_) };

declare 'RepeatedServiceLbPolicy',
    as ArrayRef[ServiceLbPolicy()];

coerce 'RepeatedServiceLbPolicy',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::ServiceLbPolicy::ServiceLbPolicy'->new($_) } @$_ ] };

declare 'MapStringServiceLbPolicy',
    as HashRef[ServiceLbPolicy()];

declare 'LoadBalancingAlgorithm',
    as (Int | Str);

declare 'IsolationGranularity',
    as (Int | Str);

declare 'IsolationMode',
    as (Int | Str);

declare 'AutoCapacityDrain',
    as InstanceOf['Google::Cloud::Networkservices::V1::ServiceLbPolicy::ServiceLbPolicy::AutoCapacityDrain'];

coerce 'AutoCapacityDrain',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::ServiceLbPolicy::ServiceLbPolicy::AutoCapacityDrain'->new($_) };

declare 'RepeatedAutoCapacityDrain',
    as ArrayRef[AutoCapacityDrain()];

coerce 'RepeatedAutoCapacityDrain',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::ServiceLbPolicy::ServiceLbPolicy::AutoCapacityDrain'->new($_) } @$_ ] };

declare 'MapStringAutoCapacityDrain',
    as HashRef[AutoCapacityDrain()];

declare 'FailoverConfig',
    as InstanceOf['Google::Cloud::Networkservices::V1::ServiceLbPolicy::ServiceLbPolicy::FailoverConfig'];

coerce 'FailoverConfig',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::ServiceLbPolicy::ServiceLbPolicy::FailoverConfig'->new($_) };

declare 'RepeatedFailoverConfig',
    as ArrayRef[FailoverConfig()];

coerce 'RepeatedFailoverConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::ServiceLbPolicy::ServiceLbPolicy::FailoverConfig'->new($_) } @$_ ] };

declare 'MapStringFailoverConfig',
    as HashRef[FailoverConfig()];

declare 'IsolationConfig',
    as InstanceOf['Google::Cloud::Networkservices::V1::ServiceLbPolicy::ServiceLbPolicy::IsolationConfig'];

coerce 'IsolationConfig',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::ServiceLbPolicy::ServiceLbPolicy::IsolationConfig'->new($_) };

declare 'RepeatedIsolationConfig',
    as ArrayRef[IsolationConfig()];

coerce 'RepeatedIsolationConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::ServiceLbPolicy::ServiceLbPolicy::IsolationConfig'->new($_) } @$_ ] };

declare 'MapStringIsolationConfig',
    as HashRef[IsolationConfig()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Networkservices::V1::ServiceLbPolicy::ServiceLbPolicy::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::ServiceLbPolicy::ServiceLbPolicy::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::ServiceLbPolicy::ServiceLbPolicy::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'ListServiceLbPoliciesRequest',
    as InstanceOf['Google::Cloud::Networkservices::V1::ServiceLbPolicy::ListServiceLbPoliciesRequest'];

coerce 'ListServiceLbPoliciesRequest',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::ServiceLbPolicy::ListServiceLbPoliciesRequest'->new($_) };

declare 'RepeatedListServiceLbPoliciesRequest',
    as ArrayRef[ListServiceLbPoliciesRequest()];

coerce 'RepeatedListServiceLbPoliciesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::ServiceLbPolicy::ListServiceLbPoliciesRequest'->new($_) } @$_ ] };

declare 'MapStringListServiceLbPoliciesRequest',
    as HashRef[ListServiceLbPoliciesRequest()];

declare 'ListServiceLbPoliciesResponse',
    as InstanceOf['Google::Cloud::Networkservices::V1::ServiceLbPolicy::ListServiceLbPoliciesResponse'];

coerce 'ListServiceLbPoliciesResponse',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::ServiceLbPolicy::ListServiceLbPoliciesResponse'->new($_) };

declare 'RepeatedListServiceLbPoliciesResponse',
    as ArrayRef[ListServiceLbPoliciesResponse()];

coerce 'RepeatedListServiceLbPoliciesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::ServiceLbPolicy::ListServiceLbPoliciesResponse'->new($_) } @$_ ] };

declare 'MapStringListServiceLbPoliciesResponse',
    as HashRef[ListServiceLbPoliciesResponse()];

declare 'GetServiceLbPolicyRequest',
    as InstanceOf['Google::Cloud::Networkservices::V1::ServiceLbPolicy::GetServiceLbPolicyRequest'];

coerce 'GetServiceLbPolicyRequest',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::ServiceLbPolicy::GetServiceLbPolicyRequest'->new($_) };

declare 'RepeatedGetServiceLbPolicyRequest',
    as ArrayRef[GetServiceLbPolicyRequest()];

coerce 'RepeatedGetServiceLbPolicyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::ServiceLbPolicy::GetServiceLbPolicyRequest'->new($_) } @$_ ] };

declare 'MapStringGetServiceLbPolicyRequest',
    as HashRef[GetServiceLbPolicyRequest()];

declare 'CreateServiceLbPolicyRequest',
    as InstanceOf['Google::Cloud::Networkservices::V1::ServiceLbPolicy::CreateServiceLbPolicyRequest'];

coerce 'CreateServiceLbPolicyRequest',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::ServiceLbPolicy::CreateServiceLbPolicyRequest'->new($_) };

declare 'RepeatedCreateServiceLbPolicyRequest',
    as ArrayRef[CreateServiceLbPolicyRequest()];

coerce 'RepeatedCreateServiceLbPolicyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::ServiceLbPolicy::CreateServiceLbPolicyRequest'->new($_) } @$_ ] };

declare 'MapStringCreateServiceLbPolicyRequest',
    as HashRef[CreateServiceLbPolicyRequest()];

declare 'UpdateServiceLbPolicyRequest',
    as InstanceOf['Google::Cloud::Networkservices::V1::ServiceLbPolicy::UpdateServiceLbPolicyRequest'];

coerce 'UpdateServiceLbPolicyRequest',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::ServiceLbPolicy::UpdateServiceLbPolicyRequest'->new($_) };

declare 'RepeatedUpdateServiceLbPolicyRequest',
    as ArrayRef[UpdateServiceLbPolicyRequest()];

coerce 'RepeatedUpdateServiceLbPolicyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::ServiceLbPolicy::UpdateServiceLbPolicyRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateServiceLbPolicyRequest',
    as HashRef[UpdateServiceLbPolicyRequest()];

declare 'DeleteServiceLbPolicyRequest',
    as InstanceOf['Google::Cloud::Networkservices::V1::ServiceLbPolicy::DeleteServiceLbPolicyRequest'];

coerce 'DeleteServiceLbPolicyRequest',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::ServiceLbPolicy::DeleteServiceLbPolicyRequest'->new($_) };

declare 'RepeatedDeleteServiceLbPolicyRequest',
    as ArrayRef[DeleteServiceLbPolicyRequest()];

coerce 'RepeatedDeleteServiceLbPolicyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::ServiceLbPolicy::DeleteServiceLbPolicyRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteServiceLbPolicyRequest',
    as HashRef[DeleteServiceLbPolicyRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Networkservices::V1::ServiceLbPolicy::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
