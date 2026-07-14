package Google::Cloud::Bigquery::V2::JobStatus::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'JobStatus',
    as InstanceOf['Google::Cloud::Bigquery::V2::JobStatus::JobStatus'];

coerce 'JobStatus',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::JobStatus::JobStatus'->new($_) };

declare 'RepeatedJobStatus',
    as ArrayRef[JobStatus()];

coerce 'RepeatedJobStatus',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::JobStatus::JobStatus'->new($_) } @$_ ] };

declare 'MapStringJobStatus',
    as HashRef[JobStatus()];

declare 'ContinuousJobStatus',
    as InstanceOf['Google::Cloud::Bigquery::V2::JobStatus::ContinuousJobStatus'];

coerce 'ContinuousJobStatus',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::JobStatus::ContinuousJobStatus'->new($_) };

declare 'RepeatedContinuousJobStatus',
    as ArrayRef[ContinuousJobStatus()];

coerce 'RepeatedContinuousJobStatus',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::JobStatus::ContinuousJobStatus'->new($_) } @$_ ] };

declare 'MapStringContinuousJobStatus',
    as HashRef[ContinuousJobStatus()];

1;
