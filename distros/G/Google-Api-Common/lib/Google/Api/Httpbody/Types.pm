package Google::Api::Httpbody::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'HttpBody',
    as InstanceOf['Google::Api::Httpbody::HttpBody'];

coerce 'HttpBody',
    from HashRef, via { 'Google::Api::Httpbody::HttpBody'->new($_) };

declare 'RepeatedHttpBody',
    as ArrayRef[HttpBody()];

coerce 'RepeatedHttpBody',
    from ArrayRef[HashRef], via { [ map { 'Google::Api::Httpbody::HttpBody'->new($_) } @$_ ] };

declare 'MapStringHttpBody',
    as HashRef[HttpBody()];

1;
