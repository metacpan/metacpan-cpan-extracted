package Google::Cloud::BigQuery::V2::JobStatus::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'JobStatus',
    as InstanceOf['Google::Cloud::BigQuery::V2::JobStatus::JobStatus'];

coerce 'JobStatus',
    from HashRef, via { 'Google::Cloud::BigQuery::V2::JobStatus::JobStatus'->new($_) };

declare 'RepeatedJobStatus',
    as ArrayRef[JobStatus()];

coerce 'RepeatedJobStatus',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::BigQuery::V2::JobStatus::JobStatus'->new($_) } @$_ ] };

declare 'MapStringJobStatus',
    as HashRef[JobStatus()];

1;
