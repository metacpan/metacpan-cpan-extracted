package Google::Type::Decimal::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Decimal',
    as InstanceOf['Google::Type::Decimal::Decimal'];

coerce 'Decimal',
    from HashRef, via { 'Google::Type::Decimal::Decimal'->new($_) };

declare 'RepeatedDecimal',
    as ArrayRef[Decimal()];

coerce 'RepeatedDecimal',
    from ArrayRef[HashRef], via { [ map { 'Google::Type::Decimal::Decimal'->new($_) } @$_ ] };

declare 'MapStringDecimal',
    as HashRef[Decimal()];

1;
