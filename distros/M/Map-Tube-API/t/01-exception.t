#!/usr/bin/env perl

use 5.006;
use strict;
use warnings FATAL => 'all';

use Test::More;
use Map::Tube::API::Exception;

my $ex = Map::Tube::API::Exception->new({ code => 404, message => 'Not Found' });
isa_ok($ex, 'Map::Tube::API::Exception');
is($ex->code,    404,         'code() returns what was passed in');
is($ex->message, 'Not Found', 'message() returns what was passed in');

is(
    $ex->as_string,
    "ERROR: Not Found (status: 404)\n",
    'as_string() formats code and message as documented'
);

is(
    "$ex",
    "ERROR: Not Found (status: 404)\n",
    'stringification overload ("") matches as_string()'
);

eval { Map::Tube::API::Exception->new({ message => 'no code given' }) };
ok($@, 'construction without required "code" attribute dies');

eval { Map::Tube::API::Exception->new({ code => 500 }) };
ok($@, 'construction without required "message" attribute dies');

eval {
    Map::Tube::API::Exception->throw({ code => 503, message => 'Service Unavailable' });
};
isa_ok($@, 'Map::Tube::API::Exception', '->throw() dies with the exception object itself ($@)');

done_testing;
