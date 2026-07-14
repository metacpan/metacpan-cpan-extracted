package Google::Cloud::BigQuery::V2::SystemVariable::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'SystemVariables',
    as InstanceOf['Google::Cloud::BigQuery::V2::SystemVariable::SystemVariables'];

coerce 'SystemVariables',
    from HashRef, via { 'Google::Cloud::BigQuery::V2::SystemVariable::SystemVariables'->new($_) };

declare 'RepeatedSystemVariables',
    as ArrayRef[SystemVariables()];

coerce 'RepeatedSystemVariables',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::BigQuery::V2::SystemVariable::SystemVariables'->new($_) } @$_ ] };

declare 'MapStringSystemVariables',
    as HashRef[SystemVariables()];

declare 'TypesEntry',
    as InstanceOf['Google::Cloud::BigQuery::V2::SystemVariable::SystemVariables::TypesEntry'];

coerce 'TypesEntry',
    from HashRef, via { 'Google::Cloud::BigQuery::V2::SystemVariable::SystemVariables::TypesEntry'->new($_) };

declare 'RepeatedTypesEntry',
    as ArrayRef[TypesEntry()];

coerce 'RepeatedTypesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::BigQuery::V2::SystemVariable::SystemVariables::TypesEntry'->new($_) } @$_ ] };

declare 'MapStringTypesEntry',
    as HashRef[TypesEntry()];

1;
