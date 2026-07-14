package Google::Api::Consumer::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ProjectProperties',
    as InstanceOf['Google::Api::Consumer::ProjectProperties'];

coerce 'ProjectProperties',
    from HashRef, via { 'Google::Api::Consumer::ProjectProperties'->new($_) };

declare 'RepeatedProjectProperties',
    as ArrayRef[ProjectProperties()];

coerce 'RepeatedProjectProperties',
    from ArrayRef[HashRef], via { [ map { 'Google::Api::Consumer::ProjectProperties'->new($_) } @$_ ] };

declare 'MapStringProjectProperties',
    as HashRef[ProjectProperties()];

declare 'Property',
    as InstanceOf['Google::Api::Consumer::Property'];

coerce 'Property',
    from HashRef, via { 'Google::Api::Consumer::Property'->new($_) };

declare 'RepeatedProperty',
    as ArrayRef[Property()];

coerce 'RepeatedProperty',
    from ArrayRef[HashRef], via { [ map { 'Google::Api::Consumer::Property'->new($_) } @$_ ] };

declare 'MapStringProperty',
    as HashRef[Property()];

declare 'PropertyType',
    as (Int | Str);

1;
