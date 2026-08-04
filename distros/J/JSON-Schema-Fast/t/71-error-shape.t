use strict; use warnings;
use Test::More;
use JSON::Schema::Fast;
use File::Raw::JSON;
sub J { File::Raw::JSON::file_json_decode($_[0]) }

# a fixed schema + data pair maps to a fixed set of error triples, so the
# error vocabulary can't silently regress.
my $v = JSON::Schema::Fast->compile({
    type       => 'object',
    required   => ['name'],
    properties => {
        age  => { type => 'integer', minimum => 0 },
        tags => { type => 'array', items => { type => 'string' } },
    },
});

my $errs = $v->errors(J('{"age":-1,"tags":["ok",7]}'));
my %got = map {
    $_->{keyword} => { il => $_->{instanceLocation}, sl => $_->{schemaLocation} }
} @$errs;

is_deeply($got{required}, { il => '', sl => '/required' },
    'required: root instanceLocation, /required schemaLocation');
is_deeply($got{minimum}, { il => '/age', sl => '/properties/age/minimum' },
    'minimum: /age, /properties/age/minimum');
is_deeply($got{type}, { il => '/tags/1', sl => '/properties/tags/items/type' },
    'nested array item: /tags/1, /properties/tags/items/type');

is(scalar(@$errs), 3, 'exactly the three expected errors');

done_testing;
