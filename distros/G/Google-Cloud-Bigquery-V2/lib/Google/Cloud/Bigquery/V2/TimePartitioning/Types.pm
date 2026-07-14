package Google::Cloud::Bigquery::V2::TimePartitioning::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'TimePartitioning',
    as InstanceOf['Google::Cloud::Bigquery::V2::TimePartitioning::TimePartitioning'];

coerce 'TimePartitioning',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::TimePartitioning::TimePartitioning'->new($_) };

declare 'RepeatedTimePartitioning',
    as ArrayRef[TimePartitioning()];

coerce 'RepeatedTimePartitioning',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::TimePartitioning::TimePartitioning'->new($_) } @$_ ] };

declare 'MapStringTimePartitioning',
    as HashRef[TimePartitioning()];

1;
