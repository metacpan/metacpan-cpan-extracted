package Google::Api::Endpoint::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Endpoint',
    as InstanceOf['Google::Api::Endpoint::Endpoint'];

coerce 'Endpoint',
    from HashRef, via { 'Google::Api::Endpoint::Endpoint'->new($_) };

declare 'RepeatedEndpoint',
    as ArrayRef[Endpoint()];

coerce 'RepeatedEndpoint',
    from ArrayRef[HashRef], via { [ map { 'Google::Api::Endpoint::Endpoint'->new($_) } @$_ ] };

declare 'MapStringEndpoint',
    as HashRef[Endpoint()];

1;
