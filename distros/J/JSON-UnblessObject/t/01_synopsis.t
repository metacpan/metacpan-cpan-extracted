use Test2::V0;
use Test2::Require::Module 'Cpanel::JSON::XS';

use JSON::UnblessObject qw(unbless_object);

use Cpanel::JSON::XS ();
use Cpanel::JSON::XS::Type;
use Scalar::Util qw(blessed);

{
    package SomeEntity;
    sub new {
        my ($class, %args) = @_;
        return bless \%args, $class
    }
    sub a { shift->{a} }
    sub b { shift->{b} }
}

my $entity = SomeEntity->new(a => 123, b => 'HELLO');

is unbless_object($entity, { a => JSON_TYPE_INT }),
   { a => 123 };

is unbless_object($entity, { b => JSON_TYPE_STRING }),
   { b => 'HELLO' };

is unbless_object($entity, { a => JSON_TYPE_INT, b => JSON_TYPE_STRING }),
   { a => 123, b => 'HELLO' };



my $json = Cpanel::JSON::XS->new->canonical;
sub encode_json {
    my ($data, $spec) = @_;

    $data = unbless_object($data, $spec) if blessed $data;
    $json->encode($data, $spec)
}

is encode_json($entity, { a => JSON_TYPE_INT }),
   '{"a":123}';

is encode_json($entity, { b => JSON_TYPE_STRING }),
   '{"b":"HELLO"}';

is encode_json($entity, { a => JSON_TYPE_INT, b => JSON_TYPE_STRING }),
   '{"a":123,"b":"HELLO"}';

done_testing;
