package Google::Cloud::Bigquery::V2::Job::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Job',
    as InstanceOf['Google::Cloud::Bigquery::V2::Job::Job'];

coerce 'Job',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::Job::Job'->new($_) };

declare 'RepeatedJob',
    as ArrayRef[Job()];

coerce 'RepeatedJob',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::Job::Job'->new($_) } @$_ ] };

declare 'MapStringJob',
    as HashRef[Job()];

declare 'CancelJobRequest',
    as InstanceOf['Google::Cloud::Bigquery::V2::Job::CancelJobRequest'];

coerce 'CancelJobRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::Job::CancelJobRequest'->new($_) };

declare 'RepeatedCancelJobRequest',
    as ArrayRef[CancelJobRequest()];

coerce 'RepeatedCancelJobRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::Job::CancelJobRequest'->new($_) } @$_ ] };

declare 'MapStringCancelJobRequest',
    as HashRef[CancelJobRequest()];

declare 'JobCancelResponse',
    as InstanceOf['Google::Cloud::Bigquery::V2::Job::JobCancelResponse'];

coerce 'JobCancelResponse',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::Job::JobCancelResponse'->new($_) };

declare 'RepeatedJobCancelResponse',
    as ArrayRef[JobCancelResponse()];

coerce 'RepeatedJobCancelResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::Job::JobCancelResponse'->new($_) } @$_ ] };

declare 'MapStringJobCancelResponse',
    as HashRef[JobCancelResponse()];

declare 'GetJobRequest',
    as InstanceOf['Google::Cloud::Bigquery::V2::Job::GetJobRequest'];

coerce 'GetJobRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::Job::GetJobRequest'->new($_) };

declare 'RepeatedGetJobRequest',
    as ArrayRef[GetJobRequest()];

coerce 'RepeatedGetJobRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::Job::GetJobRequest'->new($_) } @$_ ] };

declare 'MapStringGetJobRequest',
    as HashRef[GetJobRequest()];

declare 'InsertJobRequest',
    as InstanceOf['Google::Cloud::Bigquery::V2::Job::InsertJobRequest'];

coerce 'InsertJobRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::Job::InsertJobRequest'->new($_) };

declare 'RepeatedInsertJobRequest',
    as ArrayRef[InsertJobRequest()];

coerce 'RepeatedInsertJobRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::Job::InsertJobRequest'->new($_) } @$_ ] };

declare 'MapStringInsertJobRequest',
    as HashRef[InsertJobRequest()];

declare 'UpdateJobRequest',
    as InstanceOf['Google::Cloud::Bigquery::V2::Job::UpdateJobRequest'];

coerce 'UpdateJobRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::Job::UpdateJobRequest'->new($_) };

declare 'RepeatedUpdateJobRequest',
    as ArrayRef[UpdateJobRequest()];

coerce 'RepeatedUpdateJobRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::Job::UpdateJobRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateJobRequest',
    as HashRef[UpdateJobRequest()];

declare 'DeleteJobRequest',
    as InstanceOf['Google::Cloud::Bigquery::V2::Job::DeleteJobRequest'];

coerce 'DeleteJobRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::Job::DeleteJobRequest'->new($_) };

declare 'RepeatedDeleteJobRequest',
    as ArrayRef[DeleteJobRequest()];

coerce 'RepeatedDeleteJobRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::Job::DeleteJobRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteJobRequest',
    as HashRef[DeleteJobRequest()];

declare 'ListJobsRequest',
    as InstanceOf['Google::Cloud::Bigquery::V2::Job::ListJobsRequest'];

coerce 'ListJobsRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::Job::ListJobsRequest'->new($_) };

declare 'RepeatedListJobsRequest',
    as ArrayRef[ListJobsRequest()];

coerce 'RepeatedListJobsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::Job::ListJobsRequest'->new($_) } @$_ ] };

declare 'MapStringListJobsRequest',
    as HashRef[ListJobsRequest()];

declare 'Projection',
    as (Int | Str);

declare 'StateFilter',
    as (Int | Str);

declare 'ListFormatJob',
    as InstanceOf['Google::Cloud::Bigquery::V2::Job::ListFormatJob'];

coerce 'ListFormatJob',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::Job::ListFormatJob'->new($_) };

declare 'RepeatedListFormatJob',
    as ArrayRef[ListFormatJob()];

coerce 'RepeatedListFormatJob',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::Job::ListFormatJob'->new($_) } @$_ ] };

declare 'MapStringListFormatJob',
    as HashRef[ListFormatJob()];

declare 'JobList',
    as InstanceOf['Google::Cloud::Bigquery::V2::Job::JobList'];

coerce 'JobList',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::Job::JobList'->new($_) };

declare 'RepeatedJobList',
    as ArrayRef[JobList()];

coerce 'RepeatedJobList',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::Job::JobList'->new($_) } @$_ ] };

declare 'MapStringJobList',
    as HashRef[JobList()];

declare 'GetQueryResultsRequest',
    as InstanceOf['Google::Cloud::Bigquery::V2::Job::GetQueryResultsRequest'];

coerce 'GetQueryResultsRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::Job::GetQueryResultsRequest'->new($_) };

declare 'RepeatedGetQueryResultsRequest',
    as ArrayRef[GetQueryResultsRequest()];

coerce 'RepeatedGetQueryResultsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::Job::GetQueryResultsRequest'->new($_) } @$_ ] };

declare 'MapStringGetQueryResultsRequest',
    as HashRef[GetQueryResultsRequest()];

declare 'GetQueryResultsResponse',
    as InstanceOf['Google::Cloud::Bigquery::V2::Job::GetQueryResultsResponse'];

coerce 'GetQueryResultsResponse',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::Job::GetQueryResultsResponse'->new($_) };

declare 'RepeatedGetQueryResultsResponse',
    as ArrayRef[GetQueryResultsResponse()];

coerce 'RepeatedGetQueryResultsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::Job::GetQueryResultsResponse'->new($_) } @$_ ] };

declare 'MapStringGetQueryResultsResponse',
    as HashRef[GetQueryResultsResponse()];

declare 'PostQueryRequest',
    as InstanceOf['Google::Cloud::Bigquery::V2::Job::PostQueryRequest'];

coerce 'PostQueryRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::Job::PostQueryRequest'->new($_) };

declare 'RepeatedPostQueryRequest',
    as ArrayRef[PostQueryRequest()];

coerce 'RepeatedPostQueryRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::Job::PostQueryRequest'->new($_) } @$_ ] };

declare 'MapStringPostQueryRequest',
    as HashRef[PostQueryRequest()];

declare 'QueryRequest',
    as InstanceOf['Google::Cloud::Bigquery::V2::Job::QueryRequest'];

coerce 'QueryRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::Job::QueryRequest'->new($_) };

declare 'RepeatedQueryRequest',
    as ArrayRef[QueryRequest()];

coerce 'RepeatedQueryRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::Job::QueryRequest'->new($_) } @$_ ] };

declare 'MapStringQueryRequest',
    as HashRef[QueryRequest()];

declare 'JobCreationMode',
    as (Int | Str);

declare 'QueryResultsFormat',
    as (Int | Str);

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Bigquery::V2::Job::QueryRequest::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::Job::QueryRequest::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::Job::QueryRequest::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'QueryResponse',
    as InstanceOf['Google::Cloud::Bigquery::V2::Job::QueryResponse'];

coerce 'QueryResponse',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::Job::QueryResponse'->new($_) };

declare 'RepeatedQueryResponse',
    as ArrayRef[QueryResponse()];

coerce 'RepeatedQueryResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::Job::QueryResponse'->new($_) } @$_ ] };

declare 'MapStringQueryResponse',
    as HashRef[QueryResponse()];

1;
