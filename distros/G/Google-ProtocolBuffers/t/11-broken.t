use Test::More tests => 49;
use strict;
use warnings;
use Google::ProtocolBuffers;

BEGIN{
	$SIG{__DIE__} = \&Carp::confess;
}

Google::ProtocolBuffers->parsefile(
    "google/protobuf/unittest.proto", 
    { include_dir => 't' }
);

##
## optional_int32
##

## one byte off
ok(eval { ProtobufUnittest::TestAllTypes->decode("\x{08}\x{00}") });
ok(! eval { ProtobufUnittest::TestAllTypes->decode("\x{08}") });
ok(eval {ProtobufUnittest::TestAllTypes->decode("\x{08}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{01}")});
ok(!eval {ProtobufUnittest::TestAllTypes->decode("\x{08}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}")});
## varint too long
ok(!eval {ProtobufUnittest::TestAllTypes->decode("\x{08}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}")});


##
## optional_int64
##

ok(eval{ProtobufUnittest::TestAllTypes->decode("\x{10}\x{00}")});
ok(!eval{ProtobufUnittest::TestAllTypes->decode("\x{10}")});
ok(!eval{ProtobufUnittest::TestAllTypes->decode("\x{10}\x{ff}")});
ok(eval{ProtobufUnittest::TestAllTypes->decode("\x{10}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{01}")});
ok(!eval{ProtobufUnittest::TestAllTypes->decode("\x{10}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}")});
ok(!eval{ProtobufUnittest::TestAllTypes->decode("\x{10}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}")});

##
## optional_uint32
##
ok(eval{ProtobufUnittest::TestAllTypes->decode("\x{18}\x{00}")});
ok(!eval{ProtobufUnittest::TestAllTypes->decode("\x{18}")});
ok(!eval{ProtobufUnittest::TestAllTypes->decode("\x{18}\x{ff}")});

##
## optional_uint64
##
ok(eval{ProtobufUnittest::TestAllTypes->decode("\x{20}\x{00}")});
ok(!eval{ProtobufUnittest::TestAllTypes->decode("\x{20}")});
ok(!eval{ProtobufUnittest::TestAllTypes->decode("\x{20}\x{ff}")});

##
## optional_sint32
##
ok(eval{ProtobufUnittest::TestAllTypes->decode("\x{28}\x{00}")});
ok(!eval{ProtobufUnittest::TestAllTypes->decode("\x{28}")});
ok(!eval{ProtobufUnittest::TestAllTypes->decode("\x{28}\x{ff}")});

##
## optional_sint64
##
ok(eval{ProtobufUnittest::TestAllTypes->decode("0\x{00}")});
ok(!eval{ProtobufUnittest::TestAllTypes->decode("0")});
ok(!eval{ProtobufUnittest::TestAllTypes->decode("0\x{ff}")});

##
## optional_fixed32
##
ok(eval{ProtobufUnittest::TestAllTypes->decode("\x{3d}\x{00}\x{00}\x{00}\x{00}")});
ok(!eval{ProtobufUnittest::TestAllTypes->decode("\x{3d}\x{00}\x{00}\x{00}")});

##
## optional_fixed64
##
ok(eval{ProtobufUnittest::TestAllTypes->decode("A\x{00}\x{00}\x{00}\x{00}\x{00}\x{00}\x{00}\x{00}")});
ok(!eval{ProtobufUnittest::TestAllTypes->decode("A\x{00}\x{00}\x{00}\x{00}\x{00}\x{00}\x{00}")});

##
## optional_sfixed32
##
ok(eval{ProtobufUnittest::TestAllTypes->decode("M\x{00}\x{00}\x{00}\x{00}")});
ok(!eval{ProtobufUnittest::TestAllTypes->decode("M\x{00}\x{00}\x{00}")});

##
## optional_sfixed64
##
ok(eval{ProtobufUnittest::TestAllTypes->decode("Q\x{00}\x{00}\x{00}\x{00}\x{00}\x{00}\x{00}\x{00}")});
ok(!eval{ProtobufUnittest::TestAllTypes->decode("Q\x{00}\x{00}\x{00}\x{00}\x{00}\x{00}\x{00}")});

##
## optional_float
##
ok(eval{ProtobufUnittest::TestAllTypes->decode("\x{5d}\x{00}\x{00}\x{00}\x{00}")});
ok(!eval{ProtobufUnittest::TestAllTypes->decode("\x{5d}\x{00}\x{00}\x{00}")});

##
## optional_double
##
ok(eval{ProtobufUnittest::TestAllTypes->decode("a\x{00}\x{00}\x{00}\x{00}\x{00}\x{00}\x{00}\x{00}")});
ok(!eval{ProtobufUnittest::TestAllTypes->decode("a\x{00}\x{00}\x{00}\x{00}\x{00}\x{00}\x{00}")});

##
## optional_bool
##
ok(eval{ProtobufUnittest::TestAllTypes->decode("h\x{00}")});
ok(!eval{ProtobufUnittest::TestAllTypes->decode("h")});

##
## optional_string
##
ok(eval{ProtobufUnittest::TestAllTypes->decode("r\x{00}")});
ok(!eval{ProtobufUnittest::TestAllTypes->decode("r")});
ok(eval{ProtobufUnittest::TestAllTypes->decode("r\x{0c}Hello\x{2c}\x{20}world")});
ok(!eval{ProtobufUnittest::TestAllTypes->decode("r\x{0c}Hello\x{2c}\x{20}worl")});

##
## optional_bytes
##
ok(eval{ProtobufUnittest::TestAllTypes->decode("z\x{00}")});
ok(!eval{ProtobufUnittest::TestAllTypes->decode("z")});
ok(eval{ProtobufUnittest::TestAllTypes->decode("z\x{01}\x{00}")});
ok(!eval{ProtobufUnittest::TestAllTypes->decode("z\x{01}")});

##
## OptionalGroup
##
ok(eval{ProtobufUnittest::TestAllTypes->decode("\x{83}\x{01}\x{88}\x{01}\x{00}\x{84}\x{01}")});
ok(!eval{ProtobufUnittest::TestAllTypes->decode("\x{83}\x{01}\x{88}\x{01}\x{00}\x{84}")});

##
## optional_nested_message
##
ok(eval{ProtobufUnittest::TestAllTypes->decode("\x{92}\x{01}\x{02}\x{08}\x{00}")});
ok(!eval{ProtobufUnittest::TestAllTypes->decode("\x{92}\x{01}\x{02}\x{08}")});

