#!/usr/bin/perl

use warnings;
use strict;

use Test::More tests => 19;
use Test::Warn;

use_ok('Encode::Base32::Crockford', qw(
	base32_decode base32_decode_with_checksum
	base32_encode base32_encode_with_checksum
));

eval {
	my $duff = base32_decode(undef);
};

like($@, qr/is undefined/, "detect undefined string");

eval {
	my $duff = base32_decode("");
};

like($@, qr/^string is empty/, "detect empty string");

eval {
	my $duff = base32_decode("fudge");
};

like($@, qr/^String "FUDGE" contains invalid characters/, "detect invalid characters");

is(base32_decode("10"), 32, "decode() 1");

is(base32_decode("A0"), 320, "decode() 2");

is(base32_decode("AA-BB-CC-DD"), 354715840941, "strip chunk markers in decode()");

is(base32_decode_with_checksum("40H"), 128, "decode_with_checksum()");

is(base32_decode("U", { "is_checksum" => 1 }), 36, "decode a checksum");

eval {
	base32_decode("AA", { "is_checksum" => 1});
};

like($@, qr/^Checksum "AA" is too long/, "spot overlong checksum");

eval {
	base32_decode("?", { "is_checksum" => 1 });
};

like($@, qr/^String "\?" contains invalid characters/, "spot invalid checksum");

warning_like {
	my $foo = base32_decode("LO", { "mode" => "warn" });
} qr/String "LO" corrected to "10"/, "warnings mode";

eval {
	my $foo = base32_decode("LO", { "mode" => "strict" });
};

like($@, qr/String "LO" requires normalization/, "strict mode");

eval {
	base32_decode_with_checksum("A0X");
};

like($@, qr/^Checksum symbol "X" is not correct for value "A0"./, "spot incorrect checksum");

eval {
	base32_encode("foo");
};

like($@, qr/^"foo" isn't a number/, "spot non-number input");

is(base32_encode(128), 40, "encode()");

is(base32_encode(500), 'FM', "encode larger number");

is(base32_encode_with_checksum(128), '40H', "encode_with_checksum()");

is(base32_encode_with_checksum(9), '99', "checksum encode small number");
