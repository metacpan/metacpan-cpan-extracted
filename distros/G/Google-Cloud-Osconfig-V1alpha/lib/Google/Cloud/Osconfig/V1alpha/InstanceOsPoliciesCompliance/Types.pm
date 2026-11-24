package Google::Cloud::Osconfig::V1alpha::InstanceOsPoliciesCompliance::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'InstanceOSPoliciesCompliance',
    as InstanceOf['Google::Cloud::Osconfig::V1alpha::InstanceOsPoliciesCompliance::InstanceOSPoliciesCompliance'];

coerce 'InstanceOSPoliciesCompliance',
    from HashRef, via { 'Google::Cloud::Osconfig::V1alpha::InstanceOsPoliciesCompliance::InstanceOSPoliciesCompliance'->new($_) };

declare 'RepeatedInstanceOSPoliciesCompliance',
    as ArrayRef[InstanceOSPoliciesCompliance()];

coerce 'RepeatedInstanceOSPoliciesCompliance',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::V1alpha::InstanceOsPoliciesCompliance::InstanceOSPoliciesCompliance'->new($_) } @$_ ] };

declare 'MapStringInstanceOSPoliciesCompliance',
    as HashRef[InstanceOSPoliciesCompliance()];

declare 'OSPolicyCompliance',
    as InstanceOf['Google::Cloud::Osconfig::V1alpha::InstanceOsPoliciesCompliance::InstanceOSPoliciesCompliance::OSPolicyCompliance'];

coerce 'OSPolicyCompliance',
    from HashRef, via { 'Google::Cloud::Osconfig::V1alpha::InstanceOsPoliciesCompliance::InstanceOSPoliciesCompliance::OSPolicyCompliance'->new($_) };

declare 'RepeatedOSPolicyCompliance',
    as ArrayRef[OSPolicyCompliance()];

coerce 'RepeatedOSPolicyCompliance',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::V1alpha::InstanceOsPoliciesCompliance::InstanceOSPoliciesCompliance::OSPolicyCompliance'->new($_) } @$_ ] };

declare 'MapStringOSPolicyCompliance',
    as HashRef[OSPolicyCompliance()];

declare 'GetInstanceOSPoliciesComplianceRequest',
    as InstanceOf['Google::Cloud::Osconfig::V1alpha::InstanceOsPoliciesCompliance::GetInstanceOSPoliciesComplianceRequest'];

coerce 'GetInstanceOSPoliciesComplianceRequest',
    from HashRef, via { 'Google::Cloud::Osconfig::V1alpha::InstanceOsPoliciesCompliance::GetInstanceOSPoliciesComplianceRequest'->new($_) };

declare 'RepeatedGetInstanceOSPoliciesComplianceRequest',
    as ArrayRef[GetInstanceOSPoliciesComplianceRequest()];

coerce 'RepeatedGetInstanceOSPoliciesComplianceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::V1alpha::InstanceOsPoliciesCompliance::GetInstanceOSPoliciesComplianceRequest'->new($_) } @$_ ] };

declare 'MapStringGetInstanceOSPoliciesComplianceRequest',
    as HashRef[GetInstanceOSPoliciesComplianceRequest()];

declare 'ListInstanceOSPoliciesCompliancesRequest',
    as InstanceOf['Google::Cloud::Osconfig::V1alpha::InstanceOsPoliciesCompliance::ListInstanceOSPoliciesCompliancesRequest'];

coerce 'ListInstanceOSPoliciesCompliancesRequest',
    from HashRef, via { 'Google::Cloud::Osconfig::V1alpha::InstanceOsPoliciesCompliance::ListInstanceOSPoliciesCompliancesRequest'->new($_) };

declare 'RepeatedListInstanceOSPoliciesCompliancesRequest',
    as ArrayRef[ListInstanceOSPoliciesCompliancesRequest()];

coerce 'RepeatedListInstanceOSPoliciesCompliancesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::V1alpha::InstanceOsPoliciesCompliance::ListInstanceOSPoliciesCompliancesRequest'->new($_) } @$_ ] };

declare 'MapStringListInstanceOSPoliciesCompliancesRequest',
    as HashRef[ListInstanceOSPoliciesCompliancesRequest()];

declare 'ListInstanceOSPoliciesCompliancesResponse',
    as InstanceOf['Google::Cloud::Osconfig::V1alpha::InstanceOsPoliciesCompliance::ListInstanceOSPoliciesCompliancesResponse'];

coerce 'ListInstanceOSPoliciesCompliancesResponse',
    from HashRef, via { 'Google::Cloud::Osconfig::V1alpha::InstanceOsPoliciesCompliance::ListInstanceOSPoliciesCompliancesResponse'->new($_) };

declare 'RepeatedListInstanceOSPoliciesCompliancesResponse',
    as ArrayRef[ListInstanceOSPoliciesCompliancesResponse()];

coerce 'RepeatedListInstanceOSPoliciesCompliancesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::V1alpha::InstanceOsPoliciesCompliance::ListInstanceOSPoliciesCompliancesResponse'->new($_) } @$_ ] };

declare 'MapStringListInstanceOSPoliciesCompliancesResponse',
    as HashRef[ListInstanceOSPoliciesCompliancesResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Osconfig::V1alpha::InstanceOsPoliciesCompliance::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
