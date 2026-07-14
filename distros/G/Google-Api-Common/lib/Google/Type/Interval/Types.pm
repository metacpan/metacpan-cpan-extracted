package Google::Type::Interval::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Interval',
    as InstanceOf['Google::Type::Interval::Interval'];

coerce 'Interval',
    from HashRef, via { 'Google::Type::Interval::Interval'->new($_) };

declare 'RepeatedInterval',
    as ArrayRef[Interval()];

coerce 'RepeatedInterval',
    from ArrayRef[HashRef], via { [ map { 'Google::Type::Interval::Interval'->new($_) } @$_ ] };

declare 'MapStringInterval',
    as HashRef[Interval()];

1;
