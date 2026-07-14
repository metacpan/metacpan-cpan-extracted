package Google::Type::Datetime::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'DateTime',
    as InstanceOf['Google::Type::Datetime::DateTime'];

coerce 'DateTime',
    from HashRef, via { 'Google::Type::Datetime::DateTime'->new($_) };

declare 'RepeatedDateTime',
    as ArrayRef[DateTime()];

coerce 'RepeatedDateTime',
    from ArrayRef[HashRef], via { [ map { 'Google::Type::Datetime::DateTime'->new($_) } @$_ ] };

declare 'MapStringDateTime',
    as HashRef[DateTime()];

declare 'TimeZone',
    as InstanceOf['Google::Type::Datetime::TimeZone'];

coerce 'TimeZone',
    from HashRef, via { 'Google::Type::Datetime::TimeZone'->new($_) };

declare 'RepeatedTimeZone',
    as ArrayRef[TimeZone()];

coerce 'RepeatedTimeZone',
    from ArrayRef[HashRef], via { [ map { 'Google::Type::Datetime::TimeZone'->new($_) } @$_ ] };

declare 'MapStringTimeZone',
    as HashRef[TimeZone()];

1;
