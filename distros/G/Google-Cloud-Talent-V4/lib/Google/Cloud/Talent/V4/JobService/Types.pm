package Google::Cloud::Talent::V4::JobService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'JobView',
    as (Int | Str);

declare 'CreateJobRequest',
    as InstanceOf['Google::Cloud::Talent::V4::JobService::CreateJobRequest'];

coerce 'CreateJobRequest',
    from HashRef, via { 'Google::Cloud::Talent::V4::JobService::CreateJobRequest'->new($_) };

declare 'RepeatedCreateJobRequest',
    as ArrayRef[CreateJobRequest()];

coerce 'RepeatedCreateJobRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Talent::V4::JobService::CreateJobRequest'->new($_) } @$_ ] };

declare 'MapStringCreateJobRequest',
    as HashRef[CreateJobRequest()];

declare 'GetJobRequest',
    as InstanceOf['Google::Cloud::Talent::V4::JobService::GetJobRequest'];

coerce 'GetJobRequest',
    from HashRef, via { 'Google::Cloud::Talent::V4::JobService::GetJobRequest'->new($_) };

declare 'RepeatedGetJobRequest',
    as ArrayRef[GetJobRequest()];

coerce 'RepeatedGetJobRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Talent::V4::JobService::GetJobRequest'->new($_) } @$_ ] };

declare 'MapStringGetJobRequest',
    as HashRef[GetJobRequest()];

declare 'UpdateJobRequest',
    as InstanceOf['Google::Cloud::Talent::V4::JobService::UpdateJobRequest'];

coerce 'UpdateJobRequest',
    from HashRef, via { 'Google::Cloud::Talent::V4::JobService::UpdateJobRequest'->new($_) };

declare 'RepeatedUpdateJobRequest',
    as ArrayRef[UpdateJobRequest()];

coerce 'RepeatedUpdateJobRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Talent::V4::JobService::UpdateJobRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateJobRequest',
    as HashRef[UpdateJobRequest()];

declare 'DeleteJobRequest',
    as InstanceOf['Google::Cloud::Talent::V4::JobService::DeleteJobRequest'];

coerce 'DeleteJobRequest',
    from HashRef, via { 'Google::Cloud::Talent::V4::JobService::DeleteJobRequest'->new($_) };

declare 'RepeatedDeleteJobRequest',
    as ArrayRef[DeleteJobRequest()];

coerce 'RepeatedDeleteJobRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Talent::V4::JobService::DeleteJobRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteJobRequest',
    as HashRef[DeleteJobRequest()];

declare 'ListJobsRequest',
    as InstanceOf['Google::Cloud::Talent::V4::JobService::ListJobsRequest'];

coerce 'ListJobsRequest',
    from HashRef, via { 'Google::Cloud::Talent::V4::JobService::ListJobsRequest'->new($_) };

declare 'RepeatedListJobsRequest',
    as ArrayRef[ListJobsRequest()];

coerce 'RepeatedListJobsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Talent::V4::JobService::ListJobsRequest'->new($_) } @$_ ] };

declare 'MapStringListJobsRequest',
    as HashRef[ListJobsRequest()];

declare 'ListJobsResponse',
    as InstanceOf['Google::Cloud::Talent::V4::JobService::ListJobsResponse'];

coerce 'ListJobsResponse',
    from HashRef, via { 'Google::Cloud::Talent::V4::JobService::ListJobsResponse'->new($_) };

declare 'RepeatedListJobsResponse',
    as ArrayRef[ListJobsResponse()];

coerce 'RepeatedListJobsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Talent::V4::JobService::ListJobsResponse'->new($_) } @$_ ] };

declare 'MapStringListJobsResponse',
    as HashRef[ListJobsResponse()];

declare 'SearchJobsRequest',
    as InstanceOf['Google::Cloud::Talent::V4::JobService::SearchJobsRequest'];

coerce 'SearchJobsRequest',
    from HashRef, via { 'Google::Cloud::Talent::V4::JobService::SearchJobsRequest'->new($_) };

declare 'RepeatedSearchJobsRequest',
    as ArrayRef[SearchJobsRequest()];

coerce 'RepeatedSearchJobsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Talent::V4::JobService::SearchJobsRequest'->new($_) } @$_ ] };

declare 'MapStringSearchJobsRequest',
    as HashRef[SearchJobsRequest()];

declare 'SearchMode',
    as (Int | Str);

declare 'DiversificationLevel',
    as (Int | Str);

declare 'KeywordMatchMode',
    as (Int | Str);

declare 'RelevanceThreshold',
    as (Int | Str);

declare 'CustomRankingInfo',
    as InstanceOf['Google::Cloud::Talent::V4::JobService::SearchJobsRequest::CustomRankingInfo'];

coerce 'CustomRankingInfo',
    from HashRef, via { 'Google::Cloud::Talent::V4::JobService::SearchJobsRequest::CustomRankingInfo'->new($_) };

declare 'RepeatedCustomRankingInfo',
    as ArrayRef[CustomRankingInfo()];

coerce 'RepeatedCustomRankingInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Talent::V4::JobService::SearchJobsRequest::CustomRankingInfo'->new($_) } @$_ ] };

declare 'MapStringCustomRankingInfo',
    as HashRef[CustomRankingInfo()];

declare 'ImportanceLevel',
    as (Int | Str);

declare 'SearchJobsResponse',
    as InstanceOf['Google::Cloud::Talent::V4::JobService::SearchJobsResponse'];

coerce 'SearchJobsResponse',
    from HashRef, via { 'Google::Cloud::Talent::V4::JobService::SearchJobsResponse'->new($_) };

declare 'RepeatedSearchJobsResponse',
    as ArrayRef[SearchJobsResponse()];

coerce 'RepeatedSearchJobsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Talent::V4::JobService::SearchJobsResponse'->new($_) } @$_ ] };

declare 'MapStringSearchJobsResponse',
    as HashRef[SearchJobsResponse()];

declare 'MatchingJob',
    as InstanceOf['Google::Cloud::Talent::V4::JobService::SearchJobsResponse::MatchingJob'];

coerce 'MatchingJob',
    from HashRef, via { 'Google::Cloud::Talent::V4::JobService::SearchJobsResponse::MatchingJob'->new($_) };

declare 'RepeatedMatchingJob',
    as ArrayRef[MatchingJob()];

coerce 'RepeatedMatchingJob',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Talent::V4::JobService::SearchJobsResponse::MatchingJob'->new($_) } @$_ ] };

declare 'MapStringMatchingJob',
    as HashRef[MatchingJob()];

declare 'CommuteInfo',
    as InstanceOf['Google::Cloud::Talent::V4::JobService::SearchJobsResponse::CommuteInfo'];

coerce 'CommuteInfo',
    from HashRef, via { 'Google::Cloud::Talent::V4::JobService::SearchJobsResponse::CommuteInfo'->new($_) };

declare 'RepeatedCommuteInfo',
    as ArrayRef[CommuteInfo()];

coerce 'RepeatedCommuteInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Talent::V4::JobService::SearchJobsResponse::CommuteInfo'->new($_) } @$_ ] };

declare 'MapStringCommuteInfo',
    as HashRef[CommuteInfo()];

declare 'BatchCreateJobsRequest',
    as InstanceOf['Google::Cloud::Talent::V4::JobService::BatchCreateJobsRequest'];

coerce 'BatchCreateJobsRequest',
    from HashRef, via { 'Google::Cloud::Talent::V4::JobService::BatchCreateJobsRequest'->new($_) };

declare 'RepeatedBatchCreateJobsRequest',
    as ArrayRef[BatchCreateJobsRequest()];

coerce 'RepeatedBatchCreateJobsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Talent::V4::JobService::BatchCreateJobsRequest'->new($_) } @$_ ] };

declare 'MapStringBatchCreateJobsRequest',
    as HashRef[BatchCreateJobsRequest()];

declare 'BatchUpdateJobsRequest',
    as InstanceOf['Google::Cloud::Talent::V4::JobService::BatchUpdateJobsRequest'];

coerce 'BatchUpdateJobsRequest',
    from HashRef, via { 'Google::Cloud::Talent::V4::JobService::BatchUpdateJobsRequest'->new($_) };

declare 'RepeatedBatchUpdateJobsRequest',
    as ArrayRef[BatchUpdateJobsRequest()];

coerce 'RepeatedBatchUpdateJobsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Talent::V4::JobService::BatchUpdateJobsRequest'->new($_) } @$_ ] };

declare 'MapStringBatchUpdateJobsRequest',
    as HashRef[BatchUpdateJobsRequest()];

declare 'BatchDeleteJobsRequest',
    as InstanceOf['Google::Cloud::Talent::V4::JobService::BatchDeleteJobsRequest'];

coerce 'BatchDeleteJobsRequest',
    from HashRef, via { 'Google::Cloud::Talent::V4::JobService::BatchDeleteJobsRequest'->new($_) };

declare 'RepeatedBatchDeleteJobsRequest',
    as ArrayRef[BatchDeleteJobsRequest()];

coerce 'RepeatedBatchDeleteJobsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Talent::V4::JobService::BatchDeleteJobsRequest'->new($_) } @$_ ] };

declare 'MapStringBatchDeleteJobsRequest',
    as HashRef[BatchDeleteJobsRequest()];

declare 'JobResult',
    as InstanceOf['Google::Cloud::Talent::V4::JobService::JobResult'];

coerce 'JobResult',
    from HashRef, via { 'Google::Cloud::Talent::V4::JobService::JobResult'->new($_) };

declare 'RepeatedJobResult',
    as ArrayRef[JobResult()];

coerce 'RepeatedJobResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Talent::V4::JobService::JobResult'->new($_) } @$_ ] };

declare 'MapStringJobResult',
    as HashRef[JobResult()];

declare 'BatchCreateJobsResponse',
    as InstanceOf['Google::Cloud::Talent::V4::JobService::BatchCreateJobsResponse'];

coerce 'BatchCreateJobsResponse',
    from HashRef, via { 'Google::Cloud::Talent::V4::JobService::BatchCreateJobsResponse'->new($_) };

declare 'RepeatedBatchCreateJobsResponse',
    as ArrayRef[BatchCreateJobsResponse()];

coerce 'RepeatedBatchCreateJobsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Talent::V4::JobService::BatchCreateJobsResponse'->new($_) } @$_ ] };

declare 'MapStringBatchCreateJobsResponse',
    as HashRef[BatchCreateJobsResponse()];

declare 'BatchUpdateJobsResponse',
    as InstanceOf['Google::Cloud::Talent::V4::JobService::BatchUpdateJobsResponse'];

coerce 'BatchUpdateJobsResponse',
    from HashRef, via { 'Google::Cloud::Talent::V4::JobService::BatchUpdateJobsResponse'->new($_) };

declare 'RepeatedBatchUpdateJobsResponse',
    as ArrayRef[BatchUpdateJobsResponse()];

coerce 'RepeatedBatchUpdateJobsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Talent::V4::JobService::BatchUpdateJobsResponse'->new($_) } @$_ ] };

declare 'MapStringBatchUpdateJobsResponse',
    as HashRef[BatchUpdateJobsResponse()];

declare 'BatchDeleteJobsResponse',
    as InstanceOf['Google::Cloud::Talent::V4::JobService::BatchDeleteJobsResponse'];

coerce 'BatchDeleteJobsResponse',
    from HashRef, via { 'Google::Cloud::Talent::V4::JobService::BatchDeleteJobsResponse'->new($_) };

declare 'RepeatedBatchDeleteJobsResponse',
    as ArrayRef[BatchDeleteJobsResponse()];

coerce 'RepeatedBatchDeleteJobsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Talent::V4::JobService::BatchDeleteJobsResponse'->new($_) } @$_ ] };

declare 'MapStringBatchDeleteJobsResponse',
    as HashRef[BatchDeleteJobsResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Talent::V4::JobService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
