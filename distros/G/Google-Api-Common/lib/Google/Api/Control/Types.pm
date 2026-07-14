package Google::Api::Control::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Control',
    as InstanceOf['Google::Api::Control::Control'];

coerce 'Control',
    from HashRef, via { 'Google::Api::Control::Control'->new($_) };

declare 'RepeatedControl',
    as ArrayRef[Control()];

coerce 'RepeatedControl',
    from ArrayRef[HashRef], via { [ map { 'Google::Api::Control::Control'->new($_) } @$_ ] };

declare 'MapStringControl',
    as HashRef[Control()];

1;
