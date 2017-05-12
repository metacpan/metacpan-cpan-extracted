use Test::More;
use strict;
use warnings;
use Google::ProtocolBuffers;
use Config qw/%Config/;

BEGIN {
    if ($Config{ivsize}<=4) {
        plan skip_all => "64-bit-only platforms test";
    } else {
        plan tests => 33;
    }
}


Google::ProtocolBuffers->parsefile(
    "google/protobuf/unittest.proto", 
    { include_dir => 't', create_accessors => 1 }
);

##
## Code below should not even compile properly on 32-bit platforms
##
no warnings 'portable';
my ($str, $data);

##
## Encoder
##

##
## optional_int32
##
$str = ProtobufUnittest::TestAllTypes->encode({optional_int32 => -1});
is($str, "\x{08}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{01}", "optional_int32=-1");

##
## optional_int64
##
$str = ProtobufUnittest::TestAllTypes->encode({optional_int64 => 234234234234});
is($str, "\x{10}\x{fa}\x{8a}\x{cb}\x{cb}\x{e8}\x{06}", "optional_int64=234234234234");

$str = ProtobufUnittest::TestAllTypes->encode({optional_int64 => 9223372036854775807});
is($str, "\x{10}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{7f}", "optional_int64=9223372036854775807");

$str = ProtobufUnittest::TestAllTypes->encode({optional_int64 => -9223372036854775808});
is($str, "\x{10}\x{80}\x{80}\x{80}\x{80}\x{80}\x{80}\x{80}\x{80}\x{80}\x{01}", "optional_int64=-9223372036854775808");

##
## optional_uint64
##
$str = ProtobufUnittest::TestAllTypes->encode({optional_uint64 => 2336346474234});
is($str, "\x{20}\x{fa}\x{8d}\x{e8}\x{c8}\x{ff}C", "optional_uint64=2336346474234");

$str = ProtobufUnittest::TestAllTypes->encode({optional_uint64 => 18446744073709551615});
is($str, "\x{20}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{01}", "optional_uint64=18446744073709551615");


##
## optional_sint64
##
$str = ProtobufUnittest::TestAllTypes->encode({optional_sint64 => 234234234234 });
is($str, "0\x{f4}\x{95}\x{96}\x{97}\x{d1}\x{0d}", "optional_sint64=234234234234");

$str = ProtobufUnittest::TestAllTypes->encode({optional_sint64 => 9223372036854775807 });
is($str, "0\x{fe}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{01}", "optional_sint64=9223372036854775807");

$str = ProtobufUnittest::TestAllTypes->encode({optional_sint64 => -9223372036854775808 });
is($str, "0\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{01}", "optional_sint64=-9223372036854775808");


##
## optional_fixed64
##
$str = ProtobufUnittest::TestAllTypes->encode({optional_fixed64 => 234234234234 });
is($str, "Az\x{c5}r\x{89}6\x{00}\x{00}\x{00}", "optional_fixed64=234234234234");

$str = ProtobufUnittest::TestAllTypes->encode({optional_fixed64 => 9223372036854775807 });
is($str, "A\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{7f}", "optional_fixed64=9223372036854775807");

$str = ProtobufUnittest::TestAllTypes->encode({optional_fixed64 => 18446744073709551615 });
is($str, "A\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}", "optional_fixed64=18446744073709551615");


##
## optional_sfixed64
##
$str = ProtobufUnittest::TestAllTypes->encode({optional_sfixed64 => 234234234234 });
is($str, "Qz\x{c5}r\x{89}6\x{00}\x{00}\x{00}", "optional_sfixed64=234234234234");

$str = ProtobufUnittest::TestAllTypes->encode({optional_sfixed64 => 9223372036854775807 });
is($str, "Q\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{7f}", "optional_sfixed64=9223372036854775807");

$str = ProtobufUnittest::TestAllTypes->encode({optional_sfixed64 => -9223372036854775808 });
is($str, "Q\x{00}\x{00}\x{00}\x{00}\x{00}\x{00}\x{00}\x{80}", "optional_sfixed64=-9223372036854775808");



##
## Decoder
## 

##
## optional_int32
##
$data = ProtobufUnittest::TestAllTypes->decode("\x{08}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{01}");
is($data->{optional_int32}, -1, "optional_int32=-1");
ok(!ref $data->{optional_int32}, "It's not a Math::BigInt");

##
## optional_int64
##
$data = ProtobufUnittest::TestAllTypes->decode("\x{10}\x{fa}\x{8a}\x{cb}\x{cb}\x{e8}\x{06}");
is($data->{optional_int64}, 234234234234, "optional_int64=234234234234");

$data = ProtobufUnittest::TestAllTypes->decode("\x{10}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{7f}");
is($data->{optional_int64}, 9223372036854775807, "optional_int64=9223372036854775807");

$data = ProtobufUnittest::TestAllTypes->decode("\x{10}\x{80}\x{80}\x{80}\x{80}\x{80}\x{80}\x{80}\x{80}\x{80}\x{01}");
is($data->{optional_int64}, -9223372036854775808, "optional_int64=-9223372036854775808");

##
## optional_uint64
##
$data = ProtobufUnittest::TestAllTypes->decode("\x{20}\x{fa}\x{8d}\x{e8}\x{c8}\x{ff}C");
is($data->{optional_uint64}, 2336346474234, "optional_uint64=2336346474234");

$data = ProtobufUnittest::TestAllTypes->decode("\x{20}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{01}");
is($data->{optional_uint64}, 18446744073709551615, "optional_uint64=18446744073709551615");


##
## optional_sint64
##
$data = ProtobufUnittest::TestAllTypes->decode("0\x{f4}\x{95}\x{96}\x{97}\x{d1}\x{0d}");
is($data->{optional_sint64}, 234234234234, "optional_sint64=234234234234");

$data = ProtobufUnittest::TestAllTypes->decode("0\x{fe}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{01}");
is($data->{optional_sint64}, 9223372036854775807, "optional_sint64=9223372036854775807");

$data = ProtobufUnittest::TestAllTypes->decode("0\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{01}");
is($data->{optional_sint64}, -9223372036854775808, "optional_sint64=-9223372036854775808");

##
## optional_fixed64
##
$data = ProtobufUnittest::TestAllTypes->decode("Az\x{c5}r\x{89}6\x{00}\x{00}\x{00}");
is($data->{optional_fixed64}, 234234234234, "optional_fixed64=234234234234");

$data = ProtobufUnittest::TestAllTypes->decode("A\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{7f}");
is($data->{optional_fixed64}, 9223372036854775807, "optional_fixed64=9223372036854775807");

$data = ProtobufUnittest::TestAllTypes->decode("A\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}");
is($data->{optional_fixed64}, 18446744073709551615, "optional_fixed64=18446744073709551615");

##
## optional_sfixed64
##
$data = ProtobufUnittest::TestAllTypes->decode("Qz\x{c5}r\x{89}6\x{00}\x{00}\x{00}");
is($data->{optional_sfixed64}, 234234234234, "optional_sfixed64=234234234234");

$data = ProtobufUnittest::TestAllTypes->decode("Q\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{7f}");
is($data->{optional_sfixed64}, 9223372036854775807, "optional_sfixed64=9223372036854775807");

$data = ProtobufUnittest::TestAllTypes->decode("Q\x{00}\x{00}\x{00}\x{00}\x{00}\x{00}\x{00}\x{80}");
is($data->{optional_sfixed64}, -9223372036854775808, "optional_sfixed64=-9223372036854775808");


##
## Default values
##
$data = ProtobufUnittest::TestExtremeDefaultValues->new;

##  optional uint64 large_uint64 = 3 [default = 0xFFFFFFFFFFFFFFFF];
is($data->large_uint64, 0xFFFFFFFFFFFFFFFF);

##  optional  int64 small_int64  = 5 [default = -0x7FFFFFFFFFFFFFFF];
is($data->small_int64, -0x7FFFFFFFFFFFFFFF);


