use utf8;
use strict;
use warnings;
use Test::More qw(no_plan);
use lib 'lib';
use aliased 'Javonet::Core::Protocol::TypeSerializer' => 'TypeSerializer';
use lib 't/dataSeed';
use ProtocolDataSeed;

sub test_typeserializer_string_javonet {
    my @result = TypeSerializer->serializeString($ProtocolDataSeed::JAVONET_string_deserialized);
    is_deeply(\@result, \@ProtocolDataSeed::JAVONET_string_serialized, 'String serialization test');
}

sub test_typeserializer_string_nonasciistring {
    my @result = TypeSerializer->serializeString("Ť¿ϻÐßĦŁ");
    is_deeply(\@result, \@ProtocolDataSeed::NonAscii_string_serialized, 'String non-ascii serialization test');
}

sub test_typeserializer_emptystring {
    my $string = "";
    my @result = TypeSerializer->serializeString($string);
    is_deeply(\@result, \@ProtocolDataSeed::empty_string_serialized, 'Empty string serialization test');
}

sub test_typeserializer_int {
    my @result = TypeSerializer->serializeInt($ProtocolDataSeed::int_deserialized);
    is_deeply(\@result, \@ProtocolDataSeed::int_serialized, 'Int serialization test');
}

sub test_typeserializer_bool {
    my @result = TypeSerializer->serializeBool($ProtocolDataSeed::bool_deserialized);
    is_deeply(\@result, \@ProtocolDataSeed::bool_serialized, 'Bool serialization test');
}

sub test_typeserializer_float {
    my @result = TypeSerializer->serializeFloat($ProtocolDataSeed::float_deserialized);
    is_deeply(\@result, \@ProtocolDataSeed::float_serialized, 'Float serialization test');
}

sub test_typeserializer_byte {
    my @result = TypeSerializer->serializeByte($ProtocolDataSeed::byte_deserialized);
    is_deeply(\@result, \@ProtocolDataSeed::byte_serialized, 'Byte serialization test');
}

sub test_typeserializer_char {
    my @result = TypeSerializer->serializeChar($ProtocolDataSeed::char_deserialized);
    is_deeply(\@result, \@ProtocolDataSeed::char_serialized, 'Char serialization test');
}

sub test_typeserializer_longlong {
    my @result = TypeSerializer->serializeLongLong($ProtocolDataSeed::longlong_deserialized);
    is_deeply(\@result, \@ProtocolDataSeed::longlong_serialized, 'LongLong serialization test');
}

sub test_typeserializer_double {
    my @result = TypeSerializer->serializeDouble($ProtocolDataSeed::double_deserialized);
    is_deeply(\@result, \@ProtocolDataSeed::double_serialized, 'Double serialization test');
}

sub test_typeserializer_ullong {
    my @result = TypeSerializer->serializeUllong($ProtocolDataSeed::ullong_deserialized);
    is_deeply(\@result, \@ProtocolDataSeed::ullong_serialized, 'ULongLong serialization test');
}

sub test_typeserializer_uint {
    my @result = TypeSerializer->serializeUint($ProtocolDataSeed::uint_deserialized);
    is_deeply(\@result, \@ProtocolDataSeed::uint_serialized, 'UInt serialization test');
}

sub test_deserialize_undef {
    my @result = TypeSerializer->serializeUndef();
    is_deeply(\@result, \@ProtocolDataSeed::undef_serialized, 'Undef serialization test');
}

# Run tests
test_typeserializer_string_javonet();
test_typeserializer_string_nonasciistring();
test_typeserializer_emptystring();
test_typeserializer_int();
test_typeserializer_bool();
test_typeserializer_float();
test_typeserializer_byte();
test_typeserializer_char();
test_typeserializer_longlong();
test_typeserializer_double();
test_typeserializer_ullong();
test_typeserializer_uint();
test_deserialize_undef();

done_testing();