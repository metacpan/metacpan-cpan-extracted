use 5.008003;
use strict;
use warnings;
use Test::More tests => 10;
use Horus qw(:all);

# Basic v4 generation
my $uuid = uuid_v4();
like($uuid, qr/^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/,
     'uuid_v4 matches v4 pattern (version=4, variant=8/9/a/b)');

# Version and variant
is(uuid_version($uuid), 4, 'uuid_version returns 4');
is(uuid_variant($uuid), 1, 'uuid_variant returns 1 (RFC 9562)');

# Uniqueness test - generate 1000 UUIDs, all should be unique
my %seen;
my $dupes = 0;
for (1..1000) {
    my $u = uuid_v4();
    $dupes++ if $seen{$u}++;
}
is($dupes, 0, 'no duplicates in 1000 v4 UUIDs');

# Validate
ok(uuid_validate($uuid), 'uuid_validate accepts v4');

# Not nil/max
ok(!uuid_is_nil($uuid), 'v4 is not nil');
ok(!uuid_is_max($uuid), 'v4 is not max');

# Different formats
my $hex = uuid_v4(UUID_FMT_HEX);
like($hex, qr/^[0-9a-f]{32}$/, 'uuid_v4 hex format is 32 hex chars');

my $upper = uuid_v4(UUID_FMT_UPPER_STR);
like($upper, qr/^[0-9A-F]{8}-[0-9A-F]{4}-4[0-9A-F]{3}-[89AB][0-9A-F]{3}-[0-9A-F]{12}$/,
     'uuid_v4 uppercase format');

# Base64 format
my $b64 = uuid_v4(UUID_FMT_BASE64);
is(length($b64), 22, 'uuid_v4 base64 is 22 chars');
