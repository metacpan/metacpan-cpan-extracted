use 5.008003;
use strict;
use warnings;
use Test::More tests => 8;
use Horus qw(:all);

# Basic v1 generation
my $uuid = uuid_v1();
like($uuid, qr/^[0-9a-f]{8}-[0-9a-f]{4}-1[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/,
     'uuid_v1 matches v1 pattern');

is(uuid_version($uuid), 1, 'uuid_version returns 1');
is(uuid_variant($uuid), 1, 'uuid_variant returns 1 (RFC 9562)');

# Timestamp extraction - should be close to now
my $now = time();
my $extracted = uuid_time($uuid);
ok(abs($extracted - $now) < 5, "v1 timestamp within 5 seconds of now (got $extracted, expected ~$now)");

# Node ID should be stable across calls
my $uuid2 = uuid_v1();
my $node1 = substr($uuid,  24, 12);
my $node2 = substr($uuid2, 24, 12);
is($node1, $node2, 'v1 node ID is stable across calls');

# UUIDs should be different
isnt($uuid, $uuid2, 'two v1 UUIDs are different');

# Validate
ok(uuid_validate($uuid), 'uuid_validate accepts v1');

# Uniqueness
my %seen;
my $dupes = 0;
for (1..100) {
    my $u = uuid_v1();
    $dupes++ if $seen{$u}++;
}
is($dupes, 0, 'no duplicates in 100 v1 UUIDs');
