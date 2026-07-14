package Google::Cloud::Bigquery::V2::ModelReference::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ModelReference',
    as InstanceOf['Google::Cloud::Bigquery::V2::ModelReference::ModelReference'];

coerce 'ModelReference',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::ModelReference::ModelReference'->new($_) };

declare 'RepeatedModelReference',
    as ArrayRef[ModelReference()];

coerce 'RepeatedModelReference',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::ModelReference::ModelReference'->new($_) } @$_ ] };

declare 'MapStringModelReference',
    as HashRef[ModelReference()];

1;
