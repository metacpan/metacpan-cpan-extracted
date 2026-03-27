use 5.008003;
use strict;
use warnings;
use Test::More tests => 25;

BEGIN { use_ok('Horus') };

# Test that all generation functions are importable
my @gen_funcs = qw(uuid_v1 uuid_v2 uuid_v3 uuid_v4 uuid_v5
                   uuid_v6 uuid_v7 uuid_v8 uuid_nil uuid_max
                   uuid_v4_bulk);
for my $func (@gen_funcs) {
    can_ok('Horus', $func);
}

# Test that all utility functions are importable
my @util_funcs = qw(uuid_parse uuid_validate uuid_version uuid_variant
                    uuid_cmp uuid_convert uuid_time uuid_is_nil uuid_is_max);
for my $func (@util_funcs) {
    can_ok('Horus', $func);
}

# Test that format constants exist
can_ok('Horus', 'UUID_FMT_STR');
can_ok('Horus', 'UUID_FMT_HEX');
can_ok('Horus', 'UUID_FMT_BASE64');
can_ok('Horus', 'UUID_NS_DNS');
