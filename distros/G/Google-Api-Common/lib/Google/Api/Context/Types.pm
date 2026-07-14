package Google::Api::Context::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Context',
    as InstanceOf['Google::Api::Context::Context'];

coerce 'Context',
    from HashRef, via { 'Google::Api::Context::Context'->new($_) };

declare 'RepeatedContext',
    as ArrayRef[Context()];

coerce 'RepeatedContext',
    from ArrayRef[HashRef], via { [ map { 'Google::Api::Context::Context'->new($_) } @$_ ] };

declare 'MapStringContext',
    as HashRef[Context()];

declare 'ContextRule',
    as InstanceOf['Google::Api::Context::ContextRule'];

coerce 'ContextRule',
    from HashRef, via { 'Google::Api::Context::ContextRule'->new($_) };

declare 'RepeatedContextRule',
    as ArrayRef[ContextRule()];

coerce 'RepeatedContextRule',
    from ArrayRef[HashRef], via { [ map { 'Google::Api::Context::ContextRule'->new($_) } @$_ ] };

declare 'MapStringContextRule',
    as HashRef[ContextRule()];

1;
