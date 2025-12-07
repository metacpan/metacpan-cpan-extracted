package Javonet::Core::Protocol::TypeDeserializer;
use strict;
use warnings;
use Encode;
use lib 'lib';

use Exporter qw(import);
our @EXPORT = qw(
    deserializeString
    deserializeInt
    deserializeBool
    deserializeFloat
    deserializeByte
    deserializeChar
    deserializeLongLong
    deserializeDouble
    deserializeULongLong
    deserializeUInt
    deserializeUndef
);

sub deserializeString {
    my ($class, $string_encoding_mode, $acc_ref) = @_;
    my @string_array = @$acc_ref;
    my $string_array_joined = join '', map chr, @string_array;
    my $decoded_string = Encode::decode("utf8", $string_array_joined);
    return $decoded_string;
}

sub deserializeInt {
    my ($class, $acc_ref) = @_;
    my @int_array = @$acc_ref;
    my $decoded_int = unpack "i", pack "C4",  @int_array;
    return $decoded_int;
}

sub deserializeBool {
    my ($class, $boolean_value) = @_;
    return $boolean_value;
}

sub deserializeFloat {
    my ($class, $acc_ref) = @_;
    my @float_array = @$acc_ref;
    my $decoded_float = unpack "f", pack "C4",  @float_array;
    return $decoded_float;
}

sub deserializeByte {
    my ($class, $acc_ref) = @_;
    my @byte_array = $acc_ref;
    my $decoded_byte = unpack "C", pack "C",  @byte_array;
    return $decoded_byte;
}

sub deserializeChar {
    my ($class, $acc_ref) = @_;
    my @char_array = $acc_ref;
    my $decoded_char = unpack "C", pack "C",  @char_array;
    return $decoded_char;
}

sub deserializeLongLong {
    my ($class, $acc_ref) = @_;
    my @longlong_array = @$acc_ref;
    my $decoded_longlong = unpack "q", pack "C8",  @longlong_array;
    return $decoded_longlong;
}

sub deserializeDouble {
    my ($class, $acc_ref) = @_;
    my @double_array = @$acc_ref;
    my $decoded_double = unpack "d", pack "C8",  @double_array;
    return $decoded_double;
}

sub deserializeULongLong {
    my ($class, $acc_ref) = @_;
    my @ulonglong_array = @$acc_ref;
    my $decoded_ulonglong = unpack "Q", pack "C8",  @ulonglong_array;
    return $decoded_ulonglong;
}

sub deserializeUInt {
    my ($class, $acc_ref) = @_;
    my @uint_array = @$acc_ref;
    my $decoded_uint = unpack "V", pack "C4",  @uint_array;
    return $decoded_uint;
}

sub deserializeUndef {
    my ($class) = @_;
    return undef;
}

1;