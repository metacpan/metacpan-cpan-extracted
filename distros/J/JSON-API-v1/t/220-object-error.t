use Test::Lib;
use Test::JSON::API::v1;


cmp_object_json(new_error(), {}, "Empty error object, should this be valid?");

cmp_object_json(
    new_error(
        id     => 'foo',
        links  => new_link(uri => 'https://example.com'),
        status => '200',
        code   => '123',
        title  => 'Some error',
        detail => 'Some localized error',
        source => {
            pointer   => '/data',
            parameter => 'some params',
        },
        meta => "im very meta-ish",
    ),
    {
        id     => 'foo',
        links  => { self => 'https://example.com' },
        status => '200',
        code   => '123',
        title  => 'Some error',
        detail => 'Some localized error',
        source => {
            pointer   => '/data',
            parameter => 'some params',
        },
        meta => "im very meta-ish",

    },
    "All the items of a test object",
);


done_testing();
