use strict;
use warnings;
use Test::More tests => 3;
use FindBin;
use lib "$FindBin::Bin/../lib";
use JQ::Lite;

my $jq = JQ::Lite->new;

my $object_json = '{"a":1,"b":2}';
my @object_values = $jq->run_query($object_json, '.[]');
is_deeply([ sort { $a <=> $b } @object_values ], [1, 2], '.[] iterates over object values');

my $nested_object_json = '{"users":{"u1":{"name":"Alice"},"u2":{"name":"Bob"}}}';
my @names = $jq->run_query($nested_object_json, '.users[] | .name');
is_deeply([ sort @names ], ['Alice', 'Bob'], 'key[] iterates over object values');

my $array_json = '[{"name":"Alice","age":30},{"name":"Bob","age":25}]';
my @names_from_array = $jq->run_query($array_json, '.[] | .name');
is_deeply(\@names_from_array, ['Alice', 'Bob'], '.[] still iterates over arrays');

