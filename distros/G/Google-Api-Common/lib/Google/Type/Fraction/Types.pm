package Google::Type::Fraction::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Fraction',
    as InstanceOf['Google::Type::Fraction::Fraction'];

coerce 'Fraction',
    from HashRef, via { 'Google::Type::Fraction::Fraction'->new($_) };

declare 'RepeatedFraction',
    as ArrayRef[Fraction()];

coerce 'RepeatedFraction',
    from ArrayRef[HashRef], via { [ map { 'Google::Type::Fraction::Fraction'->new($_) } @$_ ] };

declare 'MapStringFraction',
    as HashRef[Fraction()];

1;
