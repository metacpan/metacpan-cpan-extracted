package Google::Api::Policy::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'FieldPolicy',
    as InstanceOf['Google::Api::Policy::FieldPolicy'];

coerce 'FieldPolicy',
    from HashRef, via { 'Google::Api::Policy::FieldPolicy'->new($_) };

declare 'RepeatedFieldPolicy',
    as ArrayRef[FieldPolicy()];

coerce 'RepeatedFieldPolicy',
    from ArrayRef[HashRef], via { [ map { 'Google::Api::Policy::FieldPolicy'->new($_) } @$_ ] };

declare 'MapStringFieldPolicy',
    as HashRef[FieldPolicy()];

declare 'MethodPolicy',
    as InstanceOf['Google::Api::Policy::MethodPolicy'];

coerce 'MethodPolicy',
    from HashRef, via { 'Google::Api::Policy::MethodPolicy'->new($_) };

declare 'RepeatedMethodPolicy',
    as ArrayRef[MethodPolicy()];

coerce 'RepeatedMethodPolicy',
    from ArrayRef[HashRef], via { [ map { 'Google::Api::Policy::MethodPolicy'->new($_) } @$_ ] };

declare 'MapStringMethodPolicy',
    as HashRef[MethodPolicy()];

1;
