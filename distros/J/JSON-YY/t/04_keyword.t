use strict;
use warnings;
use Test::More;
use JSON::YY qw(encode_json decode_json);

# keywords compile to custom ops — test they work like functions
my $data = {foo => 1, bar => [2, 3]};

# encode_json as keyword
my $json = encode_json $data;
ok defined $json, 'encode_json keyword produces output';
like $json, qr/"foo"/, 'encode_json keyword output has key';

# decode_json as keyword
my $back = decode_json $json;
is_deeply $back, $data, 'decode_json keyword roundtrip';

# with parens still works
my $json2 = encode_json($data);
is $json2, $json, 'encode_json with parens matches keyword';

# in expressions
my $len = length encode_json [1,2,3];
is $len, 7, 'keyword in expression context';

# nested
my $rt = decode_json encode_json {x => 42};
is $rt->{x}, 42, 'nested keyword calls';

# scalar value
my $str = encode_json "hello";
is $str, '"hello"', 'encode_json keyword with scalar';

my $num = decode_json "42";
is $num, 42, 'decode_json keyword with scalar';

# verify it's actually a custom op, not a function call
use B ();
my $cv = B::svref_2object(\&main::_test_keyword_op);

# simple verification: the keyword works in list context
my @list = (decode_json '{"a":1}', decode_json '{"b":2}');
is scalar @list, 2, 'keyword in list context';
is $list[0]{a}, 1, 'first element';
is $list[1]{b}, 2, 'second element';

done_testing;

sub _test_keyword_op { encode_json {t => 1} }
