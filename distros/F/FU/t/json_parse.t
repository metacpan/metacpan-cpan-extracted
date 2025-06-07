use v5.36;
use Test::More;
use FU::Util 'json_parse';
no warnings 'experimental::builtin';
use builtin 'is_bool', 'created_as_number', 'true', 'false';
use Config;

my @error = (
    '',
    'tru',
    'nul',
    'fals',
    'true,',

    '"',
    "\"\x00\"",
    '"\x"',
    '"\u',
    '" \u123',
    '"\\',
    '"\ud812"',
    '"\u123g"',
    '"\udc12"',
    '"\udc12\u1234"',
    "\"\x{110000}\"",

    '"\u0000"',
    '"\b"',
    '"\f"',
    '"\u007f"',

    '1.',
    '01',
    '1e',
    '1e+',
    '1x',
    '1e-',
    '--1',
    '+1',
    '0x1',
    '1..1',
    '1ee1',
    '1e1.1',

    ' [ ',
    '[,true]',
    '[true,]',
    '[,]',

    ' { ',
    '{1:2}',
    '{""}',
    '{"":}',
    '{"":1',
    '{"":1,}',
    '{,}',
    '{"":1,"":2}',
    '{"ë":1,"ë":1}',

    '[] x',
    '{}x',
);
for my $s (@error) {
    ok !eval { json_parse($s); 1 };
}

my $v;

ok !defined json_parse " null ";

$v = json_parse " true \t\r\n ";
ok is_bool $v;
ok $v;

$v = json_parse " false ";
ok is_bool $v;
ok !$v;

sub str($in, $exp) {
    utf8::encode(my $str = $in);
    my $out = json_parse($in);
    is $out, $exp, $str;
    ok utf8::is_utf8($out) || $out =~ /^[\x00-\x7f]*$/;
    $out = json_parse($str, utf8 => 1);
    is $out, $exp, $str;
    ok utf8::is_utf8($out) || $out =~ /^[\x00-\x7f]*$/;
}
str '""', '';
str '"hello, world"', 'hello, world';
str '"\u0099\u0234\u1234"', "\x{99}\x{234}\x{1234}";
str "\"\x{99}\x{234}\x{1234}\x{12345}\"", "\x{99}\x{234}\x{1234}\x{12345}";
str '"\/\"\\\\\t\n\r"', "/\"\\\x{09}\x{0a}\x{0d}";
str '"\uD83D\uDE03"', "\x{1F603}";

sub num($in, $exp=$in) {
    my $out = json_parse($in);
    is $out, $exp;
    ok created_as_number $out;
}
num 0;
num ' -0 ', 0;
num '-9223372036854775808';
num '9223372036854775807';
num '18446744073709551615';
if (!$Config{uselongdouble}) { # Behavior of longdouble is architecture-dependent
    num '-9223372036854775809', -9.22337203685478e+18;
    num '18446744073709551616', 1.84467440737096e+19;
}
num '1.234';
num '1e5', 100000;
num '1e+5', 100000;
num '1e-5', 0.00001;
num '2.5e-5', 0.000025;
num '2.5e5', 250000;
num '2.5E5', 250000;
num '-0.000000000000000000000000000000000000000000000000000000000000000000000000000001', -1e-78;

$v = json_parse ' [ ] ';
is ref $v, 'ARRAY';
is scalar @$v, 0;

$v = json_parse ' [ true , null , false ] ';
is ref $v, 'ARRAY';
is scalar @$v, 3;
ok $v->[0];
ok !defined $v->[1];
ok !$v->[2];

$v = json_parse ' [true,null,false] ';
is ref $v, 'ARRAY';
is scalar @$v, 3;
ok $v->[0];
ok !defined $v->[1];
ok !$v->[2];

$v = json_parse ' [ [] ] ';
is ref $v, 'ARRAY';
is scalar @$v, 1;
is ref $v->[0], 'ARRAY';
is scalar $v->[0]->@*, 0;

$v = json_parse '{}';
is ref $v, 'HASH';
is keys %$v, 0;

$v = json_parse '{"a":1}';
is ref $v, 'HASH';
is keys %$v, 1;
is $v->{a}, 1;

sub complete($s) {
    $v = json_parse $s;
    is ref $v, 'HASH';
    is keys %$v, 3;

    ok exists $v->{a};
    is ref $v->{a}, 'ARRAY';
    is scalar $v->{a}->@*, 5;
    ok created_as_number $v->{a}[0];
    is $v->{a}[0], 1;
    ok created_as_number $v->{a}[1];
    is $v->{a}[1], 0.1;
    ok is_bool $v->{a}[2];
    ok $v->{a}[2];
    ok !defined $v->{a}[3];
    is ref $v->{a}[4], 'HASH';
    is keys $v->{a}[4]->%*, 0;

    ok exists $v->{''};
    ok created_as_number $v->{''};
    is $v->{''}, 0;

    ok exists $v->{'ë'};
    is ref $v->{'ë'}, 'ARRAY';
    is scalar $v->{'ë'}->@*, 0;
}
complete '{"a":[1,0.1,true,null,{}],"":-0,"ë":[]}';
complete '  {
    "a"  :  [  1  ,  0.1  ,  true  ,  null  ,  {  }  ]  ,
    ""   :  -0  ,
    "ë"  :  [  ]
}  ';


# Test large inputs to cover some buffer handling special cases.
for (2000..2100, 4000..4200, 8100..8200, 12200..12300, 16300..16400) {
    my $s = 'a'x$_;
    is json_parse("\"$s\""), $s
}

ok !eval { json_parse '[[[[]]]]', max_depth => 4; 1 };
ok !eval { json_parse '{"":{"":{"":{"":1}}}}', max_depth => 4; 1 };

is json_parse('"\u0000\b\f\u007f"', allow_control => 1), "\x00\x08\x0c\x7f";

# 500 depth
{
    $v = json_parse('['x500 . ']'x500);
    my $i = 0;
    while (ref $v) { $v = $v->[0]; $i++ }
    is $i, 500;
}
{
    $v = json_parse('{"":'x500 . 1 . '}'x500);
    my $i = 0;
    while (ref $v) { $v = $v->{''}; $i++ }
    is $i, 500;
}


# offset / max_size
{
    my $off = 0;
    my $str = '0123-5.3e1"x"[]{}truefalse 1  '; # cursed
    is json_parse($str, offset => \$off), 0;
    is $off, 1;
    is json_parse($str, offset => \$off, max_size => 4), 123;
    is $off, 4;
    is json_parse($str, offset => \$off), -53;
    is $off, 10;
    is json_parse($str, offset => \$off), 'x';
    is $off, 13;
    is ref json_parse($str, offset => \$off), 'ARRAY';
    is $off, 15;
    is ref json_parse($str, offset => \$off), 'HASH';
    is $off, 17;
    ok json_parse($str, offset => \$off);
    is $off, 21;
    ok !json_parse($str, offset => \$off);
    is $off, 27;
    is json_parse($str, offset => \$off), 1;
    ok !defined $off;
    ok !eval { json_parse $str, offset => \$off; 1 };

    $off = 100;
    ok !eval { json_parse $str, offset => \$off; 1 };

    $off = 17;
    ok !eval { json_parse $str, offset => \$off, max_size => 3; 1 };

    is json_parse('"string"', max_size => 8), 'string';
    ok !eval { json_parse '"string"', max_size => 7 };
}

# Mutable hashes/arrays
my $d = json_parse('[true,false,null,{"a":true,"b":false,"c":null}]');
is_deeply $d, [true,false,undef,{a => true, b => false, c => undef}];
$_ = 1 for @{$d}[0,1,2], values $d->[3]->%*;
is_deeply $d, [1,1,1,{a => 1, b => 1, c => 1}];

done_testing;
