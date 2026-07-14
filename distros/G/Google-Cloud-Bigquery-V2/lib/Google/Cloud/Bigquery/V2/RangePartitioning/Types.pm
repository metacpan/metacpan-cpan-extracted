package Google::Cloud::Bigquery::V2::RangePartitioning::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'RangePartitioning',
    as InstanceOf['Google::Cloud::Bigquery::V2::RangePartitioning::RangePartitioning'];

coerce 'RangePartitioning',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::RangePartitioning::RangePartitioning'->new($_) };

declare 'RepeatedRangePartitioning',
    as ArrayRef[RangePartitioning()];

coerce 'RepeatedRangePartitioning',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::RangePartitioning::RangePartitioning'->new($_) } @$_ ] };

declare 'MapStringRangePartitioning',
    as HashRef[RangePartitioning()];

declare 'Range',
    as InstanceOf['Google::Cloud::Bigquery::V2::RangePartitioning::RangePartitioning::Range'];

coerce 'Range',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::RangePartitioning::RangePartitioning::Range'->new($_) };

declare 'RepeatedRange',
    as ArrayRef[Range()];

coerce 'RepeatedRange',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::RangePartitioning::RangePartitioning::Range'->new($_) } @$_ ] };

declare 'MapStringRange',
    as HashRef[Range()];

1;
