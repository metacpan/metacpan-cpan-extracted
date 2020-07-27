use Test::Lib;
use Test::JSON::API::v1;

my $data = new_resource(
    id         => 'someid',
    type       => 'testsuite',
    attributes => {
        foo     => 'bar',
        message => { hello => 'world' },
    },
    meta => new_meta(),
);
my $data2 = new_resource(
    id         => 'someid',
    type       => 'test',
    attributes => {
        foo     => 'bar',
        message => { hello => 'world' },
    },
    meta => new_meta(),
);


my $object = new_toplevel(data => $data);
$object->add_included($data);

cmp_object_json(
    $object,
    {
        data => {
            id         => 'someid',
            type       => 'testsuite',
            attributes => {
                foo     => 'bar',
                message => { hello => 'world' },
            },
            meta => {},
        },
        included => [
            {
                id         => 'someid',
                type       => 'testsuite',
                attributes => {
                    foo     => 'bar',
                    message => { hello => 'world' },
                },
                meta => {},
            }
        ]
    }
);

$object = new_toplevel(data => $data);

$object->add_included($data);
$object->add_data($data2);

my $json = JSON::XS->new->utf8(0)->convert_blessed;

done_testing;
