package Google::Cloud::Bigquery::V2::JobCreationReason::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'JobCreationReason',
    as InstanceOf['Google::Cloud::Bigquery::V2::JobCreationReason::JobCreationReason'];

coerce 'JobCreationReason',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::JobCreationReason::JobCreationReason'->new($_) };

declare 'RepeatedJobCreationReason',
    as ArrayRef[JobCreationReason()];

coerce 'RepeatedJobCreationReason',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::JobCreationReason::JobCreationReason'->new($_) } @$_ ] };

declare 'MapStringJobCreationReason',
    as HashRef[JobCreationReason()];

declare 'Code',
    as (Int | Str);

1;
