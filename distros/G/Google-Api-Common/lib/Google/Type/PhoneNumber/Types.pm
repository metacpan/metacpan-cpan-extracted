package Google::Type::PhoneNumber::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'PhoneNumber',
    as InstanceOf['Google::Type::PhoneNumber::PhoneNumber'];

coerce 'PhoneNumber',
    from HashRef, via { 'Google::Type::PhoneNumber::PhoneNumber'->new($_) };

declare 'RepeatedPhoneNumber',
    as ArrayRef[PhoneNumber()];

coerce 'RepeatedPhoneNumber',
    from ArrayRef[HashRef], via { [ map { 'Google::Type::PhoneNumber::PhoneNumber'->new($_) } @$_ ] };

declare 'MapStringPhoneNumber',
    as HashRef[PhoneNumber()];

declare 'ShortCode',
    as InstanceOf['Google::Type::PhoneNumber::PhoneNumber::ShortCode'];

coerce 'ShortCode',
    from HashRef, via { 'Google::Type::PhoneNumber::PhoneNumber::ShortCode'->new($_) };

declare 'RepeatedShortCode',
    as ArrayRef[ShortCode()];

coerce 'RepeatedShortCode',
    from ArrayRef[HashRef], via { [ map { 'Google::Type::PhoneNumber::PhoneNumber::ShortCode'->new($_) } @$_ ] };

declare 'MapStringShortCode',
    as HashRef[ShortCode()];

1;
