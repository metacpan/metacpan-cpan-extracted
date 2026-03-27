use 5.008003;
use strict;
use warnings;
use Test::More tests => 7;
use Horus qw(:all);

# v5 with DNS namespace
my $uuid = uuid_v5(UUID_NS_DNS(), 'example.com');
like($uuid, qr/^[0-9a-f]{8}-[0-9a-f]{4}-5[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/,
     'uuid_v5 matches v5 pattern');

is(uuid_version($uuid), 5, 'uuid_version returns 5');
is(uuid_variant($uuid), 1, 'uuid_variant returns 1 (RFC 9562)');

# Deterministic: same inputs = same UUID
my $uuid2 = uuid_v5(UUID_NS_DNS(), 'example.com');
is($uuid, $uuid2, 'uuid_v5 is deterministic');

# Different name = different UUID
my $uuid3 = uuid_v5(UUID_NS_DNS(), 'example.org');
isnt($uuid, $uuid3, 'different names produce different UUIDs');

# Different namespace = different UUID
my $uuid4 = uuid_v5(UUID_NS_URL(), 'example.com');
isnt($uuid, $uuid4, 'different namespaces produce different UUIDs');

# Validate
ok(uuid_validate($uuid), 'uuid_validate accepts v5');
