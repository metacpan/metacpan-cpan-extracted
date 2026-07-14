package Google::Cloud::Bigquery::V2::UdfResource::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'UserDefinedFunctionResource',
    as InstanceOf['Google::Cloud::Bigquery::V2::UdfResource::UserDefinedFunctionResource'];

coerce 'UserDefinedFunctionResource',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::UdfResource::UserDefinedFunctionResource'->new($_) };

declare 'RepeatedUserDefinedFunctionResource',
    as ArrayRef[UserDefinedFunctionResource()];

coerce 'RepeatedUserDefinedFunctionResource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::UdfResource::UserDefinedFunctionResource'->new($_) } @$_ ] };

declare 'MapStringUserDefinedFunctionResource',
    as HashRef[UserDefinedFunctionResource()];

1;
