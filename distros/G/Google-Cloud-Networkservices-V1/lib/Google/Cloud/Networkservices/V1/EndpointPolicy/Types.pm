package Google::Cloud::Networkservices::V1::EndpointPolicy::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'EndpointPolicy',
    as InstanceOf['Google::Cloud::Networkservices::V1::EndpointPolicy::EndpointPolicy'];

coerce 'EndpointPolicy',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::EndpointPolicy::EndpointPolicy'->new($_) };

declare 'RepeatedEndpointPolicy',
    as ArrayRef[EndpointPolicy()];

coerce 'RepeatedEndpointPolicy',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::EndpointPolicy::EndpointPolicy'->new($_) } @$_ ] };

declare 'MapStringEndpointPolicy',
    as HashRef[EndpointPolicy()];

declare 'EndpointPolicyType',
    as (Int | Str);

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Networkservices::V1::EndpointPolicy::EndpointPolicy::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::EndpointPolicy::EndpointPolicy::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::EndpointPolicy::EndpointPolicy::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'ListEndpointPoliciesRequest',
    as InstanceOf['Google::Cloud::Networkservices::V1::EndpointPolicy::ListEndpointPoliciesRequest'];

coerce 'ListEndpointPoliciesRequest',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::EndpointPolicy::ListEndpointPoliciesRequest'->new($_) };

declare 'RepeatedListEndpointPoliciesRequest',
    as ArrayRef[ListEndpointPoliciesRequest()];

coerce 'RepeatedListEndpointPoliciesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::EndpointPolicy::ListEndpointPoliciesRequest'->new($_) } @$_ ] };

declare 'MapStringListEndpointPoliciesRequest',
    as HashRef[ListEndpointPoliciesRequest()];

declare 'ListEndpointPoliciesResponse',
    as InstanceOf['Google::Cloud::Networkservices::V1::EndpointPolicy::ListEndpointPoliciesResponse'];

coerce 'ListEndpointPoliciesResponse',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::EndpointPolicy::ListEndpointPoliciesResponse'->new($_) };

declare 'RepeatedListEndpointPoliciesResponse',
    as ArrayRef[ListEndpointPoliciesResponse()];

coerce 'RepeatedListEndpointPoliciesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::EndpointPolicy::ListEndpointPoliciesResponse'->new($_) } @$_ ] };

declare 'MapStringListEndpointPoliciesResponse',
    as HashRef[ListEndpointPoliciesResponse()];

declare 'GetEndpointPolicyRequest',
    as InstanceOf['Google::Cloud::Networkservices::V1::EndpointPolicy::GetEndpointPolicyRequest'];

coerce 'GetEndpointPolicyRequest',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::EndpointPolicy::GetEndpointPolicyRequest'->new($_) };

declare 'RepeatedGetEndpointPolicyRequest',
    as ArrayRef[GetEndpointPolicyRequest()];

coerce 'RepeatedGetEndpointPolicyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::EndpointPolicy::GetEndpointPolicyRequest'->new($_) } @$_ ] };

declare 'MapStringGetEndpointPolicyRequest',
    as HashRef[GetEndpointPolicyRequest()];

declare 'CreateEndpointPolicyRequest',
    as InstanceOf['Google::Cloud::Networkservices::V1::EndpointPolicy::CreateEndpointPolicyRequest'];

coerce 'CreateEndpointPolicyRequest',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::EndpointPolicy::CreateEndpointPolicyRequest'->new($_) };

declare 'RepeatedCreateEndpointPolicyRequest',
    as ArrayRef[CreateEndpointPolicyRequest()];

coerce 'RepeatedCreateEndpointPolicyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::EndpointPolicy::CreateEndpointPolicyRequest'->new($_) } @$_ ] };

declare 'MapStringCreateEndpointPolicyRequest',
    as HashRef[CreateEndpointPolicyRequest()];

declare 'UpdateEndpointPolicyRequest',
    as InstanceOf['Google::Cloud::Networkservices::V1::EndpointPolicy::UpdateEndpointPolicyRequest'];

coerce 'UpdateEndpointPolicyRequest',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::EndpointPolicy::UpdateEndpointPolicyRequest'->new($_) };

declare 'RepeatedUpdateEndpointPolicyRequest',
    as ArrayRef[UpdateEndpointPolicyRequest()];

coerce 'RepeatedUpdateEndpointPolicyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::EndpointPolicy::UpdateEndpointPolicyRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateEndpointPolicyRequest',
    as HashRef[UpdateEndpointPolicyRequest()];

declare 'DeleteEndpointPolicyRequest',
    as InstanceOf['Google::Cloud::Networkservices::V1::EndpointPolicy::DeleteEndpointPolicyRequest'];

coerce 'DeleteEndpointPolicyRequest',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::EndpointPolicy::DeleteEndpointPolicyRequest'->new($_) };

declare 'RepeatedDeleteEndpointPolicyRequest',
    as ArrayRef[DeleteEndpointPolicyRequest()];

coerce 'RepeatedDeleteEndpointPolicyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::EndpointPolicy::DeleteEndpointPolicyRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteEndpointPolicyRequest',
    as HashRef[DeleteEndpointPolicyRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Networkservices::V1::EndpointPolicy::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
