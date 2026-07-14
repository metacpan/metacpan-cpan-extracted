package Google::Type::Quaternion::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Quaternion',
    as InstanceOf['Google::Type::Quaternion::Quaternion'];

coerce 'Quaternion',
    from HashRef, via { 'Google::Type::Quaternion::Quaternion'->new($_) };

declare 'RepeatedQuaternion',
    as ArrayRef[Quaternion()];

coerce 'RepeatedQuaternion',
    from ArrayRef[HashRef], via { [ map { 'Google::Type::Quaternion::Quaternion'->new($_) } @$_ ] };

declare 'MapStringQuaternion',
    as HashRef[Quaternion()];

1;
