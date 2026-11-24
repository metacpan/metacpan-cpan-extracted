package Google::Cloud::Bigquery::Datapolicies::V2::Datapolicy::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'CreateDataPolicyRequest',
    as InstanceOf['Google::Cloud::Bigquery::Datapolicies::V2::Datapolicy::CreateDataPolicyRequest'];

coerce 'CreateDataPolicyRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::Datapolicies::V2::Datapolicy::CreateDataPolicyRequest'->new($_) };

declare 'RepeatedCreateDataPolicyRequest',
    as ArrayRef[CreateDataPolicyRequest()];

coerce 'RepeatedCreateDataPolicyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Datapolicies::V2::Datapolicy::CreateDataPolicyRequest'->new($_) } @$_ ] };

declare 'MapStringCreateDataPolicyRequest',
    as HashRef[CreateDataPolicyRequest()];

declare 'UpdateDataPolicyRequest',
    as InstanceOf['Google::Cloud::Bigquery::Datapolicies::V2::Datapolicy::UpdateDataPolicyRequest'];

coerce 'UpdateDataPolicyRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::Datapolicies::V2::Datapolicy::UpdateDataPolicyRequest'->new($_) };

declare 'RepeatedUpdateDataPolicyRequest',
    as ArrayRef[UpdateDataPolicyRequest()];

coerce 'RepeatedUpdateDataPolicyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Datapolicies::V2::Datapolicy::UpdateDataPolicyRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateDataPolicyRequest',
    as HashRef[UpdateDataPolicyRequest()];

declare 'AddGranteesRequest',
    as InstanceOf['Google::Cloud::Bigquery::Datapolicies::V2::Datapolicy::AddGranteesRequest'];

coerce 'AddGranteesRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::Datapolicies::V2::Datapolicy::AddGranteesRequest'->new($_) };

declare 'RepeatedAddGranteesRequest',
    as ArrayRef[AddGranteesRequest()];

coerce 'RepeatedAddGranteesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Datapolicies::V2::Datapolicy::AddGranteesRequest'->new($_) } @$_ ] };

declare 'MapStringAddGranteesRequest',
    as HashRef[AddGranteesRequest()];

declare 'RemoveGranteesRequest',
    as InstanceOf['Google::Cloud::Bigquery::Datapolicies::V2::Datapolicy::RemoveGranteesRequest'];

coerce 'RemoveGranteesRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::Datapolicies::V2::Datapolicy::RemoveGranteesRequest'->new($_) };

declare 'RepeatedRemoveGranteesRequest',
    as ArrayRef[RemoveGranteesRequest()];

coerce 'RepeatedRemoveGranteesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Datapolicies::V2::Datapolicy::RemoveGranteesRequest'->new($_) } @$_ ] };

declare 'MapStringRemoveGranteesRequest',
    as HashRef[RemoveGranteesRequest()];

declare 'DeleteDataPolicyRequest',
    as InstanceOf['Google::Cloud::Bigquery::Datapolicies::V2::Datapolicy::DeleteDataPolicyRequest'];

coerce 'DeleteDataPolicyRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::Datapolicies::V2::Datapolicy::DeleteDataPolicyRequest'->new($_) };

declare 'RepeatedDeleteDataPolicyRequest',
    as ArrayRef[DeleteDataPolicyRequest()];

coerce 'RepeatedDeleteDataPolicyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Datapolicies::V2::Datapolicy::DeleteDataPolicyRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteDataPolicyRequest',
    as HashRef[DeleteDataPolicyRequest()];

declare 'GetDataPolicyRequest',
    as InstanceOf['Google::Cloud::Bigquery::Datapolicies::V2::Datapolicy::GetDataPolicyRequest'];

coerce 'GetDataPolicyRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::Datapolicies::V2::Datapolicy::GetDataPolicyRequest'->new($_) };

declare 'RepeatedGetDataPolicyRequest',
    as ArrayRef[GetDataPolicyRequest()];

coerce 'RepeatedGetDataPolicyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Datapolicies::V2::Datapolicy::GetDataPolicyRequest'->new($_) } @$_ ] };

declare 'MapStringGetDataPolicyRequest',
    as HashRef[GetDataPolicyRequest()];

declare 'ListDataPoliciesRequest',
    as InstanceOf['Google::Cloud::Bigquery::Datapolicies::V2::Datapolicy::ListDataPoliciesRequest'];

coerce 'ListDataPoliciesRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::Datapolicies::V2::Datapolicy::ListDataPoliciesRequest'->new($_) };

declare 'RepeatedListDataPoliciesRequest',
    as ArrayRef[ListDataPoliciesRequest()];

coerce 'RepeatedListDataPoliciesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Datapolicies::V2::Datapolicy::ListDataPoliciesRequest'->new($_) } @$_ ] };

declare 'MapStringListDataPoliciesRequest',
    as HashRef[ListDataPoliciesRequest()];

declare 'ListDataPoliciesResponse',
    as InstanceOf['Google::Cloud::Bigquery::Datapolicies::V2::Datapolicy::ListDataPoliciesResponse'];

coerce 'ListDataPoliciesResponse',
    from HashRef, via { 'Google::Cloud::Bigquery::Datapolicies::V2::Datapolicy::ListDataPoliciesResponse'->new($_) };

declare 'RepeatedListDataPoliciesResponse',
    as ArrayRef[ListDataPoliciesResponse()];

coerce 'RepeatedListDataPoliciesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Datapolicies::V2::Datapolicy::ListDataPoliciesResponse'->new($_) } @$_ ] };

declare 'MapStringListDataPoliciesResponse',
    as HashRef[ListDataPoliciesResponse()];

declare 'DataPolicy',
    as InstanceOf['Google::Cloud::Bigquery::Datapolicies::V2::Datapolicy::DataPolicy'];

coerce 'DataPolicy',
    from HashRef, via { 'Google::Cloud::Bigquery::Datapolicies::V2::Datapolicy::DataPolicy'->new($_) };

declare 'RepeatedDataPolicy',
    as ArrayRef[DataPolicy()];

coerce 'RepeatedDataPolicy',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Datapolicies::V2::Datapolicy::DataPolicy'->new($_) } @$_ ] };

declare 'MapStringDataPolicy',
    as HashRef[DataPolicy()];

declare 'DataPolicyType',
    as (Int | Str);

declare 'Version',
    as (Int | Str);

declare 'DataMaskingPolicy',
    as InstanceOf['Google::Cloud::Bigquery::Datapolicies::V2::Datapolicy::DataMaskingPolicy'];

coerce 'DataMaskingPolicy',
    from HashRef, via { 'Google::Cloud::Bigquery::Datapolicies::V2::Datapolicy::DataMaskingPolicy'->new($_) };

declare 'RepeatedDataMaskingPolicy',
    as ArrayRef[DataMaskingPolicy()];

coerce 'RepeatedDataMaskingPolicy',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Datapolicies::V2::Datapolicy::DataMaskingPolicy'->new($_) } @$_ ] };

declare 'MapStringDataMaskingPolicy',
    as HashRef[DataMaskingPolicy()];

declare 'PredefinedExpression',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Bigquery::Datapolicies::V2::Datapolicy::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
