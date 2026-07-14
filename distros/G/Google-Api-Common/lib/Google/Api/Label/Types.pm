package Google::Api::Label::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'LabelDescriptor',
    as InstanceOf['Google::Api::Label::LabelDescriptor'];

coerce 'LabelDescriptor',
    from HashRef, via { 'Google::Api::Label::LabelDescriptor'->new($_) };

declare 'RepeatedLabelDescriptor',
    as ArrayRef[LabelDescriptor()];

coerce 'RepeatedLabelDescriptor',
    from ArrayRef[HashRef], via { [ map { 'Google::Api::Label::LabelDescriptor'->new($_) } @$_ ] };

declare 'MapStringLabelDescriptor',
    as HashRef[LabelDescriptor()];

declare 'ValueType',
    as (Int | Str);

1;
