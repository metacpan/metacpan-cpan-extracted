use Test::Lib;
use Test::JSON::API::v1;

my $object = new_relationship();

throws_ok(
    sub {
        $object->TO_JSON
    },
    qr/Unable to continue, you don't have data, links or meta set/,
    "Unable to create an object without any required data",
);

$object = new_relationship(
    data => { type => 'example', id => 'foo' },
);

cmp_object_json(
    $object,
    { data => { type => 'example', id => 'foo' } },
    "Serializes correctly"
);

$object = new_relationship(
    links => new_link(
        uri     => 'https://example',
        related => new_link(uri => 'https://example.com/related'),
    )
);

cmp_object_json(
    $object,
    {
        links => {
            self    => 'https://example',
            related => { self => 'https://example.com/related' }
        }
    },
    ".. also works with links",
);

$object = new_relationship(
    meta => { foo => 'bar' },
);

cmp_object_json($object, { meta => { foo => 'bar', } }, ".. and with meta",);

done_testing;
