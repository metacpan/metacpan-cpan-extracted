package Google::Cloud::Bigquery::V2::JobReference::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'JobReference',
    as InstanceOf['Google::Cloud::Bigquery::V2::JobReference::JobReference'];

coerce 'JobReference',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::JobReference::JobReference'->new($_) };

declare 'RepeatedJobReference',
    as ArrayRef[JobReference()];

coerce 'RepeatedJobReference',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::JobReference::JobReference'->new($_) } @$_ ] };

declare 'MapStringJobReference',
    as HashRef[JobReference()];

1;
