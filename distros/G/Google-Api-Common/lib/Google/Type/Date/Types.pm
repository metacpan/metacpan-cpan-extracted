package Google::Type::Date::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Date',
    as InstanceOf['Google::Type::Date::Date'];

coerce 'Date',
    from HashRef, via { 'Google::Type::Date::Date'->new($_) };

declare 'RepeatedDate',
    as ArrayRef[Date()];

coerce 'RepeatedDate',
    from ArrayRef[HashRef], via { [ map { 'Google::Type::Date::Date'->new($_) } @$_ ] };

declare 'MapStringDate',
    as HashRef[Date()];

1;
