package Google::Type::Money::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Money',
    as InstanceOf['Google::Type::Money::Money'];

coerce 'Money',
    from HashRef, via { 'Google::Type::Money::Money'->new($_) };

declare 'RepeatedMoney',
    as ArrayRef[Money()];

coerce 'RepeatedMoney',
    from ArrayRef[HashRef], via { [ map { 'Google::Type::Money::Money'->new($_) } @$_ ] };

declare 'MapStringMoney',
    as HashRef[Money()];

1;
