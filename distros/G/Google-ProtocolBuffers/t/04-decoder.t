use Test::More tests => 169;
use strict;
use warnings;
use Google::ProtocolBuffers;
use Math::BigInt;

BEGIN{
	$SIG{__DIE__} = \&Carp::confess;
}

Google::ProtocolBuffers->parsefile(
    "google/protobuf/unittest.proto", 
    { include_dir => 't' }
);

my $data;
##
## optional_int32
##
$data = ProtobufUnittest::TestAllTypes->decode("\x{08}\x{00}");
is($data->{optional_int32}, 0, "optional_int32=0");

$data = ProtobufUnittest::TestAllTypes->decode("\x{08}\x{01}");
is($data->{optional_int32}, 1, "optional_int32=1");

$data = ProtobufUnittest::TestAllTypes->decode("\x{08}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{01}");
is($data->{optional_int32}, -1, "optional_int32=-1");

$data = ProtobufUnittest::TestAllTypes->decode("\x{08}\x{02}");
is($data->{optional_int32}, 2, "optional_int32=2");

$data = ProtobufUnittest::TestAllTypes->decode("\x{08}\x{80}\x{b7}\x{01}");
is($data->{optional_int32}, 23424, "optional_int32=23424");

$data = ProtobufUnittest::TestAllTypes->decode("\x{08}\x{ff}\x{ff}\x{ff}\x{ff}\x{07}");
is($data->{optional_int32}, 2147483647, "optional_int32=2147483647");

$data = ProtobufUnittest::TestAllTypes->decode("\x{08}\x{80}\x{80}\x{80}\x{80}\x{f8}\x{ff}\x{ff}\x{ff}\x{ff}\x{01}");
is($data->{optional_int32}, -2147483648, "optional_int32=-2147483648");

##
## optional_int64
##
$data = ProtobufUnittest::TestAllTypes->decode("\x{10}\x{00}");
is($data->{optional_int64}, 0, "optional_int64=0");

$data = ProtobufUnittest::TestAllTypes->decode("\x{10}\x{01}");
is($data->{optional_int64}, 1, "optional_int64=1");

$data = ProtobufUnittest::TestAllTypes->decode("\x{10}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{01}");
is($data->{optional_int64}, -1, "optional_int64=-1");

$data = ProtobufUnittest::TestAllTypes->decode("\x{10}\x{fa}\x{8a}\x{cb}\x{cb}\x{e8}\x{06}");
is($data->{optional_int64}, Math::BigInt->new("234234234234"), "optional_int64=Math::BigInt->new(\\x{22}234234234234\\x{22})");

$data = ProtobufUnittest::TestAllTypes->decode("\x{10}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{7f}");
is($data->{optional_int64}, Math::BigInt->new("9223372036854775807"), "optional_int64=Math::BigInt->new(\\x{22}9223372036854775807\\x{22})");

$data = ProtobufUnittest::TestAllTypes->decode("\x{10}\x{80}\x{80}\x{80}\x{80}\x{80}\x{80}\x{80}\x{80}\x{80}\x{01}");
is($data->{optional_int64}, Math::BigInt->new("-9223372036854775808"), "optional_int64=Math::BigInt->new(\\x{22}-9223372036854775808\\x{22})");

##
## optional_uint32
##
$data = ProtobufUnittest::TestAllTypes->decode("\x{18}\x{00}");
is($data->{optional_uint32}, 0, "optional_uint32=0");

$data = ProtobufUnittest::TestAllTypes->decode("\x{18}\x{01}");
is($data->{optional_uint32}, 1, "optional_uint32=1");

$data = ProtobufUnittest::TestAllTypes->decode("\x{18}\x{02}");
is($data->{optional_uint32}, 2, "optional_uint32=2");

$data = ProtobufUnittest::TestAllTypes->decode("\x{18}\x{da}\x{f4}\x{90}\x{01}");
is($data->{optional_uint32}, 2374234, "optional_uint32=2374234");

$data = ProtobufUnittest::TestAllTypes->decode("\x{18}\x{ff}\x{ff}\x{ff}\x{ff}\x{0f}");
is($data->{optional_uint32}, 4294967295, "optional_uint32=4294967295");

##
## optional_uint64
##
$data = ProtobufUnittest::TestAllTypes->decode("\x{20}\x{00}");
is($data->{optional_uint64}, 0, "optional_uint64=0");

$data = ProtobufUnittest::TestAllTypes->decode("\x{20}\x{01}");
is($data->{optional_uint64}, 1, "optional_uint64=1");

$data = ProtobufUnittest::TestAllTypes->decode("\x{20}\x{02}");
is($data->{optional_uint64}, 2, "optional_uint64=2");

$data = ProtobufUnittest::TestAllTypes->decode("\x{20}\x{fa}\x{8d}\x{e8}\x{c8}\x{ff}C");
is($data->{optional_uint64}, Math::BigInt->new("2336346474234"), "optional_uint64=Math::BigInt->new(\\x{22}2336346474234\\x{22})");

$data = ProtobufUnittest::TestAllTypes->decode("\x{20}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{01}");
is($data->{optional_uint64}, Math::BigInt->new("18446744073709551615"), "optional_uint64=Math::BigInt->new(\\x{22}18446744073709551615\\x{22})");

##
## optional_sint32
##
$data = ProtobufUnittest::TestAllTypes->decode("\x{28}\x{00}");
is($data->{optional_sint32}, 0, "optional_sint32=0");

$data = ProtobufUnittest::TestAllTypes->decode("\x{28}\x{02}");
is($data->{optional_sint32}, 1, "optional_sint32=1");

$data = ProtobufUnittest::TestAllTypes->decode("\x{28}\x{01}");
is($data->{optional_sint32}, -1, "optional_sint32=-1");

$data = ProtobufUnittest::TestAllTypes->decode("\x{28}\x{04}");
is($data->{optional_sint32}, 2, "optional_sint32=2");

$data = ProtobufUnittest::TestAllTypes->decode("\x{28}\x{fc}\x{fc}\x{1c}");
is($data->{optional_sint32}, 237374, "optional_sint32=237374");

$data = ProtobufUnittest::TestAllTypes->decode("\x{28}\x{fb}\x{8a}\x{d1}\x{04}");
is($data->{optional_sint32}, -4858558, "optional_sint32=-4858558");

$data = ProtobufUnittest::TestAllTypes->decode("\x{28}\x{fe}\x{ff}\x{ff}\x{ff}\x{0f}");
is($data->{optional_sint32}, 2147483647, "optional_sint32=2147483647");

$data = ProtobufUnittest::TestAllTypes->decode("\x{28}\x{ff}\x{ff}\x{ff}\x{ff}\x{0f}");
is($data->{optional_sint32}, -2147483648, "optional_sint32=-2147483648");

##
## optional_sint64
##
$data = ProtobufUnittest::TestAllTypes->decode("0\x{00}");
is($data->{optional_sint64}, 0, "optional_sint64=0");

$data = ProtobufUnittest::TestAllTypes->decode("0\x{02}");
is($data->{optional_sint64}, 1, "optional_sint64=1");

$data = ProtobufUnittest::TestAllTypes->decode("0\x{01}");
is($data->{optional_sint64}, -1, "optional_sint64=-1");

$data = ProtobufUnittest::TestAllTypes->decode("0\x{04}");
is($data->{optional_sint64}, 2, "optional_sint64=2");

$data = ProtobufUnittest::TestAllTypes->decode("0\x{f4}\x{95}\x{96}\x{97}\x{d1}\x{0d}");
is($data->{optional_sint64}, Math::BigInt->new("234234234234"), "optional_sint64=Math::BigInt->new(\\x{22}234234234234\\x{22})");

$data = ProtobufUnittest::TestAllTypes->decode("0\x{fe}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{01}");
is($data->{optional_sint64}, Math::BigInt->new("9223372036854775807"), "optional_sint64=Math::BigInt->new(\\x{22}9223372036854775807\\x{22})");

$data = ProtobufUnittest::TestAllTypes->decode("0\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{01}");
is($data->{optional_sint64}, Math::BigInt->new("-9223372036854775808"), "optional_sint64=Math::BigInt->new(\\x{22}-9223372036854775808\\x{22})");

##
## optional_fixed32
##
$data = ProtobufUnittest::TestAllTypes->decode("\x{3d}\x{00}\x{00}\x{00}\x{00}");
is($data->{optional_fixed32}, 0, "optional_fixed32=0");

$data = ProtobufUnittest::TestAllTypes->decode("\x{3d}\x{01}\x{00}\x{00}\x{00}");
is($data->{optional_fixed32}, 1, "optional_fixed32=1");

$data = ProtobufUnittest::TestAllTypes->decode("\x{3d}\x{02}\x{00}\x{00}\x{00}");
is($data->{optional_fixed32}, 2, "optional_fixed32=2");

$data = ProtobufUnittest::TestAllTypes->decode("\x{3d}\x{08}\x{2b}\x{a2}V");
is($data->{optional_fixed32}, 1453468424, "optional_fixed32=1453468424");

$data = ProtobufUnittest::TestAllTypes->decode("\x{3d}\x{ff}\x{ff}\x{ff}\x{7f}");
is($data->{optional_fixed32}, 2147483647, "optional_fixed32=2147483647");

$data = ProtobufUnittest::TestAllTypes->decode("\x{3d}\x{ff}\x{ff}\x{ff}\x{ff}");
is($data->{optional_fixed32}, 4294967295, "optional_fixed32=4294967295");

##
## optional_fixed64
##
$data = ProtobufUnittest::TestAllTypes->decode("A\x{00}\x{00}\x{00}\x{00}\x{00}\x{00}\x{00}\x{00}");
is($data->{optional_fixed64}, 0, "optional_fixed64=0");

$data = ProtobufUnittest::TestAllTypes->decode("A\x{01}\x{00}\x{00}\x{00}\x{00}\x{00}\x{00}\x{00}");
is($data->{optional_fixed64}, 1, "optional_fixed64=1");

$data = ProtobufUnittest::TestAllTypes->decode("A\x{02}\x{00}\x{00}\x{00}\x{00}\x{00}\x{00}\x{00}");
is($data->{optional_fixed64}, 2, "optional_fixed64=2");

$data = ProtobufUnittest::TestAllTypes->decode("Az\x{c5}r\x{89}6\x{00}\x{00}\x{00}");
is($data->{optional_fixed64}, Math::BigInt->new("234234234234"), "optional_fixed64=Math::BigInt->new(\\x{22}234234234234\\x{22})");

$data = ProtobufUnittest::TestAllTypes->decode("A\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{7f}");
is($data->{optional_fixed64}, Math::BigInt->new("9223372036854775807"), "optional_fixed64=Math::BigInt->new(\\x{22}9223372036854775807\\x{22})");

$data = ProtobufUnittest::TestAllTypes->decode("A\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}");
is($data->{optional_fixed64}, Math::BigInt->new("18446744073709551615"), "optional_fixed64=Math::BigInt->new(\\x{22}18446744073709551615\\x{22})");

##
## optional_sfixed32
##
$data = ProtobufUnittest::TestAllTypes->decode("M\x{00}\x{00}\x{00}\x{00}");
is($data->{optional_sfixed32}, 0, "optional_sfixed32=0");

$data = ProtobufUnittest::TestAllTypes->decode("M\x{01}\x{00}\x{00}\x{00}");
is($data->{optional_sfixed32}, 1, "optional_sfixed32=1");

$data = ProtobufUnittest::TestAllTypes->decode("M\x{ff}\x{ff}\x{ff}\x{ff}");
is($data->{optional_sfixed32}, -1, "optional_sfixed32=-1");

$data = ProtobufUnittest::TestAllTypes->decode("M\x{02}\x{00}\x{00}\x{00}");
is($data->{optional_sfixed32}, 2, "optional_sfixed32=2");

$data = ProtobufUnittest::TestAllTypes->decode("MH\x{94}aC");
is($data->{optional_sfixed32}, 1130468424, "optional_sfixed32=1130468424");

$data = ProtobufUnittest::TestAllTypes->decode("M\x{ff}\x{ff}\x{ff}\x{7f}");
is($data->{optional_sfixed32}, 2147483647, "optional_sfixed32=2147483647");

$data = ProtobufUnittest::TestAllTypes->decode("M\x{00}\x{00}\x{00}\x{80}");
is($data->{optional_sfixed32}, -2147483648, "optional_sfixed32=-2147483648");

##
## optional_sfixed64
##
$data = ProtobufUnittest::TestAllTypes->decode("Q\x{00}\x{00}\x{00}\x{00}\x{00}\x{00}\x{00}\x{00}");
is($data->{optional_sfixed64}, 0, "optional_sfixed64=0");

$data = ProtobufUnittest::TestAllTypes->decode("Q\x{01}\x{00}\x{00}\x{00}\x{00}\x{00}\x{00}\x{00}");
is($data->{optional_sfixed64}, 1, "optional_sfixed64=1");

$data = ProtobufUnittest::TestAllTypes->decode("Q\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}");
is($data->{optional_sfixed64}, -1, "optional_sfixed64=-1");

$data = ProtobufUnittest::TestAllTypes->decode("Q\x{02}\x{00}\x{00}\x{00}\x{00}\x{00}\x{00}\x{00}");
is($data->{optional_sfixed64}, 2, "optional_sfixed64=2");

$data = ProtobufUnittest::TestAllTypes->decode("Qz\x{c5}r\x{89}6\x{00}\x{00}\x{00}");
is($data->{optional_sfixed64}, Math::BigInt->new("234234234234"), "optional_sfixed64=Math::BigInt->new(\\x{22}234234234234\\x{22})");

$data = ProtobufUnittest::TestAllTypes->decode("Q\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{7f}");
is($data->{optional_sfixed64}, Math::BigInt->new("9223372036854775807"), "optional_sfixed64=Math::BigInt->new(\\x{22}9223372036854775807\\x{22})");

$data = ProtobufUnittest::TestAllTypes->decode("Q\x{00}\x{00}\x{00}\x{00}\x{00}\x{00}\x{00}\x{80}");
is($data->{optional_sfixed64}, Math::BigInt->new("-9223372036854775808"), "optional_sfixed64=Math::BigInt->new(\\x{22}-9223372036854775808\\x{22})");

##
## optional_float
##
$data = ProtobufUnittest::TestAllTypes->decode("\x{5d}\x{00}\x{00}\x{00}\x{00}");
cmp_ok($data->{optional_float}, '==', 0, "optional_float=0");

$data = ProtobufUnittest::TestAllTypes->decode("\x{5d}\x{00}\x{00}\x{80}\x{3f}");
ok(abs(1-$data->{optional_float}/(1))<0.0000001);

$data = ProtobufUnittest::TestAllTypes->decode("\x{5d}\x{00}\x{00}\x{00}\x{3f}");
ok(abs(1-$data->{optional_float}/(0.5))<0.0000001);

$data = ProtobufUnittest::TestAllTypes->decode("\x{5d}\x{00}\x{00}\x{00}\x{bf}");
ok(abs(1-$data->{optional_float}/(-0.5))<0.0000001);

$data = ProtobufUnittest::TestAllTypes->decode("\x{5d}\x{f9}\x{02}\x{15}P");
ok(abs(1-$data->{optional_float}/(10000000000))<0.0000001);

$data = ProtobufUnittest::TestAllTypes->decode("\x{5d}\x{ec}x\x{ad}\x{e0}");
ok(abs(1-$data->{optional_float}/(-1e+020))<0.0000001);

$data = ProtobufUnittest::TestAllTypes->decode("\x{5d}\x{ff}\x{e6}\x{db}\x{2e}");
ok(abs(1-$data->{optional_float}/(1e-010))<0.0000001);

$data = ProtobufUnittest::TestAllTypes->decode("\x{5d}\x{08}\x{e5}\x{bc}\x{9e}");
ok(abs(1-$data->{optional_float}/(-2e-020))<0.0000001);

##
## optional_double
##
$data = ProtobufUnittest::TestAllTypes->decode("a\x{00}\x{00}\x{00}\x{00}\x{00}\x{00}\x{00}\x{00}");
cmp_ok($data->{optional_double}, '==', 0, "optional_double=0");

$data = ProtobufUnittest::TestAllTypes->decode("a\x{00}\x{00}\x{00}\x{00}\x{00}\x{00}\x{f0}\x{3f}");
ok(abs(1-$data->{optional_double}/(1))<0.0000001);

$data = ProtobufUnittest::TestAllTypes->decode("a\x{00}\x{00}\x{00}\x{00}\x{00}\x{00}\x{e0}\x{3f}");
ok(abs(1-$data->{optional_double}/(0.5))<0.0000001);

$data = ProtobufUnittest::TestAllTypes->decode("a\x{00}\x{00}\x{00}\x{00}\x{00}\x{00}\x{e0}\x{bf}");
ok(abs(1-$data->{optional_double}/(-0.5))<0.0000001);

$data = ProtobufUnittest::TestAllTypes->decode("a\x{00}\x{00}\x{00}\x{20}_\x{a0}\x{02}B");
ok(abs(1-$data->{optional_double}/(10000000000))<0.0000001);

$data = ProtobufUnittest::TestAllTypes->decode("a\x{40}\x{8c}\x{b5}x\x{1d}\x{af}\x{15}\x{c4}");
ok(abs(1-$data->{optional_double}/(-1e+020))<0.0000001);

$data = ProtobufUnittest::TestAllTypes->decode("a\x{bb}\x{bd}\x{d7}\x{d9}\x{df}\x{7c}\x{db}\x{3d}");
ok(abs(1-$data->{optional_double}/(1e-010))<0.0000001);

$data = ProtobufUnittest::TestAllTypes->decode("a\x{23}B\x{92}\x{0c}\x{a1}\x{9c}\x{d7}\x{bb}");
ok(abs(1-$data->{optional_double}/(-2e-020))<0.0000001);

$data = ProtobufUnittest::TestAllTypes->decode("a\x{9c}Ww\x{27}\x{26}l\x{a1}7");
ok(abs(1-$data->{optional_double}/(1e-040))<0.0000001);

$data = ProtobufUnittest::TestAllTypes->decode("a\x{9a}d\x{7e}\x{c5}\x{0e}\x{1b}QJ");
ok(abs(1-$data->{optional_double}/(1e+050))<0.0000001);

##
## optional_bool
##
$data = ProtobufUnittest::TestAllTypes->decode("h\x{00}");
is($data->{optional_bool}, 0, "optional_bool=0");

$data = ProtobufUnittest::TestAllTypes->decode("h\x{01}");
is($data->{optional_bool}, 1, "optional_bool=1");

##
## optional_string
##
$data = ProtobufUnittest::TestAllTypes->decode("r\x{00}");
is($data->{optional_string}, "", "optional_string=\\x{22}\\x{22}");

$data = ProtobufUnittest::TestAllTypes->decode("r\x{01}\x{09}");
is($data->{optional_string}, "\x{09}", "optional_string=\\x{22}\\x{5c}x{09}\\x{22}");

$data = ProtobufUnittest::TestAllTypes->decode("r\x{01}\x{0a}");
is($data->{optional_string}, "\x{0a}", "optional_string=\\x{22}\\x{5c}x{0a}\\x{22}");

$data = ProtobufUnittest::TestAllTypes->decode("r\x{01}\x{0d}");
is($data->{optional_string}, "\x{0d}", "optional_string=\\x{22}\\x{5c}x{0d}\\x{22}");

$data = ProtobufUnittest::TestAllTypes->decode("r\x{0c}Hello\x{2c}\x{20}world");
is($data->{optional_string}, "Hello\x{2c}\x{20}world", "optional_string=\\x{22}Hello\\x{5c}x{2c}\\x{5c}x{20}world\\x{22}");

##
## optional_bytes
##
$data = ProtobufUnittest::TestAllTypes->decode("z\x{00}");
is($data->{optional_bytes}, "", "optional_bytes=\\x{22}\\x{22}");

$data = ProtobufUnittest::TestAllTypes->decode("z\x{01}\x{00}");
is($data->{optional_bytes}, "\x{00}", "optional_bytes=\\x{22}\\x{5c}x{00}\\x{22}");

$data = ProtobufUnittest::TestAllTypes->decode("z\x{0c}Hello\x{2c}\x{20}world");
is($data->{optional_bytes}, "Hello\x{2c}\x{20}world", "optional_bytes=\\x{22}Hello\\x{5c}x{2c}\\x{5c}x{20}world\\x{22}");

$data = ProtobufUnittest::TestAllTypes->decode("z\x{03}\x{ff}\x{fe}\x{fd}");
is($data->{optional_bytes}, "\x{ff}\x{fe}\x{fd}", "optional_bytes=\\x{22}\\x{5c}x{ff}\\x{5c}x{fe}\\x{5c}x{fd}\\x{22}");

##
## OptionalGroup
##
$data = ProtobufUnittest::TestAllTypes->decode("\x{83}\x{01}\x{88}\x{01}\x{00}\x{84}\x{01}");
is_deeply($data->{OptionalGroup}, {a => 0}, "OptionalGroup={a => 0}");

$data = ProtobufUnittest::TestAllTypes->decode("\x{83}\x{01}\x{88}\x{01}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{01}\x{84}\x{01}");
is_deeply($data->{OptionalGroup}, {a => -1}, "OptionalGroup={a => -1}");

$data = ProtobufUnittest::TestAllTypes->decode("\x{83}\x{01}\x{88}\x{01}\x{c7}\x{01}\x{84}\x{01}");
is_deeply($data->{OptionalGroup}, {a => 199}, "OptionalGroup={a => 199}");

##
## optional_nested_message
##
$data = ProtobufUnittest::TestAllTypes->decode("\x{92}\x{01}\x{02}\x{08}\x{00}");
is_deeply($data->{optional_nested_message}, {bb => 0}, "optional_nested_message={bb => 0}");

$data = ProtobufUnittest::TestAllTypes->decode("\x{92}\x{01}\x{02}\x{08}\x{01}");
is_deeply($data->{optional_nested_message}, {bb => 1}, "optional_nested_message={bb => 1}");

$data = ProtobufUnittest::TestAllTypes->decode("\x{92}\x{01}\x{0b}\x{08}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{01}");
is_deeply($data->{optional_nested_message}, {bb => -1}, "optional_nested_message={bb => -1}");

##
## optional_foreign_message
##
$data = ProtobufUnittest::TestAllTypes->decode("\x{9a}\x{01}\x{02}\x{08}\x{00}");
is_deeply($data->{optional_foreign_message}, {c => 0}, "optional_foreign_message={c => 0}");

$data = ProtobufUnittest::TestAllTypes->decode("\x{9a}\x{01}\x{0b}\x{08}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{01}");
is_deeply($data->{optional_foreign_message}, {c => -1}, "optional_foreign_message={c => -1}");

$data = ProtobufUnittest::TestAllTypes->decode("\x{9a}\x{01}\x{02}\x{08}\x{01}");
is_deeply($data->{optional_foreign_message}, {c => 1}, "optional_foreign_message={c => 1}");

##
## optional_import_message
##
$data = ProtobufUnittest::TestAllTypes->decode("\x{a2}\x{01}\x{02}\x{08}\x{00}");
is_deeply($data->{optional_import_message}, {d => 0}, "optional_import_message={d => 0}");

$data = ProtobufUnittest::TestAllTypes->decode("\x{a2}\x{01}\x{0b}\x{08}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{01}");
is_deeply($data->{optional_import_message}, {d => -1}, "optional_import_message={d => -1}");

$data = ProtobufUnittest::TestAllTypes->decode("\x{a2}\x{01}\x{02}\x{08}\x{01}");
is_deeply($data->{optional_import_message}, {d => 1}, "optional_import_message={d => 1}");

##
## optional_nested_enum
##
$data = ProtobufUnittest::TestAllTypes->decode("\x{a8}\x{01}\x{01}");
is($data->{optional_nested_enum}, ProtobufUnittest::TestAllTypes::NestedEnum::FOO(), "optional_nested_enum:FOO");

$data = ProtobufUnittest::TestAllTypes->decode("\x{a8}\x{01}\x{02}");
is($data->{optional_nested_enum}, ProtobufUnittest::TestAllTypes::NestedEnum::BAR(), "optional_nested_enum:BAR");

$data = ProtobufUnittest::TestAllTypes->decode("\x{a8}\x{01}\x{03}");
is($data->{optional_nested_enum}, ProtobufUnittest::TestAllTypes::NestedEnum::BAZ(), "optional_nested_enum:BAZ");

##
## optional_foreign_enum
##
$data = ProtobufUnittest::TestAllTypes->decode("\x{b0}\x{01}\x{04}");
is($data->{optional_foreign_enum}, ProtobufUnittest::ForeignEnum::FOREIGN_FOO(), "optional_foreign_enum:FOREIGN_FOO");

$data = ProtobufUnittest::TestAllTypes->decode("\x{b0}\x{01}\x{05}");
is($data->{optional_foreign_enum}, ProtobufUnittest::ForeignEnum::FOREIGN_BAR(), "optional_foreign_enum:FOREIGN_BAR");

$data = ProtobufUnittest::TestAllTypes->decode("\x{b0}\x{01}\x{06}");
is($data->{optional_foreign_enum}, ProtobufUnittest::ForeignEnum::FOREIGN_BAZ(), "optional_foreign_enum:FOREIGN_BAZ");

##
## optional_import_enum
##
$data = ProtobufUnittest::TestAllTypes->decode("\x{b8}\x{01}\x{07}");
is($data->{optional_import_enum}, ProtobufUnittestImport::ImportEnum::IMPORT_FOO(), "optional_import_enum:IMPORT_FOO");

$data = ProtobufUnittest::TestAllTypes->decode("\x{b8}\x{01}\x{08}");
is($data->{optional_import_enum}, ProtobufUnittestImport::ImportEnum::IMPORT_BAR(), "optional_import_enum:IMPORT_BAR");

$data = ProtobufUnittest::TestAllTypes->decode("\x{b8}\x{01}\x{09}");
is($data->{optional_import_enum}, ProtobufUnittestImport::ImportEnum::IMPORT_BAZ(), "optional_import_enum:IMPORT_BAZ");

##
## optional_string_piece
##
$data = ProtobufUnittest::TestAllTypes->decode("\x{c2}\x{01}\x{00}");
is($data->{optional_string_piece}, "", "optional_string_piece=\\x{22}\\x{22}");

$data = ProtobufUnittest::TestAllTypes->decode("\x{c2}\x{01}\x{0c}Hello\x{2c}\x{20}world");
is($data->{optional_string_piece}, "Hello\x{2c}\x{20}world", "optional_string_piece=\\x{22}Hello\\x{5c}x{2c}\\x{5c}x{20}world\\x{22}");

$data = ProtobufUnittest::TestAllTypes->decode("\x{c2}\x{01}\x{03}\x{0d}\x{09}\x{0a}");
is($data->{optional_string_piece}, "\x{0d}\x{09}\x{0a}", "optional_string_piece=\\x{22}\\x{5c}x{0d}\\x{5c}x{09}\\x{5c}x{0a}\\x{22}");

##
## optional_cord
##
$data = ProtobufUnittest::TestAllTypes->decode("\x{ca}\x{01}\x{00}");
is($data->{optional_cord}, "", "optional_cord=\\x{22}\\x{22}");

$data = ProtobufUnittest::TestAllTypes->decode("\x{ca}\x{01}\x{0c}Hello\x{2c}\x{20}world");
is($data->{optional_cord}, "Hello\x{2c}\x{20}world", "optional_cord=\\x{22}Hello\\x{5c}x{2c}\\x{5c}x{20}world\\x{22}");

$data = ProtobufUnittest::TestAllTypes->decode("\x{ca}\x{01}\x{03}\x{0d}\x{09}\x{0a}");
is($data->{optional_cord}, "\x{0d}\x{09}\x{0a}", "optional_cord=\\x{22}\\x{5c}x{0d}\\x{5c}x{09}\\x{5c}x{0a}\\x{22}");

##
## repeated_int32
##
$data = ProtobufUnittest::TestAllTypes->decode("\x{f8}\x{01}\x{00}");
is_deeply($data->{repeated_int32}, [0], "repeated_int32:0");

$data = ProtobufUnittest::TestAllTypes->decode("\x{f8}\x{01}\x{00}");
is_deeply($data->{repeated_int32}, [0], "repeated_int32=[0]");

$data = ProtobufUnittest::TestAllTypes->decode("\x{f8}\x{01}\x{00}\x{f8}\x{01}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{01}\x{f8}\x{01}\x{01}");
is_deeply($data->{repeated_int32}, [0, -1, 1], "repeated_int32=[0, -1, 1]");

##
## repeated_int64
##
$data = ProtobufUnittest::TestAllTypes->decode("\x{80}\x{02}\x{00}");
is_deeply($data->{repeated_int64}, [0], "repeated_int64=[0]");

$data = ProtobufUnittest::TestAllTypes->decode("\x{80}\x{02}\x{00}\x{80}\x{02}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{01}\x{80}\x{02}\x{01}");
is_deeply($data->{repeated_int64}, [0, -1, 1], "repeated_int64=[0, -1, 1]");

##
## repeated_uint32
##
$data = ProtobufUnittest::TestAllTypes->decode("\x{88}\x{02}\x{00}");
is_deeply($data->{repeated_uint32}, [0], "repeated_uint32=[0]");

$data = ProtobufUnittest::TestAllTypes->decode("\x{88}\x{02}\x{00}\x{88}\x{02}\x{02}\x{88}\x{02}\x{01}");
is_deeply($data->{repeated_uint32}, [0, 2, 1], "repeated_uint32=[0, 2, 1]");

##
## repeated_uint64
##
$data = ProtobufUnittest::TestAllTypes->decode("\x{90}\x{02}\x{00}");
is_deeply($data->{repeated_uint64}, [0], "repeated_uint64=[0]");

$data = ProtobufUnittest::TestAllTypes->decode("\x{90}\x{02}\x{00}\x{90}\x{02}\x{02}\x{90}\x{02}\x{01}");
is_deeply($data->{repeated_uint64}, [0, 2, 1], "repeated_uint64=[0, 2, 1]");

##
## repeated_sint32
##
$data = ProtobufUnittest::TestAllTypes->decode("\x{98}\x{02}\x{00}");
is_deeply($data->{repeated_sint32}, [0], "repeated_sint32=[0]");

$data = ProtobufUnittest::TestAllTypes->decode("\x{98}\x{02}\x{00}\x{98}\x{02}\x{01}\x{98}\x{02}\x{02}");
is_deeply($data->{repeated_sint32}, [0, -1, 1], "repeated_sint32=[0, -1, 1]");

##
## repeated_sint64
##
$data = ProtobufUnittest::TestAllTypes->decode("\x{a0}\x{02}\x{00}");
is_deeply($data->{repeated_sint64}, [0], "repeated_sint64=[0]");

$data = ProtobufUnittest::TestAllTypes->decode("\x{a0}\x{02}\x{00}\x{a0}\x{02}\x{01}\x{a0}\x{02}\x{02}");
is_deeply($data->{repeated_sint64}, [0, -1, 1], "repeated_sint64=[0, -1, 1]");

##
## repeated_fixed32
##
$data = ProtobufUnittest::TestAllTypes->decode("\x{ad}\x{02}\x{00}\x{00}\x{00}\x{00}");
is_deeply($data->{repeated_fixed32}, [0], "repeated_fixed32=[0]");

$data = ProtobufUnittest::TestAllTypes->decode("\x{ad}\x{02}\x{00}\x{00}\x{00}\x{00}\x{ad}\x{02}\x{03}\x{00}\x{00}\x{00}\x{ad}\x{02}\x{01}\x{00}\x{00}\x{00}");
is_deeply($data->{repeated_fixed32}, [0, 3, 1], "repeated_fixed32=[0, 3, 1]");

##
## repeated_fixed64
##
$data = ProtobufUnittest::TestAllTypes->decode("\x{b1}\x{02}\x{00}\x{00}\x{00}\x{00}\x{00}\x{00}\x{00}\x{00}");
is_deeply($data->{repeated_fixed64}, [0], "repeated_fixed64=[0]");

$data = ProtobufUnittest::TestAllTypes->decode("\x{b1}\x{02}\x{00}\x{00}\x{00}\x{00}\x{00}\x{00}\x{00}\x{00}\x{b1}\x{02}\x{03}\x{00}\x{00}\x{00}\x{00}\x{00}\x{00}\x{00}\x{b1}\x{02}\x{01}\x{00}\x{00}\x{00}\x{00}\x{00}\x{00}\x{00}");
is_deeply($data->{repeated_fixed64}, [0, 3, 1], "repeated_fixed64=[0, 3, 1]");

##
## repeated_sfixed32
##
$data = ProtobufUnittest::TestAllTypes->decode("\x{bd}\x{02}\x{00}\x{00}\x{00}\x{00}");
is_deeply($data->{repeated_sfixed32}, [0], "repeated_sfixed32=[0]");

$data = ProtobufUnittest::TestAllTypes->decode("\x{bd}\x{02}\x{00}\x{00}\x{00}\x{00}\x{bd}\x{02}\x{ff}\x{ff}\x{ff}\x{ff}\x{bd}\x{02}\x{01}\x{00}\x{00}\x{00}");
is_deeply($data->{repeated_sfixed32}, [0, -1, 1], "repeated_sfixed32=[0, -1, 1]");

##
## repeated_sfixed64
##
$data = ProtobufUnittest::TestAllTypes->decode("\x{c1}\x{02}\x{00}\x{00}\x{00}\x{00}\x{00}\x{00}\x{00}\x{00}");
is_deeply($data->{repeated_sfixed64}, [0], "repeated_sfixed64=[0]");

$data = ProtobufUnittest::TestAllTypes->decode("\x{c1}\x{02}\x{00}\x{00}\x{00}\x{00}\x{00}\x{00}\x{00}\x{00}\x{c1}\x{02}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{c1}\x{02}\x{01}\x{00}\x{00}\x{00}\x{00}\x{00}\x{00}\x{00}");
is_deeply($data->{repeated_sfixed64}, [0, -1, 1], "repeated_sfixed64=[0, -1, 1]");

##
## repeated_float
##
$data = ProtobufUnittest::TestAllTypes->decode("\x{cd}\x{02}\x{00}\x{00}\x{00}\x{00}");
is_deeply($data->{repeated_float}, [0], "repeated_float=[0]");

$data = ProtobufUnittest::TestAllTypes->decode("\x{cd}\x{02}\x{00}\x{00}\x{00}\x{00}\x{cd}\x{02}\x{00}\x{00}\x{00}\x{bf}\x{cd}\x{02}\x{f9}\x{02}\x{15}P");
is_deeply($data->{repeated_float}, [0, -0.5, 10000000000], "repeated_float=[0, -0.5, 10000000000]");

##
## repeated_double
##
$data = ProtobufUnittest::TestAllTypes->decode("\x{d1}\x{02}\x{00}\x{00}\x{00}\x{00}\x{00}\x{00}\x{00}\x{00}");
is_deeply($data->{repeated_double}, [0], "repeated_double=[0]");

$data = ProtobufUnittest::TestAllTypes->decode("\x{d1}\x{02}\x{00}\x{00}\x{00}\x{00}\x{00}\x{00}\x{00}\x{00}\x{d1}\x{02}\x{00}\x{00}\x{00}\x{00}\x{00}\x{00}\x{e0}\x{bf}\x{d1}\x{02}\x{00}\x{00}\x{00}\x{20}_\x{a0}\x{02}B");
is_deeply($data->{repeated_double}, [0, -0.5, 10000000000], "repeated_double=[0, -0.5, 10000000000]");

##
## repeated_bool
##
$data = ProtobufUnittest::TestAllTypes->decode("\x{d8}\x{02}\x{00}");
is_deeply($data->{repeated_bool}, [0], "repeated_bool=[0]");

$data = ProtobufUnittest::TestAllTypes->decode("\x{d8}\x{02}\x{00}\x{d8}\x{02}\x{01}\x{d8}\x{02}\x{01}\x{d8}\x{02}\x{00}");
is_deeply($data->{repeated_bool}, [0, 1, 1, 0], "repeated_bool=[0, 1, 1, 0]");

##
## repeated_string
##
$data = ProtobufUnittest::TestAllTypes->decode("\x{e2}\x{02}\x{00}");
is_deeply($data->{repeated_string}, [""], "repeated_string=[\\x{22}\\x{22}]");

$data = ProtobufUnittest::TestAllTypes->decode("\x{e2}\x{02}\x{05}hello");
is_deeply($data->{repeated_string}, ["hello"], "repeated_string=[\\x{22}hello\\x{22}]");

$data = ProtobufUnittest::TestAllTypes->decode("\x{e2}\x{02}\x{05}hello\x{e2}\x{02}\x{05}world");
is_deeply($data->{repeated_string}, ["hello", "world"], "repeated_string=[\\x{22}hello\\x{22}, \\x{22}world\\x{22}]");

##
## repeated_bytes
##
$data = ProtobufUnittest::TestAllTypes->decode("\x{ea}\x{02}\x{00}");
is_deeply($data->{repeated_bytes}, [""], "repeated_bytes=[\\x{22}\\x{22}]");

$data = ProtobufUnittest::TestAllTypes->decode("\x{ea}\x{02}\x{01}\x{00}");
is_deeply($data->{repeated_bytes}, ["\x{00}"], "repeated_bytes=[\\x{22}\\x{5c}x{00}\\x{22}]");

$data = ProtobufUnittest::TestAllTypes->decode("\x{ea}\x{02}\x{00}\x{ea}\x{02}\x{01}\x{00}\x{ea}\x{02}\x{02}\x{00}\x{00}");
is_deeply($data->{repeated_bytes}, ["", "\x{00}", "\x{00}\x{00}"], "repeated_bytes=[\\x{22}\\x{22}, \\x{22}\\x{5c}x{00}\\x{22}, \\x{22}\\x{5c}x{00}\\x{5c}x{00}\\x{22}]");

##
## RepeatedGroup
##
$data = ProtobufUnittest::TestAllTypes->decode("\x{f3}\x{02}\x{f8}\x{02}\x{00}\x{f4}\x{02}");
is_deeply($data->{RepeatedGroup}, [{a => 0}], "RepeatedGroup=[{a => 0}]");

$data = ProtobufUnittest::TestAllTypes->decode("\x{f3}\x{02}\x{f8}\x{02}\x{00}\x{f4}\x{02}\x{f3}\x{02}\x{f8}\x{02}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{01}\x{f4}\x{02}");
is_deeply($data->{RepeatedGroup}, [{a => 0}, {a => -1}], "RepeatedGroup=[{a => 0}, {a => -1}]");

##
## repeated_nested_message
##
$data = ProtobufUnittest::TestAllTypes->decode("\x{82}\x{03}\x{02}\x{08}\x{00}");
is_deeply($data->{repeated_nested_message}, [{bb => 0}], "repeated_nested_message=[{bb => 0}]");

$data = ProtobufUnittest::TestAllTypes->decode("\x{82}\x{03}\x{02}\x{08}\x{01}\x{82}\x{03}\x{02}\x{08}\x{02}");
is_deeply($data->{repeated_nested_message}, [{bb => 1}, {bb => 2}], "repeated_nested_message=[{bb => 1}, {bb => 2}]");

##
## repeated_foreign_message
##
$data = ProtobufUnittest::TestAllTypes->decode("\x{8a}\x{03}\x{02}\x{08}\x{00}");
is_deeply($data->{repeated_foreign_message}, [{c => 0}], "repeated_foreign_message=[{c => 0}]");

$data = ProtobufUnittest::TestAllTypes->decode("\x{8a}\x{03}\x{02}\x{08}\x{00}\x{8a}\x{03}\x{0b}\x{08}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{01}\x{8a}\x{03}\x{02}\x{08}\x{01}");
is_deeply($data->{repeated_foreign_message}, [{c => 0}, {c => -1}, {c => 1}], "repeated_foreign_message=[{c => 0}, {c => -1}, {c => 1}]");

##
## repeated_import_message
##
$data = ProtobufUnittest::TestAllTypes->decode("\x{92}\x{03}\x{02}\x{08}\x{00}");
is_deeply($data->{repeated_import_message}, [{d => 0}], "repeated_import_message=[{d => 0}]");

$data = ProtobufUnittest::TestAllTypes->decode("\x{92}\x{03}\x{02}\x{08}\x{00}\x{92}\x{03}\x{0b}\x{08}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{01}\x{92}\x{03}\x{02}\x{08}\x{01}");
is_deeply($data->{repeated_import_message}, [{d => 0}, {d => -1}, {d => 1}], "repeated_import_message=[{d => 0}, {d => -1}, {d => 1}]");

##
## repeated_nested_enum
##
$data = ProtobufUnittest::TestAllTypes->decode("\x{98}\x{03}\x{01}\x{98}\x{03}\x{02}");
is_deeply($data->{repeated_nested_enum}, [ProtobufUnittest::TestAllTypes::NestedEnum::FOO(), ProtobufUnittest::TestAllTypes::NestedEnum::BAR()], "repeated_nested_enum:[FOO, BAR]");

##
## repeated_string_piece
##
$data = ProtobufUnittest::TestAllTypes->decode("\x{b2}\x{03}\x{00}");
is_deeply($data->{repeated_string_piece}, [""], "repeated_string_piece=[\\x{22}\\x{22}]");

$data = ProtobufUnittest::TestAllTypes->decode("\x{b2}\x{03}\x{01}a");
is_deeply($data->{repeated_string_piece}, ["a"], "repeated_string_piece=[\\x{22}a\\x{22}]");

$data = ProtobufUnittest::TestAllTypes->decode("\x{b2}\x{03}\x{01}a\x{b2}\x{03}\x{01}b\x{b2}\x{03}\x{02}\x{0d}\x{0a}");
is_deeply($data->{repeated_string_piece}, ["a", "b", "\x{0d}\x{0a}"], "repeated_string_piece=[\\x{22}a\\x{22}, \\x{22}b\\x{22}, \\x{22}\\x{5c}x{0d}\\x{5c}x{0a}\\x{22}]");

##
## repeated_cord
##
$data = ProtobufUnittest::TestAllTypes->decode("\x{ba}\x{03}\x{00}");
is_deeply($data->{repeated_cord}, [""], "repeated_cord=[\\x{22}\\x{22}]");

$data = ProtobufUnittest::TestAllTypes->decode("\x{ba}\x{03}\x{01}a");
is_deeply($data->{repeated_cord}, ["a"], "repeated_cord=[\\x{22}a\\x{22}]");

$data = ProtobufUnittest::TestAllTypes->decode("\x{ba}\x{03}\x{01}a\x{ba}\x{03}\x{01}b\x{ba}\x{03}\x{02}\x{0d}\x{0a}");
is_deeply($data->{repeated_cord}, ["a", "b", "\x{0d}\x{0a}"], "repeated_cord=[\\x{22}a\\x{22}, \\x{22}b\\x{22}, \\x{22}\\x{5c}x{0d}\\x{5c}x{0a}\\x{22}]");


##
## repeated packed format
##
$data = ProtobufUnittest::TestAllTypes->decode("\x{fa}\x{01}\x{06}\x{03}\x{8e}\x{02}\x{9e}\x{a7}\x{05}\x{b2}\x{03}\x{01}a");
is_deeply($data, { repeated_int32 => [3, 270, 86942], repeated_string_piece=>["a"]}, "repeated_int32:packed_format");

