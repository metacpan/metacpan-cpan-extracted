use Test::Lib;
use Test::JSON::API::v1;

my $object = new_attribute();

$object->add_attribute('foo', 'bar');

cmp_object_json($object, { foo => 'bar' }, "Attribute serializes correctly");

$object->add_attribute('bar', 'baz');
$object->clear_attribute('foo');

cmp_object_json($object, { bar => 'baz' }, ".. and also after deletion");

foreach (qw(links relationships)) {
    throws_ok(
        sub {
            $object->set_attribute($_, "No you cannot");
        },
        qr/^Unable to use reserved keyword '$_'\!/,
        "Cannot set forbidden names for attributes: $_"
    );
    throws_ok(
        sub {
            $object->get_attribute($_);
        },
        qr/^Unable to use reserved keyword '$_'\!/,
        ".. nor can you retrieve them"
    );
}

$object = new_attribute(attributes => { links => 'foo' });
throws_ok(
    sub {
        cmp_object_json(
            $object,
            { links => 'foo' },
            "This test shall not pass"
        );
    },
    qr/^Unable to use reserved keyword 'links'\!/,
    ".. nor by directly setting them via constructing the object"
);




done_testing;
