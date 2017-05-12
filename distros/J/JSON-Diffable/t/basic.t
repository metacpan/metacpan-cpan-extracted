use strictures 1;
use Test::More;

use JSON::Diffable qw( encode_json decode_json );

my $data = { 
    foo => [23, { bar => 19, baz => undef }, 42],
    bar => { x => undef, y => 17, z => [3..5] },
    baz => [],
    qux => {},
};
my $json = encode_json($data);

is "$json\n", <<'ENDJSON', 'encode';
{
  "bar": {
    "x": null,
    "y": 17,
    "z": [
      3,
      4,
      5,
    ],
  },
  "baz": [
  ],
  "foo": [
    23,
    {
      "bar": 19,
      "baz": null,
    },
    42,
  ],
  "qux": {
  },
}
ENDJSON

is_deeply decode_json($json), $data, 'decode';

done_testing;
