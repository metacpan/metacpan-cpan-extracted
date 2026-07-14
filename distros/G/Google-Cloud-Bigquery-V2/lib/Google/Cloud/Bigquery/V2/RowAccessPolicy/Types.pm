package Google::Cloud::Bigquery::V2::RowAccessPolicy::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ListRowAccessPoliciesRequest',
    as InstanceOf['Google::Cloud::Bigquery::V2::RowAccessPolicy::ListRowAccessPoliciesRequest'];

coerce 'ListRowAccessPoliciesRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::RowAccessPolicy::ListRowAccessPoliciesRequest'->new($_) };

declare 'RepeatedListRowAccessPoliciesRequest',
    as ArrayRef[ListRowAccessPoliciesRequest()];

coerce 'RepeatedListRowAccessPoliciesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::RowAccessPolicy::ListRowAccessPoliciesRequest'->new($_) } @$_ ] };

declare 'MapStringListRowAccessPoliciesRequest',
    as HashRef[ListRowAccessPoliciesRequest()];

declare 'ListRowAccessPoliciesResponse',
    as InstanceOf['Google::Cloud::Bigquery::V2::RowAccessPolicy::ListRowAccessPoliciesResponse'];

coerce 'ListRowAccessPoliciesResponse',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::RowAccessPolicy::ListRowAccessPoliciesResponse'->new($_) };

declare 'RepeatedListRowAccessPoliciesResponse',
    as ArrayRef[ListRowAccessPoliciesResponse()];

coerce 'RepeatedListRowAccessPoliciesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::RowAccessPolicy::ListRowAccessPoliciesResponse'->new($_) } @$_ ] };

declare 'MapStringListRowAccessPoliciesResponse',
    as HashRef[ListRowAccessPoliciesResponse()];

declare 'GetRowAccessPolicyRequest',
    as InstanceOf['Google::Cloud::Bigquery::V2::RowAccessPolicy::GetRowAccessPolicyRequest'];

coerce 'GetRowAccessPolicyRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::RowAccessPolicy::GetRowAccessPolicyRequest'->new($_) };

declare 'RepeatedGetRowAccessPolicyRequest',
    as ArrayRef[GetRowAccessPolicyRequest()];

coerce 'RepeatedGetRowAccessPolicyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::RowAccessPolicy::GetRowAccessPolicyRequest'->new($_) } @$_ ] };

declare 'MapStringGetRowAccessPolicyRequest',
    as HashRef[GetRowAccessPolicyRequest()];

declare 'CreateRowAccessPolicyRequest',
    as InstanceOf['Google::Cloud::Bigquery::V2::RowAccessPolicy::CreateRowAccessPolicyRequest'];

coerce 'CreateRowAccessPolicyRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::RowAccessPolicy::CreateRowAccessPolicyRequest'->new($_) };

declare 'RepeatedCreateRowAccessPolicyRequest',
    as ArrayRef[CreateRowAccessPolicyRequest()];

coerce 'RepeatedCreateRowAccessPolicyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::RowAccessPolicy::CreateRowAccessPolicyRequest'->new($_) } @$_ ] };

declare 'MapStringCreateRowAccessPolicyRequest',
    as HashRef[CreateRowAccessPolicyRequest()];

declare 'UpdateRowAccessPolicyRequest',
    as InstanceOf['Google::Cloud::Bigquery::V2::RowAccessPolicy::UpdateRowAccessPolicyRequest'];

coerce 'UpdateRowAccessPolicyRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::RowAccessPolicy::UpdateRowAccessPolicyRequest'->new($_) };

declare 'RepeatedUpdateRowAccessPolicyRequest',
    as ArrayRef[UpdateRowAccessPolicyRequest()];

coerce 'RepeatedUpdateRowAccessPolicyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::RowAccessPolicy::UpdateRowAccessPolicyRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateRowAccessPolicyRequest',
    as HashRef[UpdateRowAccessPolicyRequest()];

declare 'DeleteRowAccessPolicyRequest',
    as InstanceOf['Google::Cloud::Bigquery::V2::RowAccessPolicy::DeleteRowAccessPolicyRequest'];

coerce 'DeleteRowAccessPolicyRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::RowAccessPolicy::DeleteRowAccessPolicyRequest'->new($_) };

declare 'RepeatedDeleteRowAccessPolicyRequest',
    as ArrayRef[DeleteRowAccessPolicyRequest()];

coerce 'RepeatedDeleteRowAccessPolicyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::RowAccessPolicy::DeleteRowAccessPolicyRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteRowAccessPolicyRequest',
    as HashRef[DeleteRowAccessPolicyRequest()];

declare 'BatchDeleteRowAccessPoliciesRequest',
    as InstanceOf['Google::Cloud::Bigquery::V2::RowAccessPolicy::BatchDeleteRowAccessPoliciesRequest'];

coerce 'BatchDeleteRowAccessPoliciesRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::RowAccessPolicy::BatchDeleteRowAccessPoliciesRequest'->new($_) };

declare 'RepeatedBatchDeleteRowAccessPoliciesRequest',
    as ArrayRef[BatchDeleteRowAccessPoliciesRequest()];

coerce 'RepeatedBatchDeleteRowAccessPoliciesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::RowAccessPolicy::BatchDeleteRowAccessPoliciesRequest'->new($_) } @$_ ] };

declare 'MapStringBatchDeleteRowAccessPoliciesRequest',
    as HashRef[BatchDeleteRowAccessPoliciesRequest()];

declare 'RowAccessPolicy',
    as InstanceOf['Google::Cloud::Bigquery::V2::RowAccessPolicy::RowAccessPolicy'];

coerce 'RowAccessPolicy',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::RowAccessPolicy::RowAccessPolicy'->new($_) };

declare 'RepeatedRowAccessPolicy',
    as ArrayRef[RowAccessPolicy()];

coerce 'RepeatedRowAccessPolicy',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::RowAccessPolicy::RowAccessPolicy'->new($_) } @$_ ] };

declare 'MapStringRowAccessPolicy',
    as HashRef[RowAccessPolicy()];

1;
