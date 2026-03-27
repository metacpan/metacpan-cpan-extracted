use 5.008003;
use strict;
use warnings;
use Test::More tests => 12;
use Horus qw(:all);

# Generate one UUID and test all formats
my $bin = uuid_v4(UUID_FMT_BINARY);
is(length($bin), 16, 'binary format is 16 bytes');

# Convert to all formats
my $str = uuid_convert($bin, UUID_FMT_STR);
like($str, qr/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/,
     'STR format: 36 chars hyphenated');

my $hex = uuid_convert($bin, UUID_FMT_HEX);
like($hex, qr/^[0-9a-f]{32}$/, 'HEX format: 32 hex chars');

my $braces = uuid_convert($bin, UUID_FMT_BRACES);
like($braces, qr/^\{[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\}$/,
     'BRACES format: {hyphenated}');

my $urn = uuid_convert($bin, UUID_FMT_URN);
like($urn, qr/^urn:uuid:[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/,
     'URN format: urn:uuid:hyphenated');

my $b64 = uuid_convert($bin, UUID_FMT_BASE64);
is(length($b64), 22, 'BASE64 format: 22 chars');
like($b64, qr/^[A-Za-z0-9+\/]{22}$/, 'BASE64 format: valid base64 chars');

my $b32 = uuid_convert($bin, UUID_FMT_BASE32);
is(length($b32), 26, 'BASE32 format: 26 chars');

my $crk = uuid_convert($bin, UUID_FMT_CROCKFORD);
is(length($crk), 26, 'CROCKFORD format: 26 chars');
like($crk, qr/^[0-9A-HJKMNP-TV-Z]{26}$/, 'CROCKFORD format: valid Crockford chars');

my $upper_str = uuid_convert($bin, UUID_FMT_UPPER_STR);
like($upper_str, qr/^[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}$/,
     'UPPER_STR format: uppercase hyphenated');

my $upper_hex = uuid_convert($bin, UUID_FMT_UPPER_HEX);
like($upper_hex, qr/^[0-9A-F]{32}$/, 'UPPER_HEX format: uppercase no hyphens');
