package Google::Cloud::Bigquery::V2::Project::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ProjectReference',
    as InstanceOf['Google::Cloud::Bigquery::V2::Project::ProjectReference'];

coerce 'ProjectReference',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::Project::ProjectReference'->new($_) };

declare 'RepeatedProjectReference',
    as ArrayRef[ProjectReference()];

coerce 'RepeatedProjectReference',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::Project::ProjectReference'->new($_) } @$_ ] };

declare 'MapStringProjectReference',
    as HashRef[ProjectReference()];

declare 'Project',
    as InstanceOf['Google::Cloud::Bigquery::V2::Project::Project'];

coerce 'Project',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::Project::Project'->new($_) };

declare 'RepeatedProject',
    as ArrayRef[Project()];

coerce 'RepeatedProject',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::Project::Project'->new($_) } @$_ ] };

declare 'MapStringProject',
    as HashRef[Project()];

declare 'ListProjectsRequest',
    as InstanceOf['Google::Cloud::Bigquery::V2::Project::ListProjectsRequest'];

coerce 'ListProjectsRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::Project::ListProjectsRequest'->new($_) };

declare 'RepeatedListProjectsRequest',
    as ArrayRef[ListProjectsRequest()];

coerce 'RepeatedListProjectsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::Project::ListProjectsRequest'->new($_) } @$_ ] };

declare 'MapStringListProjectsRequest',
    as HashRef[ListProjectsRequest()];

declare 'ProjectList',
    as InstanceOf['Google::Cloud::Bigquery::V2::Project::ProjectList'];

coerce 'ProjectList',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::Project::ProjectList'->new($_) };

declare 'RepeatedProjectList',
    as ArrayRef[ProjectList()];

coerce 'RepeatedProjectList',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::Project::ProjectList'->new($_) } @$_ ] };

declare 'MapStringProjectList',
    as HashRef[ProjectList()];

declare 'GetServiceAccountRequest',
    as InstanceOf['Google::Cloud::Bigquery::V2::Project::GetServiceAccountRequest'];

coerce 'GetServiceAccountRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::Project::GetServiceAccountRequest'->new($_) };

declare 'RepeatedGetServiceAccountRequest',
    as ArrayRef[GetServiceAccountRequest()];

coerce 'RepeatedGetServiceAccountRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::Project::GetServiceAccountRequest'->new($_) } @$_ ] };

declare 'MapStringGetServiceAccountRequest',
    as HashRef[GetServiceAccountRequest()];

declare 'GetServiceAccountResponse',
    as InstanceOf['Google::Cloud::Bigquery::V2::Project::GetServiceAccountResponse'];

coerce 'GetServiceAccountResponse',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::Project::GetServiceAccountResponse'->new($_) };

declare 'RepeatedGetServiceAccountResponse',
    as ArrayRef[GetServiceAccountResponse()];

coerce 'RepeatedGetServiceAccountResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::Project::GetServiceAccountResponse'->new($_) } @$_ ] };

declare 'MapStringGetServiceAccountResponse',
    as HashRef[GetServiceAccountResponse()];

1;
