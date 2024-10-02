package ProtocolDataSeed;
use strict;
use warnings FATAL => 'all';

our @JAVONET_string_serialized = (1, 1, 7, 0, 0, 0, 74, 65, 86, 79, 78, 69, 84);
our @NonAscii_string_serialized = (1, 1, 14, 0, 0, 0, 197, 164, 194, 191, 207, 187, 195, 144, 195, 159, 196, 166, 197, 129);
our @empty_string_serialized = (1, 1, 0, 0, 0, 0);
our @int_serialized = (2, 4, 89, 8, 0, 0);
our @bool_serialized = (3, 1, 1);
our @float_serialized = (4, 4, 195, 245, 170, 193);
our @byte_serialized = (5, 1, 90);
our @char_serialized = (6, 1, 91);
our @longlong_serialized = (7, 8, 21, 205, 91, 7, 0, 0, 192, 255);
our @double_serialized = (8, 8, 184, 86, 14, 60, 221, 154, 239, 63);
our @ullong_serialized = (9, 8, 255, 255, 255, 255, 255, 255, 255, 255);
our @uint_serialized = (10, 4, 254, 255, 255, 255);
our @undef_serialized = (11, 1, 0);

our $JAVONET_string_deserialized = "JAVONET";
our $NonAscii_string_deserialized = "Ť¿ϻÐßĦŁ";
our $empty_string_deserialized = "";
our $int_deserialized = 2137;
our $bool_deserialized = 1; # True in Perl
our $float_deserialized = -21.37;
our $byte_deserialized = 90;
our $char_deserialized = 91;
our $longlong_deserialized = -18014398386025195;
our $double_deserialized = 0.987654321;
our $ullong_deserialized = 18446744073709551615;
our $uint_deserialized = 2 ** 32 - 2;
our $undef_deserialized = undef;

1;