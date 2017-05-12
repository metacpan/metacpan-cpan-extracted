use Test::More tests => 168;
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

my $str;
##
## optional_int32
##
$str = ProtobufUnittest::TestAllTypes->encode({optional_int32 => 0});
is($str, "\x{08}\x{00}", "optional_int32=0");

$str = ProtobufUnittest::TestAllTypes->encode({optional_int32 => 1});
is($str, "\x{08}\x{01}", "optional_int32=1");

$str = ProtobufUnittest::TestAllTypes->encode({optional_int32 => -1});
is($str, "\x{08}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{01}", "optional_int32=-1");

$str = ProtobufUnittest::TestAllTypes->encode({optional_int32 => 2});
is($str, "\x{08}\x{02}", "optional_int32=2");

$str = ProtobufUnittest::TestAllTypes->encode({optional_int32 => 23424});
is($str, "\x{08}\x{80}\x{b7}\x{01}", "optional_int32=23424");

$str = ProtobufUnittest::TestAllTypes->encode({optional_int32 => 2147483647});
is($str, "\x{08}\x{ff}\x{ff}\x{ff}\x{ff}\x{07}", "optional_int32=2147483647");

$str = ProtobufUnittest::TestAllTypes->encode({optional_int32 => -2147483648});
is($str, "\x{08}\x{80}\x{80}\x{80}\x{80}\x{f8}\x{ff}\x{ff}\x{ff}\x{ff}\x{01}", "optional_int32=-2147483648");

##
## optional_int64
##
$str = ProtobufUnittest::TestAllTypes->encode({optional_int64 => 0});
is($str, "\x{10}\x{00}", "optional_int64=0");

$str = ProtobufUnittest::TestAllTypes->encode({optional_int64 => 1});
is($str, "\x{10}\x{01}", "optional_int64=1");

$str = ProtobufUnittest::TestAllTypes->encode({optional_int64 => -1});
is($str, "\x{10}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{01}", "optional_int64=-1");

$str = ProtobufUnittest::TestAllTypes->encode({optional_int64 => Math::BigInt->new("234234234234")});
is($str, "\x{10}\x{fa}\x{8a}\x{cb}\x{cb}\x{e8}\x{06}", "optional_int64=Math::BigInt->new(\\x{22}234234234234\\x{22})");

$str = ProtobufUnittest::TestAllTypes->encode({optional_int64 => Math::BigInt->new("9223372036854775807")});
is($str, "\x{10}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{7f}", "optional_int64=Math::BigInt->new(\\x{22}9223372036854775807\\x{22})");

$str = ProtobufUnittest::TestAllTypes->encode({optional_int64 => Math::BigInt->new("-9223372036854775808")});
is($str, "\x{10}\x{80}\x{80}\x{80}\x{80}\x{80}\x{80}\x{80}\x{80}\x{80}\x{01}", "optional_int64=Math::BigInt->new(\\x{22}-9223372036854775808\\x{22})");

##
## optional_uint32
##
$str = ProtobufUnittest::TestAllTypes->encode({optional_uint32 => 0});
is($str, "\x{18}\x{00}", "optional_uint32=0");

$str = ProtobufUnittest::TestAllTypes->encode({optional_uint32 => 1});
is($str, "\x{18}\x{01}", "optional_uint32=1");

$str = ProtobufUnittest::TestAllTypes->encode({optional_uint32 => 2});
is($str, "\x{18}\x{02}", "optional_uint32=2");

$str = ProtobufUnittest::TestAllTypes->encode({optional_uint32 => 2374234});
is($str, "\x{18}\x{da}\x{f4}\x{90}\x{01}", "optional_uint32=2374234");

$str = ProtobufUnittest::TestAllTypes->encode({optional_uint32 => 4294967295});
is($str, "\x{18}\x{ff}\x{ff}\x{ff}\x{ff}\x{0f}", "optional_uint32=4294967295");

##
## optional_uint64
##
$str = ProtobufUnittest::TestAllTypes->encode({optional_uint64 => 0});
is($str, "\x{20}\x{00}", "optional_uint64=0");

$str = ProtobufUnittest::TestAllTypes->encode({optional_uint64 => 1});
is($str, "\x{20}\x{01}", "optional_uint64=1");

$str = ProtobufUnittest::TestAllTypes->encode({optional_uint64 => 2});
is($str, "\x{20}\x{02}", "optional_uint64=2");

$str = ProtobufUnittest::TestAllTypes->encode({optional_uint64 => Math::BigInt->new("2336346474234")});
is($str, "\x{20}\x{fa}\x{8d}\x{e8}\x{c8}\x{ff}C", "optional_uint64=Math::BigInt->new(\\x{22}2336346474234\\x{22})");

$str = ProtobufUnittest::TestAllTypes->encode({optional_uint64 => Math::BigInt->new("18446744073709551615")});
is($str, "\x{20}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{01}", "optional_uint64=Math::BigInt->new(\\x{22}18446744073709551615\\x{22})");

##
## optional_sint32
##
$str = ProtobufUnittest::TestAllTypes->encode({optional_sint32 => 0});
is($str, "\x{28}\x{00}", "optional_sint32=0");

$str = ProtobufUnittest::TestAllTypes->encode({optional_sint32 => 1});
is($str, "\x{28}\x{02}", "optional_sint32=1");

$str = ProtobufUnittest::TestAllTypes->encode({optional_sint32 => -1});
is($str, "\x{28}\x{01}", "optional_sint32=-1");

$str = ProtobufUnittest::TestAllTypes->encode({optional_sint32 => 2});
is($str, "\x{28}\x{04}", "optional_sint32=2");

$str = ProtobufUnittest::TestAllTypes->encode({optional_sint32 => 237374});
is($str, "\x{28}\x{fc}\x{fc}\x{1c}", "optional_sint32=237374");

$str = ProtobufUnittest::TestAllTypes->encode({optional_sint32 => -4858558});
is($str, "\x{28}\x{fb}\x{8a}\x{d1}\x{04}", "optional_sint32=-4858558");

$str = ProtobufUnittest::TestAllTypes->encode({optional_sint32 => 2147483647});
is($str, "\x{28}\x{fe}\x{ff}\x{ff}\x{ff}\x{0f}", "optional_sint32=2147483647");

$str = ProtobufUnittest::TestAllTypes->encode({optional_sint32 => -2147483648});
is($str, "\x{28}\x{ff}\x{ff}\x{ff}\x{ff}\x{0f}", "optional_sint32=-2147483648");

##
## optional_sint64
##
$str = ProtobufUnittest::TestAllTypes->encode({optional_sint64 => 0});
is($str, "0\x{00}", "optional_sint64=0");

$str = ProtobufUnittest::TestAllTypes->encode({optional_sint64 => 1});
is($str, "0\x{02}", "optional_sint64=1");

$str = ProtobufUnittest::TestAllTypes->encode({optional_sint64 => -1});
is($str, "0\x{01}", "optional_sint64=-1");

$str = ProtobufUnittest::TestAllTypes->encode({optional_sint64 => 2});
is($str, "0\x{04}", "optional_sint64=2");

$str = ProtobufUnittest::TestAllTypes->encode({optional_sint64 => Math::BigInt->new("234234234234")});
is($str, "0\x{f4}\x{95}\x{96}\x{97}\x{d1}\x{0d}", "optional_sint64=Math::BigInt->new(\\x{22}234234234234\\x{22})");

$str = ProtobufUnittest::TestAllTypes->encode({optional_sint64 => Math::BigInt->new("9223372036854775807")});
is($str, "0\x{fe}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{01}", "optional_sint64=Math::BigInt->new(\\x{22}9223372036854775807\\x{22})");

$str = ProtobufUnittest::TestAllTypes->encode({optional_sint64 => Math::BigInt->new("-9223372036854775808")});
is($str, "0\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{01}", "optional_sint64=Math::BigInt->new(\\x{22}-9223372036854775808\\x{22})");

##
## optional_fixed32
##
$str = ProtobufUnittest::TestAllTypes->encode({optional_fixed32 => 0});
is($str, "\x{3d}\x{00}\x{00}\x{00}\x{00}", "optional_fixed32=0");

$str = ProtobufUnittest::TestAllTypes->encode({optional_fixed32 => 1});
is($str, "\x{3d}\x{01}\x{00}\x{00}\x{00}", "optional_fixed32=1");

$str = ProtobufUnittest::TestAllTypes->encode({optional_fixed32 => 2});
is($str, "\x{3d}\x{02}\x{00}\x{00}\x{00}", "optional_fixed32=2");

$str = ProtobufUnittest::TestAllTypes->encode({optional_fixed32 => 1453468424});
is($str, "\x{3d}\x{08}\x{2b}\x{a2}V", "optional_fixed32=1453468424");

$str = ProtobufUnittest::TestAllTypes->encode({optional_fixed32 => 2147483647});
is($str, "\x{3d}\x{ff}\x{ff}\x{ff}\x{7f}", "optional_fixed32=2147483647");

$str = ProtobufUnittest::TestAllTypes->encode({optional_fixed32 => 4294967295});
is($str, "\x{3d}\x{ff}\x{ff}\x{ff}\x{ff}", "optional_fixed32=4294967295");

##
## optional_fixed64
##
$str = ProtobufUnittest::TestAllTypes->encode({optional_fixed64 => 0});
is($str, "A\x{00}\x{00}\x{00}\x{00}\x{00}\x{00}\x{00}\x{00}", "optional_fixed64=0");

$str = ProtobufUnittest::TestAllTypes->encode({optional_fixed64 => 1});
is($str, "A\x{01}\x{00}\x{00}\x{00}\x{00}\x{00}\x{00}\x{00}", "optional_fixed64=1");

$str = ProtobufUnittest::TestAllTypes->encode({optional_fixed64 => 2});
is($str, "A\x{02}\x{00}\x{00}\x{00}\x{00}\x{00}\x{00}\x{00}", "optional_fixed64=2");

$str = ProtobufUnittest::TestAllTypes->encode({optional_fixed64 => Math::BigInt->new("234234234234")});
is($str, "Az\x{c5}r\x{89}6\x{00}\x{00}\x{00}", "optional_fixed64=Math::BigInt->new(\\x{22}234234234234\\x{22})");

$str = ProtobufUnittest::TestAllTypes->encode({optional_fixed64 => Math::BigInt->new("9223372036854775807")});
is($str, "A\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{7f}", "optional_fixed64=Math::BigInt->new(\\x{22}9223372036854775807\\x{22})");

$str = ProtobufUnittest::TestAllTypes->encode({optional_fixed64 => Math::BigInt->new("18446744073709551615")});
is($str, "A\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}", "optional_fixed64=Math::BigInt->new(\\x{22}18446744073709551615\\x{22})");

##
## optional_sfixed32
##
$str = ProtobufUnittest::TestAllTypes->encode({optional_sfixed32 => 0});
is($str, "M\x{00}\x{00}\x{00}\x{00}", "optional_sfixed32=0");

$str = ProtobufUnittest::TestAllTypes->encode({optional_sfixed32 => 1});
is($str, "M\x{01}\x{00}\x{00}\x{00}", "optional_sfixed32=1");

$str = ProtobufUnittest::TestAllTypes->encode({optional_sfixed32 => -1});
is($str, "M\x{ff}\x{ff}\x{ff}\x{ff}", "optional_sfixed32=-1");

$str = ProtobufUnittest::TestAllTypes->encode({optional_sfixed32 => 2});
is($str, "M\x{02}\x{00}\x{00}\x{00}", "optional_sfixed32=2");

$str = ProtobufUnittest::TestAllTypes->encode({optional_sfixed32 => 1130468424});
is($str, "MH\x{94}aC", "optional_sfixed32=1130468424");

$str = ProtobufUnittest::TestAllTypes->encode({optional_sfixed32 => 2147483647});
is($str, "M\x{ff}\x{ff}\x{ff}\x{7f}", "optional_sfixed32=2147483647");

$str = ProtobufUnittest::TestAllTypes->encode({optional_sfixed32 => -2147483648});
is($str, "M\x{00}\x{00}\x{00}\x{80}", "optional_sfixed32=-2147483648");

##
## optional_sfixed64
##
$str = ProtobufUnittest::TestAllTypes->encode({optional_sfixed64 => 0});
is($str, "Q\x{00}\x{00}\x{00}\x{00}\x{00}\x{00}\x{00}\x{00}", "optional_sfixed64=0");

$str = ProtobufUnittest::TestAllTypes->encode({optional_sfixed64 => 1});
is($str, "Q\x{01}\x{00}\x{00}\x{00}\x{00}\x{00}\x{00}\x{00}", "optional_sfixed64=1");

$str = ProtobufUnittest::TestAllTypes->encode({optional_sfixed64 => -1});
is($str, "Q\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}", "optional_sfixed64=-1");

$str = ProtobufUnittest::TestAllTypes->encode({optional_sfixed64 => 2});
is($str, "Q\x{02}\x{00}\x{00}\x{00}\x{00}\x{00}\x{00}\x{00}", "optional_sfixed64=2");

$str = ProtobufUnittest::TestAllTypes->encode({optional_sfixed64 => Math::BigInt->new("234234234234")});
is($str, "Qz\x{c5}r\x{89}6\x{00}\x{00}\x{00}", "optional_sfixed64=Math::BigInt->new(\\x{22}234234234234\\x{22})");

$str = ProtobufUnittest::TestAllTypes->encode({optional_sfixed64 => Math::BigInt->new("9223372036854775807")});
is($str, "Q\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{7f}", "optional_sfixed64=Math::BigInt->new(\\x{22}9223372036854775807\\x{22})");

$str = ProtobufUnittest::TestAllTypes->encode({optional_sfixed64 => Math::BigInt->new("-9223372036854775808")});
is($str, "Q\x{00}\x{00}\x{00}\x{00}\x{00}\x{00}\x{00}\x{80}", "optional_sfixed64=Math::BigInt->new(\\x{22}-9223372036854775808\\x{22})");

##
## optional_float
##
$str = ProtobufUnittest::TestAllTypes->encode({optional_float => 0});
is($str, "\x{5d}\x{00}\x{00}\x{00}\x{00}", "optional_float=0");

$str = ProtobufUnittest::TestAllTypes->encode({optional_float => 1});
is($str, "\x{5d}\x{00}\x{00}\x{80}\x{3f}", "optional_float=1");

$str = ProtobufUnittest::TestAllTypes->encode({optional_float => 0.5});
is($str, "\x{5d}\x{00}\x{00}\x{00}\x{3f}", "optional_float=0.5");

$str = ProtobufUnittest::TestAllTypes->encode({optional_float => -0.5});
is($str, "\x{5d}\x{00}\x{00}\x{00}\x{bf}", "optional_float=-0.5");

$str = ProtobufUnittest::TestAllTypes->encode({optional_float => 10000000000});
is($str, "\x{5d}\x{f9}\x{02}\x{15}P", "optional_float=10000000000");

$str = ProtobufUnittest::TestAllTypes->encode({optional_float => -1e+020});
is($str, "\x{5d}\x{ec}x\x{ad}\x{e0}", "optional_float=-1e+020");

$str = ProtobufUnittest::TestAllTypes->encode({optional_float => 1e-010});
is($str, "\x{5d}\x{ff}\x{e6}\x{db}\x{2e}", "optional_float=1e-010");

$str = ProtobufUnittest::TestAllTypes->encode({optional_float => -2e-020});
is($str, "\x{5d}\x{08}\x{e5}\x{bc}\x{9e}", "optional_float=-2e-020");

##
## optional_double
##
$str = ProtobufUnittest::TestAllTypes->encode({optional_double => 0});
is($str, "a\x{00}\x{00}\x{00}\x{00}\x{00}\x{00}\x{00}\x{00}", "optional_double=0");

$str = ProtobufUnittest::TestAllTypes->encode({optional_double => 1});
is($str, "a\x{00}\x{00}\x{00}\x{00}\x{00}\x{00}\x{f0}\x{3f}", "optional_double=1");

$str = ProtobufUnittest::TestAllTypes->encode({optional_double => 0.5});
is($str, "a\x{00}\x{00}\x{00}\x{00}\x{00}\x{00}\x{e0}\x{3f}", "optional_double=0.5");

$str = ProtobufUnittest::TestAllTypes->encode({optional_double => -0.5});
is($str, "a\x{00}\x{00}\x{00}\x{00}\x{00}\x{00}\x{e0}\x{bf}", "optional_double=-0.5");

$str = ProtobufUnittest::TestAllTypes->encode({optional_double => 10000000000});
is($str, "a\x{00}\x{00}\x{00}\x{20}_\x{a0}\x{02}B", "optional_double=10000000000");

$str = ProtobufUnittest::TestAllTypes->encode({optional_double => -1e+020});
is($str, "a\x{40}\x{8c}\x{b5}x\x{1d}\x{af}\x{15}\x{c4}", "optional_double=-1e+020");

$str = ProtobufUnittest::TestAllTypes->encode({optional_double => 1e-010});
is($str, "a\x{bb}\x{bd}\x{d7}\x{d9}\x{df}\x{7c}\x{db}\x{3d}", "optional_double=1e-010");

$str = ProtobufUnittest::TestAllTypes->encode({optional_double => -2e-020});
is($str, "a\x{23}B\x{92}\x{0c}\x{a1}\x{9c}\x{d7}\x{bb}", "optional_double=-2e-020");

$str = ProtobufUnittest::TestAllTypes->encode({optional_double => 1e-040});
is($str, "a\x{9c}Ww\x{27}\x{26}l\x{a1}7", "optional_double=1e-040");

$str = ProtobufUnittest::TestAllTypes->encode({optional_double => 1e+050});
is($str, "a\x{9a}d\x{7e}\x{c5}\x{0e}\x{1b}QJ", "optional_double=1e+050");

##
## optional_bool
##
$str = ProtobufUnittest::TestAllTypes->encode({optional_bool => 0});
is($str, "h\x{00}", "optional_bool=0");

$str = ProtobufUnittest::TestAllTypes->encode({optional_bool => 1});
is($str, "h\x{01}", "optional_bool=1");

##
## optional_string
##
$str = ProtobufUnittest::TestAllTypes->encode({optional_string => ""});
is($str, "r\x{00}", "optional_string=\\x{22}\\x{22}");

$str = ProtobufUnittest::TestAllTypes->encode({optional_string => "\x{09}"});
is($str, "r\x{01}\x{09}", "optional_string=\\x{22}\\x{5c}x{09}\\x{22}");

$str = ProtobufUnittest::TestAllTypes->encode({optional_string => "\x{0a}"});
is($str, "r\x{01}\x{0a}", "optional_string=\\x{22}\\x{5c}x{0a}\\x{22}");

$str = ProtobufUnittest::TestAllTypes->encode({optional_string => "\x{0d}"});
is($str, "r\x{01}\x{0d}", "optional_string=\\x{22}\\x{5c}x{0d}\\x{22}");

$str = ProtobufUnittest::TestAllTypes->encode({optional_string => "Hello\x{2c}\x{20}world"});
is($str, "r\x{0c}Hello\x{2c}\x{20}world", "optional_string=\\x{22}Hello\\x{5c}x{2c}\\x{5c}x{20}world\\x{22}");

##
## optional_bytes
##
$str = ProtobufUnittest::TestAllTypes->encode({optional_bytes => ""});
is($str, "z\x{00}", "optional_bytes=\\x{22}\\x{22}");

$str = ProtobufUnittest::TestAllTypes->encode({optional_bytes => "\x{00}"});
is($str, "z\x{01}\x{00}", "optional_bytes=\\x{22}\\x{5c}x{00}\\x{22}");

$str = ProtobufUnittest::TestAllTypes->encode({optional_bytes => "Hello\x{2c}\x{20}world"});
is($str, "z\x{0c}Hello\x{2c}\x{20}world", "optional_bytes=\\x{22}Hello\\x{5c}x{2c}\\x{5c}x{20}world\\x{22}");

$str = ProtobufUnittest::TestAllTypes->encode({optional_bytes => "\x{ff}\x{fe}\x{fd}"});
is($str, "z\x{03}\x{ff}\x{fe}\x{fd}", "optional_bytes=\\x{22}\\x{5c}x{ff}\\x{5c}x{fe}\\x{5c}x{fd}\\x{22}");

##
## OptionalGroup
##
$str = ProtobufUnittest::TestAllTypes->encode({OptionalGroup => {a => 0}});
is($str, "\x{83}\x{01}\x{88}\x{01}\x{00}\x{84}\x{01}", "OptionalGroup={a => 0}");

$str = ProtobufUnittest::TestAllTypes->encode({OptionalGroup => {a => -1}});
is($str, "\x{83}\x{01}\x{88}\x{01}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{01}\x{84}\x{01}", "OptionalGroup={a => -1}");

$str = ProtobufUnittest::TestAllTypes->encode({OptionalGroup => {a => 199}});
is($str, "\x{83}\x{01}\x{88}\x{01}\x{c7}\x{01}\x{84}\x{01}", "OptionalGroup={a => 199}");

##
## optional_nested_message
##
$str = ProtobufUnittest::TestAllTypes->encode({optional_nested_message => {bb => 0}});
is($str, "\x{92}\x{01}\x{02}\x{08}\x{00}", "optional_nested_message={bb => 0}");

$str = ProtobufUnittest::TestAllTypes->encode({optional_nested_message => {bb => 1}});
is($str, "\x{92}\x{01}\x{02}\x{08}\x{01}", "optional_nested_message={bb => 1}");

$str = ProtobufUnittest::TestAllTypes->encode({optional_nested_message => {bb => -1}});
is($str, "\x{92}\x{01}\x{0b}\x{08}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{01}", "optional_nested_message={bb => -1}");

##
## optional_foreign_message
##
$str = ProtobufUnittest::TestAllTypes->encode({optional_foreign_message => {c => 0}});
is($str, "\x{9a}\x{01}\x{02}\x{08}\x{00}", "optional_foreign_message={c => 0}");

$str = ProtobufUnittest::TestAllTypes->encode({optional_foreign_message => {c => -1}});
is($str, "\x{9a}\x{01}\x{0b}\x{08}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{01}", "optional_foreign_message={c => -1}");

$str = ProtobufUnittest::TestAllTypes->encode({optional_foreign_message => {c => 1}});
is($str, "\x{9a}\x{01}\x{02}\x{08}\x{01}", "optional_foreign_message={c => 1}");

##
## optional_import_message
##
$str = ProtobufUnittest::TestAllTypes->encode({optional_import_message => {d => 0}});
is($str, "\x{a2}\x{01}\x{02}\x{08}\x{00}", "optional_import_message={d => 0}");

$str = ProtobufUnittest::TestAllTypes->encode({optional_import_message => {d => -1}});
is($str, "\x{a2}\x{01}\x{0b}\x{08}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{01}", "optional_import_message={d => -1}");

$str = ProtobufUnittest::TestAllTypes->encode({optional_import_message => {d => 1}});
is($str, "\x{a2}\x{01}\x{02}\x{08}\x{01}", "optional_import_message={d => 1}");

##
## optional_nested_enum
##
$str = ProtobufUnittest::TestAllTypes->encode({optional_nested_enum => ProtobufUnittest::TestAllTypes::NestedEnum::FOO()});
is($str, "\x{a8}\x{01}\x{01}", "optional_nested_enum:FOO");

$str = ProtobufUnittest::TestAllTypes->encode({optional_nested_enum => ProtobufUnittest::TestAllTypes::NestedEnum::BAR()});
is($str, "\x{a8}\x{01}\x{02}", "optional_nested_enum:BAR");

$str = ProtobufUnittest::TestAllTypes->encode({optional_nested_enum => ProtobufUnittest::TestAllTypes::NestedEnum::BAZ()});
is($str, "\x{a8}\x{01}\x{03}", "optional_nested_enum:BAZ");

##
## optional_foreign_enum
##
$str = ProtobufUnittest::TestAllTypes->encode({optional_foreign_enum => ProtobufUnittest::ForeignEnum::FOREIGN_FOO()});
is($str, "\x{b0}\x{01}\x{04}", "optional_foreign_enum:FOREIGN_FOO");

$str = ProtobufUnittest::TestAllTypes->encode({optional_foreign_enum => ProtobufUnittest::ForeignEnum::FOREIGN_BAR()});
is($str, "\x{b0}\x{01}\x{05}", "optional_foreign_enum:FOREIGN_BAR");

$str = ProtobufUnittest::TestAllTypes->encode({optional_foreign_enum => ProtobufUnittest::ForeignEnum::FOREIGN_BAZ()});
is($str, "\x{b0}\x{01}\x{06}", "optional_foreign_enum:FOREIGN_BAZ");

##
## optional_import_enum
##
$str = ProtobufUnittest::TestAllTypes->encode({optional_import_enum => ProtobufUnittestImport::ImportEnum::IMPORT_FOO()});
is($str, "\x{b8}\x{01}\x{07}", "optional_import_enum:IMPORT_FOO");

$str = ProtobufUnittest::TestAllTypes->encode({optional_import_enum => ProtobufUnittestImport::ImportEnum::IMPORT_BAR()});
is($str, "\x{b8}\x{01}\x{08}", "optional_import_enum:IMPORT_BAR");

$str = ProtobufUnittest::TestAllTypes->encode({optional_import_enum => ProtobufUnittestImport::ImportEnum::IMPORT_BAZ()});
is($str, "\x{b8}\x{01}\x{09}", "optional_import_enum:IMPORT_BAZ");

##
## optional_string_piece
##
$str = ProtobufUnittest::TestAllTypes->encode({optional_string_piece => ""});
is($str, "\x{c2}\x{01}\x{00}", "optional_string_piece=\\x{22}\\x{22}");

$str = ProtobufUnittest::TestAllTypes->encode({optional_string_piece => "Hello\x{2c}\x{20}world"});
is($str, "\x{c2}\x{01}\x{0c}Hello\x{2c}\x{20}world", "optional_string_piece=\\x{22}Hello\\x{5c}x{2c}\\x{5c}x{20}world\\x{22}");

$str = ProtobufUnittest::TestAllTypes->encode({optional_string_piece => "\x{0d}\x{09}\x{0a}"});
is($str, "\x{c2}\x{01}\x{03}\x{0d}\x{09}\x{0a}", "optional_string_piece=\\x{22}\\x{5c}x{0d}\\x{5c}x{09}\\x{5c}x{0a}\\x{22}");

##
## optional_cord
##
$str = ProtobufUnittest::TestAllTypes->encode({optional_cord => ""});
is($str, "\x{ca}\x{01}\x{00}", "optional_cord=\\x{22}\\x{22}");

$str = ProtobufUnittest::TestAllTypes->encode({optional_cord => "Hello\x{2c}\x{20}world"});
is($str, "\x{ca}\x{01}\x{0c}Hello\x{2c}\x{20}world", "optional_cord=\\x{22}Hello\\x{5c}x{2c}\\x{5c}x{20}world\\x{22}");

$str = ProtobufUnittest::TestAllTypes->encode({optional_cord => "\x{0d}\x{09}\x{0a}"});
is($str, "\x{ca}\x{01}\x{03}\x{0d}\x{09}\x{0a}", "optional_cord=\\x{22}\\x{5c}x{0d}\\x{5c}x{09}\\x{5c}x{0a}\\x{22}");

##
## repeated_int32
##
$str = ProtobufUnittest::TestAllTypes->encode({repeated_int32 => 0});
is($str, "\x{f8}\x{01}\x{00}", "repeated_int32:0");

$str = ProtobufUnittest::TestAllTypes->encode({repeated_int32 => [0]});
is($str, "\x{f8}\x{01}\x{00}", "repeated_int32=[0]");

$str = ProtobufUnittest::TestAllTypes->encode({repeated_int32 => [0, -1, 1]});
is($str, "\x{f8}\x{01}\x{00}\x{f8}\x{01}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{01}\x{f8}\x{01}\x{01}", "repeated_int32=[0, -1, 1]");

##
## repeated_int64
##
$str = ProtobufUnittest::TestAllTypes->encode({repeated_int64 => [0]});
is($str, "\x{80}\x{02}\x{00}", "repeated_int64=[0]");

$str = ProtobufUnittest::TestAllTypes->encode({repeated_int64 => [0, -1, 1]});
is($str, "\x{80}\x{02}\x{00}\x{80}\x{02}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{01}\x{80}\x{02}\x{01}", "repeated_int64=[0, -1, 1]");

##
## repeated_uint32
##
$str = ProtobufUnittest::TestAllTypes->encode({repeated_uint32 => [0]});
is($str, "\x{88}\x{02}\x{00}", "repeated_uint32=[0]");

$str = ProtobufUnittest::TestAllTypes->encode({repeated_uint32 => [0, 2, 1]});
is($str, "\x{88}\x{02}\x{00}\x{88}\x{02}\x{02}\x{88}\x{02}\x{01}", "repeated_uint32=[0, 2, 1]");

##
## repeated_uint64
##
$str = ProtobufUnittest::TestAllTypes->encode({repeated_uint64 => [0]});
is($str, "\x{90}\x{02}\x{00}", "repeated_uint64=[0]");

$str = ProtobufUnittest::TestAllTypes->encode({repeated_uint64 => [0, 2, 1]});
is($str, "\x{90}\x{02}\x{00}\x{90}\x{02}\x{02}\x{90}\x{02}\x{01}", "repeated_uint64=[0, 2, 1]");

##
## repeated_sint32
##
$str = ProtobufUnittest::TestAllTypes->encode({repeated_sint32 => [0]});
is($str, "\x{98}\x{02}\x{00}", "repeated_sint32=[0]");

$str = ProtobufUnittest::TestAllTypes->encode({repeated_sint32 => [0, -1, 1]});
is($str, "\x{98}\x{02}\x{00}\x{98}\x{02}\x{01}\x{98}\x{02}\x{02}", "repeated_sint32=[0, -1, 1]");

##
## repeated_sint64
##
$str = ProtobufUnittest::TestAllTypes->encode({repeated_sint64 => [0]});
is($str, "\x{a0}\x{02}\x{00}", "repeated_sint64=[0]");

$str = ProtobufUnittest::TestAllTypes->encode({repeated_sint64 => [0, -1, 1]});
is($str, "\x{a0}\x{02}\x{00}\x{a0}\x{02}\x{01}\x{a0}\x{02}\x{02}", "repeated_sint64=[0, -1, 1]");

##
## repeated_fixed32
##
$str = ProtobufUnittest::TestAllTypes->encode({repeated_fixed32 => [0]});
is($str, "\x{ad}\x{02}\x{00}\x{00}\x{00}\x{00}", "repeated_fixed32=[0]");

$str = ProtobufUnittest::TestAllTypes->encode({repeated_fixed32 => [0, 3, 1]});
is($str, "\x{ad}\x{02}\x{00}\x{00}\x{00}\x{00}\x{ad}\x{02}\x{03}\x{00}\x{00}\x{00}\x{ad}\x{02}\x{01}\x{00}\x{00}\x{00}", "repeated_fixed32=[0, 3, 1]");

##
## repeated_fixed64
##
$str = ProtobufUnittest::TestAllTypes->encode({repeated_fixed64 => [0]});
is($str, "\x{b1}\x{02}\x{00}\x{00}\x{00}\x{00}\x{00}\x{00}\x{00}\x{00}", "repeated_fixed64=[0]");

$str = ProtobufUnittest::TestAllTypes->encode({repeated_fixed64 => [0, 3, 1]});
is($str, "\x{b1}\x{02}\x{00}\x{00}\x{00}\x{00}\x{00}\x{00}\x{00}\x{00}\x{b1}\x{02}\x{03}\x{00}\x{00}\x{00}\x{00}\x{00}\x{00}\x{00}\x{b1}\x{02}\x{01}\x{00}\x{00}\x{00}\x{00}\x{00}\x{00}\x{00}", "repeated_fixed64=[0, 3, 1]");

##
## repeated_sfixed32
##
$str = ProtobufUnittest::TestAllTypes->encode({repeated_sfixed32 => [0]});
is($str, "\x{bd}\x{02}\x{00}\x{00}\x{00}\x{00}", "repeated_sfixed32=[0]");

$str = ProtobufUnittest::TestAllTypes->encode({repeated_sfixed32 => [0, -1, 1]});
is($str, "\x{bd}\x{02}\x{00}\x{00}\x{00}\x{00}\x{bd}\x{02}\x{ff}\x{ff}\x{ff}\x{ff}\x{bd}\x{02}\x{01}\x{00}\x{00}\x{00}", "repeated_sfixed32=[0, -1, 1]");

##
## repeated_sfixed64
##
$str = ProtobufUnittest::TestAllTypes->encode({repeated_sfixed64 => [0]});
is($str, "\x{c1}\x{02}\x{00}\x{00}\x{00}\x{00}\x{00}\x{00}\x{00}\x{00}", "repeated_sfixed64=[0]");

$str = ProtobufUnittest::TestAllTypes->encode({repeated_sfixed64 => [0, -1, 1]});
is($str, "\x{c1}\x{02}\x{00}\x{00}\x{00}\x{00}\x{00}\x{00}\x{00}\x{00}\x{c1}\x{02}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{c1}\x{02}\x{01}\x{00}\x{00}\x{00}\x{00}\x{00}\x{00}\x{00}", "repeated_sfixed64=[0, -1, 1]");

##
## repeated_float
##
$str = ProtobufUnittest::TestAllTypes->encode({repeated_float => [0]});
is($str, "\x{cd}\x{02}\x{00}\x{00}\x{00}\x{00}", "repeated_float=[0]");

$str = ProtobufUnittest::TestAllTypes->encode({repeated_float => [0, -0.5, 10000000000]});
is($str, "\x{cd}\x{02}\x{00}\x{00}\x{00}\x{00}\x{cd}\x{02}\x{00}\x{00}\x{00}\x{bf}\x{cd}\x{02}\x{f9}\x{02}\x{15}P", "repeated_float=[0, -0.5, 10000000000]");

##
## repeated_double
##
$str = ProtobufUnittest::TestAllTypes->encode({repeated_double => [0]});
is($str, "\x{d1}\x{02}\x{00}\x{00}\x{00}\x{00}\x{00}\x{00}\x{00}\x{00}", "repeated_double=[0]");

$str = ProtobufUnittest::TestAllTypes->encode({repeated_double => [0, -0.5, 10000000000]});
is($str, "\x{d1}\x{02}\x{00}\x{00}\x{00}\x{00}\x{00}\x{00}\x{00}\x{00}\x{d1}\x{02}\x{00}\x{00}\x{00}\x{00}\x{00}\x{00}\x{e0}\x{bf}\x{d1}\x{02}\x{00}\x{00}\x{00}\x{20}_\x{a0}\x{02}B", "repeated_double=[0, -0.5, 10000000000]");

##
## repeated_bool
##
$str = ProtobufUnittest::TestAllTypes->encode({repeated_bool => [0]});
is($str, "\x{d8}\x{02}\x{00}", "repeated_bool=[0]");

$str = ProtobufUnittest::TestAllTypes->encode({repeated_bool => [0, 1, 1, 0]});
is($str, "\x{d8}\x{02}\x{00}\x{d8}\x{02}\x{01}\x{d8}\x{02}\x{01}\x{d8}\x{02}\x{00}", "repeated_bool=[0, 1, 1, 0]");

##
## repeated_string
##
$str = ProtobufUnittest::TestAllTypes->encode({repeated_string => [""]});
is($str, "\x{e2}\x{02}\x{00}", "repeated_string=[\\x{22}\\x{22}]");

$str = ProtobufUnittest::TestAllTypes->encode({repeated_string => ["hello"]});
is($str, "\x{e2}\x{02}\x{05}hello", "repeated_string=[\\x{22}hello\\x{22}]");

$str = ProtobufUnittest::TestAllTypes->encode({repeated_string => ["hello", "world"]});
is($str, "\x{e2}\x{02}\x{05}hello\x{e2}\x{02}\x{05}world", "repeated_string=[\\x{22}hello\\x{22}, \\x{22}world\\x{22}]");

##
## repeated_bytes
##
$str = ProtobufUnittest::TestAllTypes->encode({repeated_bytes => [""]});
is($str, "\x{ea}\x{02}\x{00}", "repeated_bytes=[\\x{22}\\x{22}]");

$str = ProtobufUnittest::TestAllTypes->encode({repeated_bytes => ["\x{00}"]});
is($str, "\x{ea}\x{02}\x{01}\x{00}", "repeated_bytes=[\\x{22}\\x{5c}x{00}\\x{22}]");

$str = ProtobufUnittest::TestAllTypes->encode({repeated_bytes => ["", "\x{00}", "\x{00}\x{00}"]});
is($str, "\x{ea}\x{02}\x{00}\x{ea}\x{02}\x{01}\x{00}\x{ea}\x{02}\x{02}\x{00}\x{00}", "repeated_bytes=[\\x{22}\\x{22}, \\x{22}\\x{5c}x{00}\\x{22}, \\x{22}\\x{5c}x{00}\\x{5c}x{00}\\x{22}]");

##
## RepeatedGroup
##
$str = ProtobufUnittest::TestAllTypes->encode({RepeatedGroup => [{a => 0}]});
is($str, "\x{f3}\x{02}\x{f8}\x{02}\x{00}\x{f4}\x{02}", "RepeatedGroup=[{a => 0}]");

$str = ProtobufUnittest::TestAllTypes->encode({RepeatedGroup => [{a => 0}, {a => -1}]});
is($str, "\x{f3}\x{02}\x{f8}\x{02}\x{00}\x{f4}\x{02}\x{f3}\x{02}\x{f8}\x{02}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{01}\x{f4}\x{02}", "RepeatedGroup=[{a => 0}, {a => -1}]");

##
## repeated_nested_message
##
$str = ProtobufUnittest::TestAllTypes->encode({repeated_nested_message => [{bb => 0}]});
is($str, "\x{82}\x{03}\x{02}\x{08}\x{00}", "repeated_nested_message=[{bb => 0}]");

$str = ProtobufUnittest::TestAllTypes->encode({repeated_nested_message => [{bb => 1}, {bb => 2}]});
is($str, "\x{82}\x{03}\x{02}\x{08}\x{01}\x{82}\x{03}\x{02}\x{08}\x{02}", "repeated_nested_message=[{bb => 1}, {bb => 2}]");

##
## repeated_foreign_message
##
$str = ProtobufUnittest::TestAllTypes->encode({repeated_foreign_message => [{c => 0}]});
is($str, "\x{8a}\x{03}\x{02}\x{08}\x{00}", "repeated_foreign_message=[{c => 0}]");

$str = ProtobufUnittest::TestAllTypes->encode({repeated_foreign_message => [{c => 0}, {c => -1}, {c => 1}]});
is($str, "\x{8a}\x{03}\x{02}\x{08}\x{00}\x{8a}\x{03}\x{0b}\x{08}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{01}\x{8a}\x{03}\x{02}\x{08}\x{01}", "repeated_foreign_message=[{c => 0}, {c => -1}, {c => 1}]");

##
## repeated_import_message
##
$str = ProtobufUnittest::TestAllTypes->encode({repeated_import_message => [{d => 0}]});
is($str, "\x{92}\x{03}\x{02}\x{08}\x{00}", "repeated_import_message=[{d => 0}]");

$str = ProtobufUnittest::TestAllTypes->encode({repeated_import_message => [{d => 0}, {d => -1}, {d => 1}]});
is($str, "\x{92}\x{03}\x{02}\x{08}\x{00}\x{92}\x{03}\x{0b}\x{08}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{01}\x{92}\x{03}\x{02}\x{08}\x{01}", "repeated_import_message=[{d => 0}, {d => -1}, {d => 1}]");

##
## repeated_nested_enum
##
$str = ProtobufUnittest::TestAllTypes->encode({repeated_nested_enum => [ProtobufUnittest::TestAllTypes::NestedEnum::FOO(), ProtobufUnittest::TestAllTypes::NestedEnum::BAR()]});
is($str, "\x{98}\x{03}\x{01}\x{98}\x{03}\x{02}", "repeated_nested_enum:[FOO, BAR]");

##
## repeated_string_piece
##
$str = ProtobufUnittest::TestAllTypes->encode({repeated_string_piece => [""]});
is($str, "\x{b2}\x{03}\x{00}", "repeated_string_piece=[\\x{22}\\x{22}]");

$str = ProtobufUnittest::TestAllTypes->encode({repeated_string_piece => ["a"]});
is($str, "\x{b2}\x{03}\x{01}a", "repeated_string_piece=[\\x{22}a\\x{22}]");

$str = ProtobufUnittest::TestAllTypes->encode({repeated_string_piece => ["a", "b", "\x{0d}\x{0a}"]});
is($str, "\x{b2}\x{03}\x{01}a\x{b2}\x{03}\x{01}b\x{b2}\x{03}\x{02}\x{0d}\x{0a}", "repeated_string_piece=[\\x{22}a\\x{22}, \\x{22}b\\x{22}, \\x{22}\\x{5c}x{0d}\\x{5c}x{0a}\\x{22}]");

##
## repeated_cord
##
$str = ProtobufUnittest::TestAllTypes->encode({repeated_cord => [""]});
is($str, "\x{ba}\x{03}\x{00}", "repeated_cord=[\\x{22}\\x{22}]");

$str = ProtobufUnittest::TestAllTypes->encode({repeated_cord => ["a"]});
is($str, "\x{ba}\x{03}\x{01}a", "repeated_cord=[\\x{22}a\\x{22}]");

$str = ProtobufUnittest::TestAllTypes->encode({repeated_cord => ["a", "b", "\x{0d}\x{0a}"]});
is($str, "\x{ba}\x{03}\x{01}a\x{ba}\x{03}\x{01}b\x{ba}\x{03}\x{02}\x{0d}\x{0a}", "repeated_cord=[\\x{22}a\\x{22}, \\x{22}b\\x{22}, \\x{22}\\x{5c}x{0d}\\x{5c}x{0a}\\x{22}]");

