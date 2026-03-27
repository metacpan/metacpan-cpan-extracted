use 5.008003;
use strict;
use warnings;
use Test::More tests => 5;
use Horus qw(:all);

# v8 with known custom data
my $custom = "\x01\x02\x03\x04\x05\x06\x07\x08\x09\x0a\x0b\x0c\x0d\x0e\x0f\x10";
my $uuid = uuid_v8($custom);

like($uuid, qr/^[0-9a-f]{8}-[0-9a-f]{4}-8[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/,
     'uuid_v8 matches v8 pattern');

is(uuid_version($uuid), 8, 'uuid_version returns 8');
is(uuid_variant($uuid), 1, 'uuid_variant returns 1 (RFC 9562)');

# Verify data is preserved (except version/variant bits)
my $bin = uuid_parse($uuid);
# Bytes 0-5 should be preserved
is(substr($bin, 0, 6), substr($custom, 0, 6), 'v8 preserves bytes 0-5');
# Bytes 10-15 should be preserved
is(substr($bin, 10, 6), substr($custom, 10, 6), 'v8 preserves bytes 10-15');
