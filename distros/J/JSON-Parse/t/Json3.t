# This is a test for module Json3.

use warnings;
use strict;
use Test::More;
use JSON::Parse 'parse_json';

# Empty array.

my $p = parse_json ('[]');
ok ($p);
is (ref $p, 'ARRAY');
is (scalar @$p, 0);

# Empty hash.

my $o = parse_json ('{}');
ok ($o);
is (ref $o, 'HASH');
is (scalar keys %$o, 0);

# Array with one element.

my $a1 = parse_json ('[1]');
ok ($a1);
is (ref $a1, 'ARRAY');
is (scalar @$a1, 1);
is ($a1->[0], 1, "Got value 1");

# Array of integer numbers.

my $ai = parse_json ('[1,12,123,1234,12345,123456,1234567,12345678]');
ok ($ai);
is (ref $ai, 'ARRAY');
is (scalar @$ai, 8);
is_deeply ($ai, [1,12,123,1234,12345,123456,1234567,12345678]);

# Object with one pair of elements, a number as value.

my $o1 = parse_json ('{"a":1}');
ok ($o1);
is (ref $o1, 'HASH', "Got a hash");
is (scalar keys %$o1, 1);
ok (defined ($o1->{a}), "Key for 'a' is defined");
is ($o1->{a}, 1, "Value for 'a' is one");

# Object with one pair of elements, a string as value.

my $o2 = parse_json ('{"william":"shakespeare"}');
ok ($o2, "got a value");
is (ref $o2, 'HASH', "Got a hash");
is (scalar keys %$o2, 1, "Right no of keys");
ok (defined ($o2->{william}), "Got key william");
is ($o2->{william}, 'shakespeare', "Got right value for william");

# Object with a lot of whitespace.

my $w = <<EOF;

{
    "Kash"  :  "Munny",
    "Funky" :  "Gibbon"
}

EOF

my $ow = parse_json ($w);

ok ($ow);
is (ref $ow, 'HASH', "Got a hash");
is (scalar keys %$ow, 2);
ok (defined ($ow->{Kash}));
is ($ow->{Funky}, 'Gibbon');

# Array of floating point numbers

my $af = parse_json ('[0.001, 2.5e4, 3e-12]');
ok ($af);
is (ref $af, 'ARRAY');
is (scalar @$af, 3);
my $eps = 1e-3;
cmp_ok (abs ($af->[0] - 0.001), '<', 0.001 * $eps);
cmp_ok (abs ($af->[1] - 2.5e4), '<', 2.5e4 * $eps);
cmp_ok (abs ($af->[2] - 3e-12), '<', 3e-12 * $eps);

# Nested hash

my $on2 = parse_json ('{"gust":{"breeze":"wind"}}');
ok ($on2);
is (ref $on2, 'HASH');
is (scalar keys %$on2, 1);
is_deeply ($on2, {gust => {breeze => 'wind'}}, "Nested hash depth 2");

# Nested hash

my $on4 = parse_json ('{"gusty":{"breezy":{"monkey":{"flat":"hog"}},"miserable":"dawson"}}');
ok ($on4);
is (ref $on4, 'HASH');
is (scalar keys %$on4, 1);
is_deeply ($on4, {gusty => {breezy => {monkey => {flat => 'hog'}}, miserable => 'dawson'}},
	   "Nested hash depth 4");

# Array of things with escapes

my $escjson = '["\\t", "bubbles\n", "\u1234", "\nmonkey\n", "milky\tmoggy", "mocha\tmoggy\n"]';

my $aesc = parse_json ($escjson);

# Test one by one.

is ($aesc->[0], "\t");
is ($aesc->[1], "bubbles\n");
ok (utf8::is_utf8 ($aesc->[2]), "Unicode switched on for character escapes");
is ($aesc->[3], "\nmonkey\n");
is ($aesc->[4], "milky\tmoggy");
is ($aesc->[5], "mocha\tmoggy\n");

my $ao = parse_json ('[{"baby":"chops"}, {"starsky":"hutch"}]');
ok ($ao, "Got JSON");
is (ref $ao, 'ARRAY');
is_deeply ($ao, [{baby => 'chops'}, {starsky => 'hutch'}]);

# Literals

my $at = parse_json ('[true]');
ok ($at);
is ($at->[0], 1);

my $afalse = parse_json ('[false]');
ok ($afalse, "got false value");
is ($afalse->[0], '', "is empty string");
done_testing ();

# Local variables:
# mode: perl
# End:
