package Google::Cloud::Bigquery::V2::PropertyGraphReference::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'PropertyGraphReference',
    as InstanceOf['Google::Cloud::Bigquery::V2::PropertyGraphReference::PropertyGraphReference'];

coerce 'PropertyGraphReference',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::PropertyGraphReference::PropertyGraphReference'->new($_) };

declare 'RepeatedPropertyGraphReference',
    as ArrayRef[PropertyGraphReference()];

coerce 'RepeatedPropertyGraphReference',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::PropertyGraphReference::PropertyGraphReference'->new($_) } @$_ ] };

declare 'MapStringPropertyGraphReference',
    as HashRef[PropertyGraphReference()];

1;
