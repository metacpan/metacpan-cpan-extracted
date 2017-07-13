use strict;
use warnings;
use JSON::Path -all;

use JSON;
my $object = from_json(<<'JSON');
{
	"foo": {
        "bar" : 1,
        "baz" : 2
    }
}
JSON

my $jpath = JSON::Path->new('$.foo.bak');
$jpath->set( $object, 'Peculiar' );
use Data::Dumper;
print Dumper $jpath->value($object);
