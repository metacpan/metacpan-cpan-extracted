use 5.008003;
use strict;
use warnings;
use Test::More tests => 5;
use Horus qw(:all);

# v2 with person domain (0) - uses getuid
my $uuid = uuid_v2(0);
like($uuid, qr/^[0-9a-f]{8}-[0-9a-f]{4}-2[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/,
     'uuid_v2 matches v2 pattern');

is(uuid_version($uuid), 2, 'uuid_version returns 2');
is(uuid_variant($uuid), 1, 'uuid_variant returns 1 (RFC 9562)');

# v2 with group domain (1) - uses getgid
my $uuid_gid = uuid_v2(1);
like($uuid_gid, qr/^[0-9a-f]{8}-[0-9a-f]{4}-2[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/,
     'uuid_v2 group domain matches v2 pattern');

# Validate
ok(uuid_validate($uuid), 'uuid_validate accepts v2');
