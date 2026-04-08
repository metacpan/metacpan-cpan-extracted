use strict;
use warnings;
use Test::More;
use JSON::YY qw(encode_json decode_json);

# functional API
is encode_json([1, 2, 3]), '[1,2,3]', 'encode array';
is encode_json({a => 1}), '{"a":1}', 'encode hash';
is_deeply decode_json('[1,2,3]'), [1, 2, 3], 'decode array';
is_deeply decode_json('{"a":1}'), {a => 1}, 'decode hash';

# roundtrip
my $data = {
    name   => "test",
    nums   => [1, 2.5, -3],
    nested => { a => { b => [undef, 1] } },
    flag   => \1,
    empty  => [],
};
my $json = encode_json($data);
my $back = decode_json($json);
is_deeply $back->{nums}, [1, 2.5, -3], 'roundtrip nums';
is $back->{name}, 'test', 'roundtrip string';
is_deeply $back->{empty}, [], 'roundtrip empty array';

# OO API
my $coder = JSON::YY->new->utf8;
my $enc = $coder->encode({x => 1});
is $enc, '{"x":1}', 'OO encode';
is_deeply $coder->decode($enc), {x => 1}, 'OO decode';

# pretty
my $pretty = JSON::YY->new->utf8->pretty->encode({a => 1});
like $pretty, qr/\n/, 'pretty has newlines';

# allow_nonref
my $nr = JSON::YY->new->utf8->allow_nonref;
is $nr->encode(42), '42', 'encode nonref int';
is $nr->encode("hello"), '"hello"', 'encode nonref string';
ok $nr->decode('true'), 'decode true';

# nonref disabled
my $strict = JSON::YY->new->utf8->allow_nonref(0);
eval { $strict->encode(42) };
like $@, qr/expected/, 'nonref disabled encode croaks';
eval { $strict->decode('42') };
like $@, qr/must be/, 'nonref disabled decode croaks';

# unicode
my $uni = JSON::YY->new->utf8;
my $unicode_str = "\x{263A}";  # smiley
my $j = $uni->encode({s => $unicode_str});
ok length($j) > 0, 'unicode encode';
my $d = $uni->decode($j);
is $d->{s}, $unicode_str, 'unicode roundtrip';

# depth limit
my $deep = JSON::YY->new->utf8->max_depth(2);
eval { $deep->encode({a => {b => {c => 1}}}) };
like $@, qr/depth/, 'max_depth exceeded';

# booleans
{
    my $bools = decode_json('[true,false,null]');
    is scalar @$bools, 3, 'decode booleans: 3 elements';
    ok $bools->[0], 'decode true is true';
    ok !$bools->[1], 'decode false is false';
    ok !defined $bools->[2], 'decode null is undef';
}

# blessed
{
    package Foo;
    sub new { bless {x => 1}, shift }
    sub TO_JSON { {x => $_[0]{x}} }
}
my $blessed = JSON::YY->new->utf8->convert_blessed;
is $blessed->encode(Foo->new), '{"x":1}', 'convert_blessed';

my $allow_b = JSON::YY->new->utf8->allow_blessed;
is $allow_b->encode(Foo->new), 'null', 'allow_blessed encodes null';

done_testing;
