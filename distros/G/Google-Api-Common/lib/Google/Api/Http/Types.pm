package Google::Api::Http::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Http',
    as InstanceOf['Google::Api::Http::Http'];

coerce 'Http',
    from HashRef, via { 'Google::Api::Http::Http'->new($_) };

declare 'RepeatedHttp',
    as ArrayRef[Http()];

coerce 'RepeatedHttp',
    from ArrayRef[HashRef], via { [ map { 'Google::Api::Http::Http'->new($_) } @$_ ] };

declare 'MapStringHttp',
    as HashRef[Http()];

declare 'HttpRule',
    as InstanceOf['Google::Api::Http::HttpRule'];

coerce 'HttpRule',
    from HashRef, via { 'Google::Api::Http::HttpRule'->new($_) };

declare 'RepeatedHttpRule',
    as ArrayRef[HttpRule()];

coerce 'RepeatedHttpRule',
    from ArrayRef[HashRef], via { [ map { 'Google::Api::Http::HttpRule'->new($_) } @$_ ] };

declare 'MapStringHttpRule',
    as HashRef[HttpRule()];

declare 'CustomHttpPattern',
    as InstanceOf['Google::Api::Http::CustomHttpPattern'];

coerce 'CustomHttpPattern',
    from HashRef, via { 'Google::Api::Http::CustomHttpPattern'->new($_) };

declare 'RepeatedCustomHttpPattern',
    as ArrayRef[CustomHttpPattern()];

coerce 'RepeatedCustomHttpPattern',
    from ArrayRef[HashRef], via { [ map { 'Google::Api::Http::CustomHttpPattern'->new($_) } @$_ ] };

declare 'MapStringCustomHttpPattern',
    as HashRef[CustomHttpPattern()];

1;
