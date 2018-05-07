use Test::More;
use JSON::Path;
use JSON;

my $object = from_json(<<'JSON');
{
    "elements": [
        { "id": 1 },
        { "id": 2 }
    ],
    "empty": null
}
JSON

my $path1 = JSON::Path->new('$.elements[*]');
my @arr   = $path1->values($object);
is_deeply \@arr, [ { id => 1 }, { id => 2 } ], 'multiple values in list context';
my $scal = $path1->values($object);
cmp_ok $scal, '==', 2, 'multiple values in scalar context';

my $path2 = JSON::Path->new('$.empty');
ok !!$path2->values($object), 'boolean check for existing null is true';

done_testing();
