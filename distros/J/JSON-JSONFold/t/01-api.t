use strict;
use warnings;
use Test::More;
use JSON::PP qw(decode_json);

use JSON::JSONFold qw(encode_json);

my $data = { a => [1, 2, 3], b => { c => 4 } };

my $out = encode_json($data);
ok($out, 'encode_json returns output');

my $decoded = decode_json($out);
is_deeply($decoded, $data, 'output is valid JSON and round-trips');

done_testing;
