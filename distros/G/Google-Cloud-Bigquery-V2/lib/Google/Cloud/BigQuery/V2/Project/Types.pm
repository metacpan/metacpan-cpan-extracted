package Google::Cloud::BigQuery::V2::Project::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'GetServiceAccountRequest',
    as InstanceOf['Google::Cloud::BigQuery::V2::Project::GetServiceAccountRequest'];

coerce 'GetServiceAccountRequest',
    from HashRef, via { 'Google::Cloud::BigQuery::V2::Project::GetServiceAccountRequest'->new($_) };

declare 'RepeatedGetServiceAccountRequest',
    as ArrayRef[GetServiceAccountRequest()];

coerce 'RepeatedGetServiceAccountRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::BigQuery::V2::Project::GetServiceAccountRequest'->new($_) } @$_ ] };

declare 'MapStringGetServiceAccountRequest',
    as HashRef[GetServiceAccountRequest()];

declare 'GetServiceAccountResponse',
    as InstanceOf['Google::Cloud::BigQuery::V2::Project::GetServiceAccountResponse'];

coerce 'GetServiceAccountResponse',
    from HashRef, via { 'Google::Cloud::BigQuery::V2::Project::GetServiceAccountResponse'->new($_) };

declare 'RepeatedGetServiceAccountResponse',
    as ArrayRef[GetServiceAccountResponse()];

coerce 'RepeatedGetServiceAccountResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::BigQuery::V2::Project::GetServiceAccountResponse'->new($_) } @$_ ] };

declare 'MapStringGetServiceAccountResponse',
    as HashRef[GetServiceAccountResponse()];

1;
