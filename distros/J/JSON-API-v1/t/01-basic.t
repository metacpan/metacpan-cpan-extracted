use Test::Lib;
use Test::JSON::API::v1;

my $object = new_toplevel();

cmp_object_json(
    $object,
    {
        data => undef,
    },
    "Our JSON API object contains the minimal set of data"
);

$object = new_toplevel(data => new_resource());
cmp_object_json(
    $object,
    {
        data => undef,
    },
    ".. and an empty resource as data is also represented correctly",
);

my $resource = new_resource(
    id => 1,
    type => 'example',
);

$object = new_toplevel(data => $resource);
cmp_object_json(
    $object,
    {
        data => {
            id => 1,
            type => 'example',
        },
    },
    ".. and minimal resource as data is also represented correctly",
);

$resource = new_resource(
    id => 1,
    type => 'example',
    attributes => {
        title => 'bar',
    },
);

$object = new_toplevel(data => $resource);

cmp_object_json(
    $object,
    {
        data => {
            id   => 1,
            type => 'example',
            attributes => {
                title => 'bar'
            },
        },
    },
    ".. and now contains attributes"
);

$object = new_toplevel(
    data => $resource,
);

$object->add_error(new_error(id => 'foo'));

cmp_object_json(
    $object,
    {
        errors => [
            { id => 'foo' }
        ],
    },
    ".. we now return an error state",
);


throws_ok(
    sub {
        $object = new_toplevel(
            data   => [$resource, $resource],
            is_set => 0,
        );
    },
    qr/^You are entering a set of data and telling me you are not a set, this is incorrect!/,
    "Add a set without being a set fails",
);

$object = new_toplevel(
    data   => [$resource, $resource, new_resource(id => 2, type => 'test')],
);

my $resource_json = [
    {
        id         => 1,
        type       => 'example',
        attributes => { title => 'bar' },
    },
    {
        id   => 2,
        type => 'test',
    }
];

cmp_object_json(
    $object,
    { data => $resource_json },
    ".. but when we are a set, we show both"
);

$object->add_data(new_resource(id => 3, type => 'bar'));

push(@$resource_json, { id => 3, type => 'bar'});

cmp_object_json(
    $object,
    { data => $resource_json },
    ".. or three after adding one extra"
);

lives_ok(
    sub {
        $object = new_toplevel(data => $resource);
        $object->add_data($resource);
    },
    "We can add when we haven't explicitly said we were a set"
);

done_testing;
