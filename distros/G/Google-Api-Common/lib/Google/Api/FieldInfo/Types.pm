package Google::Api::FieldInfo::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'FieldInfo',
    as InstanceOf['Google::Api::FieldInfo::FieldInfo'];

coerce 'FieldInfo',
    from HashRef, via { 'Google::Api::FieldInfo::FieldInfo'->new($_) };

declare 'RepeatedFieldInfo',
    as ArrayRef[FieldInfo()];

coerce 'RepeatedFieldInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Api::FieldInfo::FieldInfo'->new($_) } @$_ ] };

declare 'MapStringFieldInfo',
    as HashRef[FieldInfo()];

declare 'Format',
    as (Int | Str);

declare 'TypeReference',
    as InstanceOf['Google::Api::FieldInfo::TypeReference'];

coerce 'TypeReference',
    from HashRef, via { 'Google::Api::FieldInfo::TypeReference'->new($_) };

declare 'RepeatedTypeReference',
    as ArrayRef[TypeReference()];

coerce 'RepeatedTypeReference',
    from ArrayRef[HashRef], via { [ map { 'Google::Api::FieldInfo::TypeReference'->new($_) } @$_ ] };

declare 'MapStringTypeReference',
    as HashRef[TypeReference()];

1;
