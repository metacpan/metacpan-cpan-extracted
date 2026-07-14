package Google::Cloud::BigQuery::V2::QueryParameter::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'QueryParameterStructType',
    as InstanceOf['Google::Cloud::BigQuery::V2::QueryParameter::QueryParameterStructType'];

coerce 'QueryParameterStructType',
    from HashRef, via { 'Google::Cloud::BigQuery::V2::QueryParameter::QueryParameterStructType'->new($_) };

declare 'RepeatedQueryParameterStructType',
    as ArrayRef[QueryParameterStructType()];

coerce 'RepeatedQueryParameterStructType',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::BigQuery::V2::QueryParameter::QueryParameterStructType'->new($_) } @$_ ] };

declare 'MapStringQueryParameterStructType',
    as HashRef[QueryParameterStructType()];

declare 'QueryParameterType',
    as InstanceOf['Google::Cloud::BigQuery::V2::QueryParameter::QueryParameterType'];

coerce 'QueryParameterType',
    from HashRef, via { 'Google::Cloud::BigQuery::V2::QueryParameter::QueryParameterType'->new($_) };

declare 'RepeatedQueryParameterType',
    as ArrayRef[QueryParameterType()];

coerce 'RepeatedQueryParameterType',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::BigQuery::V2::QueryParameter::QueryParameterType'->new($_) } @$_ ] };

declare 'MapStringQueryParameterType',
    as HashRef[QueryParameterType()];

declare 'RangeValue',
    as InstanceOf['Google::Cloud::BigQuery::V2::QueryParameter::RangeValue'];

coerce 'RangeValue',
    from HashRef, via { 'Google::Cloud::BigQuery::V2::QueryParameter::RangeValue'->new($_) };

declare 'RepeatedRangeValue',
    as ArrayRef[RangeValue()];

coerce 'RepeatedRangeValue',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::BigQuery::V2::QueryParameter::RangeValue'->new($_) } @$_ ] };

declare 'MapStringRangeValue',
    as HashRef[RangeValue()];

declare 'QueryParameterValue',
    as InstanceOf['Google::Cloud::BigQuery::V2::QueryParameter::QueryParameterValue'];

coerce 'QueryParameterValue',
    from HashRef, via { 'Google::Cloud::BigQuery::V2::QueryParameter::QueryParameterValue'->new($_) };

declare 'RepeatedQueryParameterValue',
    as ArrayRef[QueryParameterValue()];

coerce 'RepeatedQueryParameterValue',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::BigQuery::V2::QueryParameter::QueryParameterValue'->new($_) } @$_ ] };

declare 'MapStringQueryParameterValue',
    as HashRef[QueryParameterValue()];

declare 'StructValuesEntry',
    as InstanceOf['Google::Cloud::BigQuery::V2::QueryParameter::QueryParameterValue::StructValuesEntry'];

coerce 'StructValuesEntry',
    from HashRef, via { 'Google::Cloud::BigQuery::V2::QueryParameter::QueryParameterValue::StructValuesEntry'->new($_) };

declare 'RepeatedStructValuesEntry',
    as ArrayRef[StructValuesEntry()];

coerce 'RepeatedStructValuesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::BigQuery::V2::QueryParameter::QueryParameterValue::StructValuesEntry'->new($_) } @$_ ] };

declare 'MapStringStructValuesEntry',
    as HashRef[StructValuesEntry()];

declare 'QueryParameter',
    as InstanceOf['Google::Cloud::BigQuery::V2::QueryParameter::QueryParameter'];

coerce 'QueryParameter',
    from HashRef, via { 'Google::Cloud::BigQuery::V2::QueryParameter::QueryParameter'->new($_) };

declare 'RepeatedQueryParameter',
    as ArrayRef[QueryParameter()];

coerce 'RepeatedQueryParameter',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::BigQuery::V2::QueryParameter::QueryParameter'->new($_) } @$_ ] };

declare 'MapStringQueryParameter',
    as HashRef[QueryParameter()];

1;
