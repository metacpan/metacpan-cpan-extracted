use Test::Lib;
use Test::JSON::API::v1;

my $object = new_resource();
cmp_object_json(
    $object,
    undef,
    "Empty resource shows undef data",
);

$object = new_resource(
    id => 1,
    type => 'example',
);

cmp_object_json(
    $object,
    {
        id   => 1,
        type => 'example',
    },
    ".. and minimal resource as data is also represented correctly",
);

$object = new_resource(
    id => 1,
    type => 'example',
    attributes => {
        title => 'bar',
    },
);

cmp_object_json(
    $object,
    {
        id   => 1,
        type => 'example',
        attributes => {
            title => 'bar'
        },
    },
    ".. and now contains attributes"
);

throws_ok(
    sub {
        new_resource(
            id         => 1,
            attributes => { 'title' => 'bar', },
        )->TO_JSON;
    },
    qr#^Unable to represent a valid data object, type is missing#,
    "Only ID given, croaking"
);

throws_ok(
    sub {
        new_resource(
            type => 'no idea',
            attributes => { 'title' => 'bar', },
        )->TO_JSON;
    },
    qr#^Unable to represent a valid data object, id is missing#,
    ".. and also croaking when only type is given",
);

done_testing;
