package Google::Cloud::BigQuery::V2::RoutineReference::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'RoutineReference',
    as InstanceOf['Google::Cloud::BigQuery::V2::RoutineReference::RoutineReference'];

coerce 'RoutineReference',
    from HashRef, via { 'Google::Cloud::BigQuery::V2::RoutineReference::RoutineReference'->new($_) };

declare 'RepeatedRoutineReference',
    as ArrayRef[RoutineReference()];

coerce 'RepeatedRoutineReference',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::BigQuery::V2::RoutineReference::RoutineReference'->new($_) } @$_ ] };

declare 'MapStringRoutineReference',
    as HashRef[RoutineReference()];

1;
