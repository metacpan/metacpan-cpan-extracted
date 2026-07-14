package Google::Type::PostalAddress::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'PostalAddress',
    as InstanceOf['Google::Type::PostalAddress::PostalAddress'];

coerce 'PostalAddress',
    from HashRef, via { 'Google::Type::PostalAddress::PostalAddress'->new($_) };

declare 'RepeatedPostalAddress',
    as ArrayRef[PostalAddress()];

coerce 'RepeatedPostalAddress',
    from ArrayRef[HashRef], via { [ map { 'Google::Type::PostalAddress::PostalAddress'->new($_) } @$_ ] };

declare 'MapStringPostalAddress',
    as HashRef[PostalAddress()];

1;
