package Google::Api::SystemParameter::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'SystemParameters',
    as InstanceOf['Google::Api::SystemParameter::SystemParameters'];

coerce 'SystemParameters',
    from HashRef, via { 'Google::Api::SystemParameter::SystemParameters'->new($_) };

declare 'RepeatedSystemParameters',
    as ArrayRef[SystemParameters()];

coerce 'RepeatedSystemParameters',
    from ArrayRef[HashRef], via { [ map { 'Google::Api::SystemParameter::SystemParameters'->new($_) } @$_ ] };

declare 'MapStringSystemParameters',
    as HashRef[SystemParameters()];

declare 'SystemParameterRule',
    as InstanceOf['Google::Api::SystemParameter::SystemParameterRule'];

coerce 'SystemParameterRule',
    from HashRef, via { 'Google::Api::SystemParameter::SystemParameterRule'->new($_) };

declare 'RepeatedSystemParameterRule',
    as ArrayRef[SystemParameterRule()];

coerce 'RepeatedSystemParameterRule',
    from ArrayRef[HashRef], via { [ map { 'Google::Api::SystemParameter::SystemParameterRule'->new($_) } @$_ ] };

declare 'MapStringSystemParameterRule',
    as HashRef[SystemParameterRule()];

declare 'SystemParameter',
    as InstanceOf['Google::Api::SystemParameter::SystemParameter'];

coerce 'SystemParameter',
    from HashRef, via { 'Google::Api::SystemParameter::SystemParameter'->new($_) };

declare 'RepeatedSystemParameter',
    as ArrayRef[SystemParameter()];

coerce 'RepeatedSystemParameter',
    from ArrayRef[HashRef], via { [ map { 'Google::Api::SystemParameter::SystemParameter'->new($_) } @$_ ] };

declare 'MapStringSystemParameter',
    as HashRef[SystemParameter()];

1;
