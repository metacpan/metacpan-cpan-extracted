use utf8;
use strict;
use warnings;
use Test::More qw(no_plan);
use lib 'lib';
use aliased 'Javonet::Core::Protocol::TypeDeserializer' => 'TypeDeserializer';
use aliased 'Javonet::Sdk::Core::StringEncodingMode' => 'StringEncodingMode', qw(get_string_encoding_mode);
use lib 't/dataSeed';
use ProtocolDataSeed;

sub test_typeDeserializer_string_JAVONET {
    my $value = TypeDeserializer->deserializeString(StringEncodingMode->get_string_encoding_mode("UTF8"), [@ProtocolDataSeed::JAVONET_string_serialized[6..$#ProtocolDataSeed::JAVONET_string_serialized]]);
    is($value, $ProtocolDataSeed::JAVONET_string_deserialized, 'TypeDeserializer deserializeString JAVONET test');
}

sub test_typeDeserializer_string_nonAsciiString {
    my $value = TypeDeserializer->deserializeString(StringEncodingMode->get_string_encoding_mode("UTF8"), [@ProtocolDataSeed::NonAscii_string_serialized[6..$#ProtocolDataSeed::NonAscii_string_serialized]]);
    is($value, "Ť¿ϻÐßĦŁ", 'TypeDeserializer deserializeString nonAsciiString test');
}

sub test_typeDeserializer_string_emptyString {
    my $value = TypeDeserializer->deserializeString(StringEncodingMode->get_string_encoding_mode("UTF8"), [@ProtocolDataSeed::empty_string_serialized[6..$#ProtocolDataSeed::empty_string_serialized]]);
    is($value, $ProtocolDataSeed::empty_string_deserialized, 'TypeDeserializer deserializeString emptyString test');
}

sub test_typeDeserializer_int {
    my $value = TypeDeserializer->deserializeInt([@ProtocolDataSeed::int_serialized[2..$#ProtocolDataSeed::int_serialized]]);
    is($value, $ProtocolDataSeed::int_deserialized, 'TypeDeserializer deserializeInt test');
}

sub test_typeDeserializer_bool {
    my $value = TypeDeserializer->deserializeBool($ProtocolDataSeed::bool_serialized[2]);
    is($value, $ProtocolDataSeed::bool_deserialized, 'TypeDeserializer deserializeBool test');
}

sub test_typeDeserializer_float {
    my $value = TypeDeserializer->deserializeFloat([@ProtocolDataSeed::float_serialized[2..$#ProtocolDataSeed::float_serialized]]);
    is(sprintf("%.4f", $value), sprintf("%.4f", $ProtocolDataSeed::float_deserialized), 'TypeDeserializer deserializeFloat test');
}

sub test_typeDeserializer_byte {
    my $value = TypeDeserializer->deserializeByte($ProtocolDataSeed::byte_serialized[2]);
    is($value, $ProtocolDataSeed::byte_deserialized, 'TypeDeserializer deserializeByte test');
}

sub test_typeDeserializer_char {
    my $value = TypeDeserializer->deserializeChar($ProtocolDataSeed::char_serialized[2]);
    is($value, $ProtocolDataSeed::char_deserialized, 'TypeDeserializer deserializeChar test');
}

sub test_typeDeserializer_longlong {
    my $value = TypeDeserializer->deserializeLongLong([@ProtocolDataSeed::longlong_serialized[2..$#ProtocolDataSeed::longlong_serialized]]);
    is($value, $ProtocolDataSeed::longlong_deserialized, 'TypeDeserializer deserializeLongLong test');
}

sub test_typeDeserializer_double {
    my $value = TypeDeserializer->deserializeDouble([@ProtocolDataSeed::double_serialized[2..$#ProtocolDataSeed::double_serialized]]);
    is($value, $ProtocolDataSeed::double_deserialized, 'TypeDeserializer deserializeDouble test');
}

sub test_typeDeserializer_ullong {
    my $value = TypeDeserializer->deserializeULongLong([@ProtocolDataSeed::ullong_serialized[2..$#ProtocolDataSeed::ullong_serialized]]);
    is($value, $ProtocolDataSeed::ullong_deserialized, 'TypeDeserializer deserializeULongLong test');
}

sub test_typeDeserializer_uint {
    my $value = TypeDeserializer->deserializeUInt([@ProtocolDataSeed::uint_serialized[2..$#ProtocolDataSeed::uint_serialized]]);
    is($value, $ProtocolDataSeed::uint_deserialized, 'TypeDeserializer deserializeUInt test');
}

sub test_typeDeserializer_undef {
    my $value = TypeDeserializer->deserializeUndef($ProtocolDataSeed::undef_serialized[2]);
    is($value, $ProtocolDataSeed::undef_deserialized, 'TypeDeserializer deserializeUndef test');
}

# Run tests
test_typeDeserializer_string_JAVONET();
test_typeDeserializer_string_nonAsciiString();
test_typeDeserializer_string_emptyString();
test_typeDeserializer_int();
test_typeDeserializer_bool();
test_typeDeserializer_float();
test_typeDeserializer_byte();
test_typeDeserializer_char();
test_typeDeserializer_longlong();
test_typeDeserializer_double();
test_typeDeserializer_ullong();
test_typeDeserializer_uint();
test_typeDeserializer_undef();

done_testing();