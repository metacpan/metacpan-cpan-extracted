use strict;
use warnings;
use Test::More;

use Encode::Bijou64 qw(encode_bijou64 decode_bijou64);

# Check the exported functions
ok(defined &encode_bijou64, 'encode_bijou64 is exported');
ok(defined &decode_bijou64, 'decode_bijou64 is exported');

# Define tests for different tiers and their boundary conditions
# Let's perform roundtrip tests for values across all tiers.
# Note: On 32-bit platforms, values above 2^32-1 might be represented as floating-point numbers
# and could lose precision. We will check if Perl has 64-bit support.
my $has_64bit = (~0 > 0xFFFFFFFF);

my @test_cases = (
	# Tier 0 (<= 0xF7 / 247): Length = 1 byte
	0, 1, 100, 247,

	# Tier 1 (248 to 503): Tag 0xF8 + 1 byte
	248, 249, 300, 503,

	# Tier 2 (504 to 66039): Tag 0xF9 + 2 bytes
	504, 505, 1000, 65535, 66039,

	# Tier 3 (66040 to 16843255): Tag 0xFA + 3 bytes
	66040, 100000, 16843255,
);

# Add higher-tier test cases depending on platform support
if ($has_64bit) {
	push @test_cases, (
		# Tier 4 (16843256 to 4311810551): Tag 0xFB + 4 bytes
		16843256, 1234567890, 4311810551,

		# Tier 5 (4311810552 to 1103823438327): Tag 0xFC + 5 bytes
		4311810552, 100000000000, 1103823438327,

		# Tier 6 (1103823438328 to 282578800148983): Tag 0xFD + 6 bytes
		1103823438328, 282578800148983,

		# Tier 7 (282578800148984 to 72340172838076919): Tag 0xFE + 7 bytes
		282578800148984, 12039810293801983, 72340172838076919
	);
}

for my $n (@test_cases) {
	my $enc = eval { encode_bijou64($n) };
	is($@, '', "encode_bijou64($n) executes without error");
	ok(defined($enc), "encode_bijou64($n) returns a value");

	# Verify exact length of encoded value based on tier
	my $len = length($enc);
	if ($n <= 247) {
		is($len, 1, "Tier 0 value $n encoded to 1 byte");
		is(ord($enc), $n, "Tier 0 value $n encodes directly to itself");
	} elsif ($n <= 503) {
		is($len, 2, "Tier 1 value $n encoded to 2 bytes");
		is(ord(substr($enc, 0, 1)), 0xF8, "Tier 1 tag is 0xF8");
	} elsif ($n <= 66039) {
		is($len, 3, "Tier 2 value $n encoded to 3 bytes");
		is(ord(substr($enc, 0, 1)), 0xF9, "Tier 2 tag is 0xF9");
	} elsif ($n <= 16843255) {
		is($len, 4, "Tier 3 value $n encoded to 4 bytes");
		is(ord(substr($enc, 0, 1)), 0xFA, "Tier 3 tag is 0xFA");
	} elsif ($n <= 4311810551) {
		is($len, 5, "Tier 4 value $n encoded to 5 bytes");
		is(ord(substr($enc, 0, 1)), 0xFB, "Tier 4 tag is 0xFB");
	} elsif ($n <= 1103823438327) {
		is($len, 6, "Tier 5 value $n encoded to 6 bytes");
		is(ord(substr($enc, 0, 1)), 0xFC, "Tier 5 tag is 0xFC");
	} elsif ($n <= 282578800148983) {
		is($len, 7, "Tier 6 value $n encoded to 7 bytes");
		is(ord(substr($enc, 0, 1)), 0xFD, "Tier 6 tag is 0xFD");
	} elsif ($n <= 72340172838076919) {
		is($len, 8, "Tier 7 value $n encoded to 8 bytes");
		is(ord(substr($enc, 0, 1)), 0xFE, "Tier 7 tag is 0xFE");
	}

	my $dec = eval { decode_bijou64($enc) };
	is($@, '', "decode_bijou64(encode_bijou64($n)) executes without error");
	is($dec, $n, "Roundtrip: $n encodes and decodes perfectly");
}

# --- Error and Edge Cases ---

# 1. Undefined values
eval { encode_bijou64(undef) };
like($@, qr/encode_bijou64\(\): undefined value/, 'encode_bijou64(undef) throws error');

eval { decode_bijou64(undef) };
like($@, qr/decode_bijou64\(\): undefined value/, 'decode_bijou64(undef) throws error');

# 2. Negative integers
eval { encode_bijou64(-5) };
like($@, qr/encode_bijou64\(\): positive integer/, 'encode_bijou64(-5) throws error');

# 3. Non-integer inputs
eval { encode_bijou64("hello") };
like($@, qr/encode_bijou64\(\): positive integer required/, 'encode_bijou64("hello") throws error');

eval { encode_bijou64("123a") };
like($@, qr/encode_bijou64\(\): positive integer required/, 'encode_bijou64("123a") throws error');

eval { encode_bijou64(12.34) };
like($@, qr/encode_bijou64\(\): positive integer required/, 'encode_bijou64(12.34) throws error');

# 4. Empty buffer
eval { decode_bijou64("") };
like($@, qr/decode_bijou64\(\): empty buffer/, 'decode_bijou64("") throws error');

# 5. Invalid tags
# Valid tags are <= 0xF7 (direct) and 0xF8 .. 0xFF.
# Let's see: all 8-bit values are theoretically valid tags since 0x00..0xF7 are <= 0xF7, and 0xF8..0xFF map to the 8 tiers.
# What about a tag that doesn't exist? Since tiers cover 0xF8 to 0xFF, there actually are no invalid tags in a single-byte range,
# but let's double check if there are other edge cases.
# If we supply a tag and the buffer length is too short or too long:
# E.g. Tag 0xF8 expects 1 extra byte (total 2 bytes). Let's give it just 1 byte (the tag itself) or 3 bytes.
eval { decode_bijou64(pack("C", 0xF8)) };
like($@, qr/decode_bijou64\(\): buffer too short/, 'decode_bijou64 with short buffer (1 byte instead of 2) throws error');

eval { decode_bijou64(pack("C*", 0xF8, 0x01, 0x02)) };
like($@, qr/decode_bijou64\(\): buffer too short/, 'decode_bijou64 with long buffer (3 bytes instead of 2) throws error');

done_testing();
