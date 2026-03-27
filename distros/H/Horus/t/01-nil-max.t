use 5.008003;
use strict;
use warnings;
use Test::More tests => 16;
use Horus qw(:all);

# NIL UUID
my $nil = uuid_nil();
is($nil, '00000000-0000-0000-0000-000000000000', 'uuid_nil default format');

my $nil_hex = uuid_nil(UUID_FMT_HEX);
is($nil_hex, '00000000000000000000000000000000', 'uuid_nil hex format');

my $nil_braces = uuid_nil(UUID_FMT_BRACES);
is($nil_braces, '{00000000-0000-0000-0000-000000000000}', 'uuid_nil braces format');

my $nil_urn = uuid_nil(UUID_FMT_URN);
is($nil_urn, 'urn:uuid:00000000-0000-0000-0000-000000000000', 'uuid_nil URN format');

my $nil_bin = uuid_nil(UUID_FMT_BINARY);
is(length($nil_bin), 16, 'uuid_nil binary length');
is($nil_bin, "\0" x 16, 'uuid_nil binary all zeros');

ok(uuid_is_nil($nil), 'uuid_is_nil recognises nil');
ok(!uuid_is_max($nil), 'uuid_is_max rejects nil');

# MAX UUID
my $max = uuid_max();
is($max, 'ffffffff-ffff-ffff-ffff-ffffffffffff', 'uuid_max default format');

my $max_hex = uuid_max(UUID_FMT_HEX);
is($max_hex, 'ffffffffffffffffffffffffffffffff', 'uuid_max hex format');

my $max_upper = uuid_max(UUID_FMT_UPPER_STR);
is($max_upper, 'FFFFFFFF-FFFF-FFFF-FFFF-FFFFFFFFFFFF', 'uuid_max uppercase');

my $max_bin = uuid_max(UUID_FMT_BINARY);
is(length($max_bin), 16, 'uuid_max binary length');
is($max_bin, "\xff" x 16, 'uuid_max binary all ones');

ok(uuid_is_max($max), 'uuid_is_max recognises max');
ok(!uuid_is_nil($max), 'uuid_is_nil rejects max');

# Cross-check
ok(!uuid_is_nil($max) && !uuid_is_max($nil), 'nil and max are distinct');
