use strict;
use warnings;
use Test::More;

unless ( eval { require JSON; 1 } ) {
    plan skip_all => 'No JSON';
}

my $data = JSON->new->decode('{"foo": true, "bar": false, "baz": 1}');

ok(
    JSON::is_bool($data->{foo}),
    'JSON.pm: true decodes to a bool',
);
ok(
    JSON::is_bool($data->{bar}),
    'JSON.pm:: false decodes to a bool',
);
ok(
    !JSON::is_bool($data->{baz}),
    'JSON.pm: int does not decode to a bool',
);

done_testing;
