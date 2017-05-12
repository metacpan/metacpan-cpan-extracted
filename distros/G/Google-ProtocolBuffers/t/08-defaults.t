use Test::More;
use strict;
use warnings;
use Google::ProtocolBuffers;

BEGIN{ $SIG{__DIE__} = \&Carp::confess; }

Google::ProtocolBuffers->parsefile(
    "google/protobuf/unittest.proto", 
    {include_dir => 't', create_accessors => 1 }
);

my $data = ProtobufUnittest::TestAllTypes->decode("\x{08}\x{00}");
is($data->{optional_int32}, 0, "optional_int32=0");
ok(defined $data->{optional_int32});
ok(exists $data->{optional_int32});

##optional    int32 default_int32    = 61 [default =  41    ];

## no value is set, accessor must return the default one
ok(!exists $data->{default_int32});
is($data->default_int32, 41);

## after setting a value, the value must be returned instead
$data->default_int32(0);
ok(exists $data->{default_int32});
is($data->{default_int32}, 0);
is($data->default_int32, 0);

## undef will not be serialized, so after decoding, a default value there will be.
## so, it make sense that after setting an undef, we get a default value
$data->default_int32(undef);
ok(!exists $data->{default_int32});
is($data->default_int32, 41);

## Data object may be get from Class::Accessor's new:
$data = ProtobufUnittest::TestAllTypes->new;
ok(!exists $data->{default_int32});
is($data->default_int32, 41);

$data = ProtobufUnittest::TestAllTypes->new({default_int32=>0});
ok(exists $data->{default_int32});
is($data->default_int32, 0);
is($data->{default_int32}, 0);

$data = ProtobufUnittest::TestAllTypes->new({default_int32=>undef});
ok(exists $data->{default_int32});
ok(!defined $data->{default_int32});
is($data->default_int32, 41);


##  optional    int64 default_int64    = 62 [default =  42    ];
is($data->default_int64, 42);

##  optional   uint32 default_uint32   = 63 [default =  43    ];
is($data->default_uint32, 43);

##  optional   uint64 default_uint64   = 64 [default =  44    ];
is($data->default_uint64, 44);

##  optional   sint32 default_sint32   = 65 [default = -45    ];
is($data->default_sint32, -45);

##  optional   sint64 default_sint64   = 66 [default =  46    ];
is($data->default_sint64, 46);

##  optional  fixed32 default_fixed32  = 67 [default =  47    ];
is($data->default_fixed32, 47);

##  optional  fixed64 default_fixed64  = 68 [default =  48    ];
is($data->default_fixed64, 48);

##  optional sfixed32 default_sfixed32 = 69 [default =  49    ];
is($data->default_fixed64, 48);

##  optional sfixed64 default_sfixed64 = 70 [default = -50    ];
is($data->default_sfixed64, -50);

##  optional    float default_float    = 71 [default =  51.5  ];
is($data->default_float, 51.5);

##  optional   double default_double   = 72 [default =  52e3  ];
cmp_ok($data->default_double, '==', 52000);

##  optional     bool default_bool     = 73 [default = true   ];
is($data->default_bool, 1);

##  optional   string default_string   = 74 [default = "hello"];
is($data->default_string, "hello");

##  optional    bytes default_bytes    = 75 [default = "world"];
is($data->default_bytes, "world");

##  optional NestedEnum  default_nested_enum  = 81 [default = BAR        ];
is($data->default_nested_enum, ProtobufUnittest::TestAllTypes::NestedEnum::BAR());

##  optional ForeignEnum default_foreign_enum = 82 [default = FOREIGN_BAR];
is($data->default_foreign_enum, ProtobufUnittest::ForeignEnum::FOREIGN_BAR());

##  optional protobuf_unittest_import.ImportEnum
##      default_import_enum = 83 [default = IMPORT_BAR];
is($data->default_import_enum, ProtobufUnittestImport::ImportEnum::IMPORT_BAR());

##  optional string default_string_piece = 84 [ctype=STRING_PIECE,default="abc"];
is($data->default_string_piece, "abc");

##  optional string default_cord = 85 [ctype=CORD,default="123"];
is($data->default_cord, "123");

##
## TestAllExtensions
##
$data = ProtobufUnittest::TestAllExtensions->new;
is($data->getExtension('default_int32_extension'), 41);
is($data->getExtension('default_string_extension'), "hello");
is($data->getExtension('default_nested_enum_extension'), ProtobufUnittest::TestAllTypes::NestedEnum::BAR());

##
## TestExtremeDefaultValues
## 
$data = ProtobufUnittest::TestExtremeDefaultValues->new;

##  optional bytes escaped_bytes = 1 [default = "\0\001\a\b\f\n\r\t\v\\\'\"\xfe"];
is($data->escaped_bytes, "\0\001\a\b\f\n\r\t\x{0b}\\\'\"\xfe");

##  optional uint32 large_uint32 = 2 [default = 0xFFFFFFFF];
is($data->large_uint32, 0xFFFFFFFF);

##  optional uint64 large_uint64 = 3 [default = 0xFFFFFFFFFFFFFFFF];
is($data->large_uint64, Math::BigInt->new("0xFFFFFFFFFFFFFFFF"));

##  optional  int32 small_int32  = 4 [default = -0x7FFFFFFF];
is($data->small_int32, -0x7FFFFFFF);

##  optional  int64 small_int64  = 5 [default = -0x7FFFFFFFFFFFFFFF];
is($data->small_int64, Math::BigInt->new("-0x7FFFFFFFFFFFFFFF"));

##  optional string utf8_string = 6 [default = "\341\210\264"];
is($data->utf8_string, "\341\210\264");


##
## Floating point default values:
##
Google::ProtocolBuffers->parse("
    message TestFP {
        required float f1   = 1  [ default =  1         ]; 
        required float f2   = 2  [ default = -1         ]; 
        required float f3   = 3  [ default =  1.25      ]; 
        required float f4   = 4  [ default =  1e3       ]; 
        required float f5   = 5  [ default =  1.25e3    ]; 
        required float f6   = 6  [ default =  1.25e-3   ]; 
        required float f7   = 7  [ default =  .25       ]; 
        required float f8   = 8  [ default = -.25e-2    ]; 
        required float f9   = 9  [ default = -.25e2     ]; 
        required float f10  = 10 [ default = 52.12e5    ];
        required float f11  = 11 [ default = -52.12e-5  ];
    }
");
$data = TestFP->decode( TestFP->encode({}) );

my $fpLimit = 0.0000001;
ok( abs($data->{f1} - 1)        <= $fpLimit, "Default floating point value f1" );
ok( abs($data->{f2} + 1)        <= $fpLimit, "Default floating point value f2" );
ok( abs($data->{f3} - 1.25)     <= $fpLimit, "Default floating point value f3" );
ok( abs($data->{f4} - 1e3)      <= $fpLimit, "Default floating point value f4" );
ok( abs($data->{f5} - 1.25e3)   <= $fpLimit, "Default floating point value f5" );
ok( abs($data->{f6} - 1.25e-3)  <= $fpLimit, "Default floating point value f6" );
ok( abs($data->{f7} - 0.25)     <= $fpLimit, "Default floating point value f7" );
ok( abs($data->{f8} + 0.25e-2)  <= $fpLimit, "Default floating point value f8" );
ok( abs($data->{f9} + 0.25e2)   <= $fpLimit, "Default floating point value f9" );
ok( abs($data->{f10} - 52.12e5)  <= $fpLimit, "Default floating point value f10");
ok( abs($data->{f11} + 52.12e-5) <= $fpLimit, "Default floating point value f11");

done_testing();