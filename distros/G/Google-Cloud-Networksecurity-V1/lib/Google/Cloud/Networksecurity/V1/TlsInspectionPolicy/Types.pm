package Google::Cloud::Networksecurity::V1::TlsInspectionPolicy::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'TlsInspectionPolicy',
    as InstanceOf['Google::Cloud::Networksecurity::V1::TlsInspectionPolicy::TlsInspectionPolicy'];

coerce 'TlsInspectionPolicy',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::TlsInspectionPolicy::TlsInspectionPolicy'->new($_) };

declare 'RepeatedTlsInspectionPolicy',
    as ArrayRef[TlsInspectionPolicy()];

coerce 'RepeatedTlsInspectionPolicy',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::TlsInspectionPolicy::TlsInspectionPolicy'->new($_) } @$_ ] };

declare 'MapStringTlsInspectionPolicy',
    as HashRef[TlsInspectionPolicy()];

declare 'TlsVersion',
    as (Int | Str);

declare 'Profile',
    as (Int | Str);

declare 'CreateTlsInspectionPolicyRequest',
    as InstanceOf['Google::Cloud::Networksecurity::V1::TlsInspectionPolicy::CreateTlsInspectionPolicyRequest'];

coerce 'CreateTlsInspectionPolicyRequest',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::TlsInspectionPolicy::CreateTlsInspectionPolicyRequest'->new($_) };

declare 'RepeatedCreateTlsInspectionPolicyRequest',
    as ArrayRef[CreateTlsInspectionPolicyRequest()];

coerce 'RepeatedCreateTlsInspectionPolicyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::TlsInspectionPolicy::CreateTlsInspectionPolicyRequest'->new($_) } @$_ ] };

declare 'MapStringCreateTlsInspectionPolicyRequest',
    as HashRef[CreateTlsInspectionPolicyRequest()];

declare 'ListTlsInspectionPoliciesRequest',
    as InstanceOf['Google::Cloud::Networksecurity::V1::TlsInspectionPolicy::ListTlsInspectionPoliciesRequest'];

coerce 'ListTlsInspectionPoliciesRequest',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::TlsInspectionPolicy::ListTlsInspectionPoliciesRequest'->new($_) };

declare 'RepeatedListTlsInspectionPoliciesRequest',
    as ArrayRef[ListTlsInspectionPoliciesRequest()];

coerce 'RepeatedListTlsInspectionPoliciesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::TlsInspectionPolicy::ListTlsInspectionPoliciesRequest'->new($_) } @$_ ] };

declare 'MapStringListTlsInspectionPoliciesRequest',
    as HashRef[ListTlsInspectionPoliciesRequest()];

declare 'ListTlsInspectionPoliciesResponse',
    as InstanceOf['Google::Cloud::Networksecurity::V1::TlsInspectionPolicy::ListTlsInspectionPoliciesResponse'];

coerce 'ListTlsInspectionPoliciesResponse',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::TlsInspectionPolicy::ListTlsInspectionPoliciesResponse'->new($_) };

declare 'RepeatedListTlsInspectionPoliciesResponse',
    as ArrayRef[ListTlsInspectionPoliciesResponse()];

coerce 'RepeatedListTlsInspectionPoliciesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::TlsInspectionPolicy::ListTlsInspectionPoliciesResponse'->new($_) } @$_ ] };

declare 'MapStringListTlsInspectionPoliciesResponse',
    as HashRef[ListTlsInspectionPoliciesResponse()];

declare 'GetTlsInspectionPolicyRequest',
    as InstanceOf['Google::Cloud::Networksecurity::V1::TlsInspectionPolicy::GetTlsInspectionPolicyRequest'];

coerce 'GetTlsInspectionPolicyRequest',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::TlsInspectionPolicy::GetTlsInspectionPolicyRequest'->new($_) };

declare 'RepeatedGetTlsInspectionPolicyRequest',
    as ArrayRef[GetTlsInspectionPolicyRequest()];

coerce 'RepeatedGetTlsInspectionPolicyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::TlsInspectionPolicy::GetTlsInspectionPolicyRequest'->new($_) } @$_ ] };

declare 'MapStringGetTlsInspectionPolicyRequest',
    as HashRef[GetTlsInspectionPolicyRequest()];

declare 'DeleteTlsInspectionPolicyRequest',
    as InstanceOf['Google::Cloud::Networksecurity::V1::TlsInspectionPolicy::DeleteTlsInspectionPolicyRequest'];

coerce 'DeleteTlsInspectionPolicyRequest',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::TlsInspectionPolicy::DeleteTlsInspectionPolicyRequest'->new($_) };

declare 'RepeatedDeleteTlsInspectionPolicyRequest',
    as ArrayRef[DeleteTlsInspectionPolicyRequest()];

coerce 'RepeatedDeleteTlsInspectionPolicyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::TlsInspectionPolicy::DeleteTlsInspectionPolicyRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteTlsInspectionPolicyRequest',
    as HashRef[DeleteTlsInspectionPolicyRequest()];

declare 'UpdateTlsInspectionPolicyRequest',
    as InstanceOf['Google::Cloud::Networksecurity::V1::TlsInspectionPolicy::UpdateTlsInspectionPolicyRequest'];

coerce 'UpdateTlsInspectionPolicyRequest',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::TlsInspectionPolicy::UpdateTlsInspectionPolicyRequest'->new($_) };

declare 'RepeatedUpdateTlsInspectionPolicyRequest',
    as ArrayRef[UpdateTlsInspectionPolicyRequest()];

coerce 'RepeatedUpdateTlsInspectionPolicyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::TlsInspectionPolicy::UpdateTlsInspectionPolicyRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateTlsInspectionPolicyRequest',
    as HashRef[UpdateTlsInspectionPolicyRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Networksecurity::V1::TlsInspectionPolicy::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
