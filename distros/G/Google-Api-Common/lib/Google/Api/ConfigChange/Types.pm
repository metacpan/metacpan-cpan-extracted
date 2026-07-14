package Google::Api::ConfigChange::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ChangeType',
    as (Int | Str);

declare 'ConfigChange',
    as InstanceOf['Google::Api::ConfigChange::ConfigChange'];

coerce 'ConfigChange',
    from HashRef, via { 'Google::Api::ConfigChange::ConfigChange'->new($_) };

declare 'RepeatedConfigChange',
    as ArrayRef[ConfigChange()];

coerce 'RepeatedConfigChange',
    from ArrayRef[HashRef], via { [ map { 'Google::Api::ConfigChange::ConfigChange'->new($_) } @$_ ] };

declare 'MapStringConfigChange',
    as HashRef[ConfigChange()];

declare 'Advice',
    as InstanceOf['Google::Api::ConfigChange::Advice'];

coerce 'Advice',
    from HashRef, via { 'Google::Api::ConfigChange::Advice'->new($_) };

declare 'RepeatedAdvice',
    as ArrayRef[Advice()];

coerce 'RepeatedAdvice',
    from ArrayRef[HashRef], via { [ map { 'Google::Api::ConfigChange::Advice'->new($_) } @$_ ] };

declare 'MapStringAdvice',
    as HashRef[Advice()];

1;
