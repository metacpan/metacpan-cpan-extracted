package Google::Api::Service::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Service',
    as InstanceOf['Google::Api::Service::Service'];

coerce 'Service',
    from HashRef, via { 'Google::Api::Service::Service'->new($_) };

declare 'RepeatedService',
    as ArrayRef[Service()];

coerce 'RepeatedService',
    from ArrayRef[HashRef], via { [ map { 'Google::Api::Service::Service'->new($_) } @$_ ] };

declare 'MapStringService',
    as HashRef[Service()];

1;
