use v5.36;
use experimental 'builtin', 'for_list';
use builtin 'true', 'false';
use Test::More;
use Tie::Array;
use Tie::Hash;
use FU::Util 'json_format';
use Config;


sub MyToJSON::TO_JSON { [scalar @_, ref $_[0], ${$_[0]}] }
sub MyToJSONSelf::TO_JSON { $_[0] }

my @tests = (
    undef, 'null',
    true, 'true',
    false, 'false',
    (map +($_, $_),
        -1000..1000,
        12345, 123456, 1234567,
        98765, 987654, 9876543,
        -12345, -123456, -1234567,
        -98765, -987654, -9876543,
        -9223372036854775808,
        9223372036854775807,
        18446744073709551615,
    ),
    0.1, '0.1',
    0.000123, '0.000123',
    -1e100, '-1e+100',

    do { use utf8; (
        "\x01é\r\n\x1f💩", '"\u0001é\r\n\u001f💩"',
    )},

    "\x011\r\n\x8c", "\"\\u00011\\r\\n\x8c\"",
    "\xff\xff", "\"\xff\xff\"",
    "\x{1f4a9}", do { use utf8; '"💩"' },

    [], '[]',
    [0,1], '[0,1]',
    [true,'hi',-0.123, [undef]], '[true,"hi",-0.123,[null]]',
    do { tie my @a, 'Tie::StdArray'; @a = (1,2); \@a }, '[1,2]',

    {}, '{}',
    {'a',1}, '{"a":1}',
    do { tie my %h, 'Tie::StdHash'; %h = ('b',1); \%h }, '{"b":1}',
    do { tie my %h, 'MyOrderedHash', one => 1, two => undef, three => []; \%h }, '{"one":1,"two":null,"three":[]}',

    do { my $o = [true]; bless \$o, 'MyToJSON' }, '[1,"MyToJSON",[true]]',
    do { my $x = [true]; my $o = [bless \$x, 'MyToJSON']; bless \$o, 'MyToJSON' }, '[1,"MyToJSON",[[1,"MyToJSON",[true]]]]',

    # from http://e-choroba.eu/18-yapc
    $$, $$,
    ''.$$, '"'.$$.'"',
    do { my $x = 12; utf8::decode($x); $x }, '"12"',
    do { no warnings 'numeric'; my $x = '19a'; $x += 0; $x }, '19',
    1844674407370955161 / 10, $Config{uselongdouble} ? 184467440737095516 : '1.84467440737096e+17',
);

my @errors = (
    \2, qr/unable to format reference/,
    *STDOUT, qr/unable to format unknown value/,
    'NaN'+0, qr/unable to format floating point NaN or Inf as JSON/,
    'Inf'+0, qr/unable to format floating point NaN or Inf as JSON/,
    do { my $o = {}; bless $o, 'FU::Whatever' }, qr/unable to format 'FU::Whatever' object as JSON/,
    do { my $o = {}; bless $o, 'MyToJSONSelf' }, qr/MyToJSONSelf::TO_JSON method returned same object as was passed instead of a new one/,
);


for my($in, $exp) (@tests) {
    my $out = json_format $in;
    is $out, $exp;
    ok utf8::is_utf8($out);

    $out = json_format $in, utf8 => 1;
    utf8::encode(my $uexp = $exp);
    is $out, $uexp;
    ok !utf8::is_utf8($out);
}

for my ($in, $exp) (@errors) {
    eval { json_format $in };
    like $@, $exp;
}


is json_format({qw/a 1 b 2 c 3 d 4 d1 5 d11 6/, do { use utf8; qw/ü 7 月 8 💩 9/ }}, canonical => 1),
   do { use utf8; '{"a":"1","b":"2","c":"3","d":"4","d1":"5","d11":"6","ü":"7","月":"8","💩":"9"}' };

is json_format(
      { a => [], b => {}, c => { x => 1 }, d => { y => true, z => false }, e => [1,2,3] },
      canonical => 1, pretty => 1
    ), <<_;
{
   "a" : [],
   "b" : {},
   "c" : {
      "x" : 1
   },
   "d" : {
      "y" : true,
      "z" : false
   },
   "e" : [
      1,
      2,
      3
   ]
}
_


eval { json_format [[]], max_depth => 2 };
like $@, qr/max_depth exceeded while formatting JSON/;

eval { json_format 'hello world', max_size => 8 };
like $@, qr/maximum string length exceeded/;


# Test large strings to cover some buffer handling special cases.
for (2000..2100, 4000..4200, 8100..8200, 12200..12300, 16300..16400) {
    my $s = 'a'x$_;
    is json_format($s), "\"$s\"";
}

# 500 depth
{
    my $v = 1;
    $v = [$v] for (1..500);
    is json_format($v), '['x500 . 1 . ']'x500;
}
{
    my $v = 1;
    $v = {'',$v} for (1..500);
    is json_format($v), '{"":'x500 . 1 . '}'x500;
}


# http://e-choroba.eu/18-yapc slide 6

tie my $incs, 'MyIncrementer', 'Xa';
is json_format($incs), '"Xa"';
is json_format($incs), '"Xb"';
is json_format($incs), '"Xc"';

tie my $incu, 'MyIncrementer', 4;
is json_format($incu), 4;
is json_format($incu), 5;
is json_format($incu), 6;


done_testing;

package MyIncrementer;
use Tie::Scalar;
use parent -norequire => 'Tie::StdScalar';
sub TIESCALAR { my ($class, $val) = @_; bless \$val, $class }
sub FETCH { my $s = shift; $$s++ }


package MyOrderedHash;
sub TIEHASH { shift; bless [ [ map $_[$_*2], 0..$#_/2 ], +{@_}, 0 ], __PACKAGE__ };
sub FETCH { $_[0][1]{$_[1]} }
sub EXISTS { exists $_[0][1]{$_[1]} }
sub FIRSTKEY { $_[0][2] = 0; &NEXTKEY }
sub NEXTKEY { $_[0][0][ $_[0][2]++ ] }
sub SCALAR { scalar $_[0][0]->@* }
