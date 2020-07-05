use strict;
use warnings;

use Test::More;
use JSON::SchemaValidator::Pointer;

subtest 'schema not modified' => sub {
    my $schema = {foo => {bar => 'baz'}};

    JSON::SchemaValidator::Pointer::pointer($schema, '#/foo/bar');

    is_deeply $schema, {foo => {bar => 'baz'}};
};

is_deeply JSON::SchemaValidator::Pointer::pointer({foo => 'bar'}, '#'), {foo => 'bar'};

is JSON::SchemaValidator::Pointer::pointer({'hello~there' => 'bar'}, '#/hello~0there'), 'bar';
is JSON::SchemaValidator::Pointer::pointer({'hello/there' => 'bar'}, '#/hello~1there'), 'bar';
is JSON::SchemaValidator::Pointer::pointer({'foo bar'     => 'bar'}, '#/foo%20bar'),    'bar';

is JSON::SchemaValidator::Pointer::pointer({foo => 'bar'},          '#/foo'),     'bar';
is JSON::SchemaValidator::Pointer::pointer({foo => {bar => 'baz'}}, '#/foo/bar'), 'baz';

is JSON::SchemaValidator::Pointer::pointer({foo => [1, 2, 3]}, '#/foo/2'), 3;

done_testing;
