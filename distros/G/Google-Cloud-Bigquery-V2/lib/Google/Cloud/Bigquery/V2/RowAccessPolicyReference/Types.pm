package Google::Cloud::Bigquery::V2::RowAccessPolicyReference::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'RowAccessPolicyReference',
    as InstanceOf['Google::Cloud::Bigquery::V2::RowAccessPolicyReference::RowAccessPolicyReference'];

coerce 'RowAccessPolicyReference',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::RowAccessPolicyReference::RowAccessPolicyReference'->new($_) };

declare 'RepeatedRowAccessPolicyReference',
    as ArrayRef[RowAccessPolicyReference()];

coerce 'RepeatedRowAccessPolicyReference',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::RowAccessPolicyReference::RowAccessPolicyReference'->new($_) } @$_ ] };

declare 'MapStringRowAccessPolicyReference',
    as HashRef[RowAccessPolicyReference()];

1;
