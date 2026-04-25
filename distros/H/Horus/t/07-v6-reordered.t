use 5.008003;
use strict;
use warnings;
use Test::More tests => 7;
use Horus qw(:all);

# Basic v6 generation
my $uuid = uuid_v6();
like($uuid, qr/^[0-9a-f]{8}-[0-9a-f]{4}-6[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/,
     'uuid_v6 matches v6 pattern');

is(uuid_version($uuid), 6, 'uuid_version returns 6');
is(uuid_variant($uuid), 1, 'uuid_variant returns 1 (RFC 9562)');

# Timestamp extraction
my $now = time();
my $extracted = uuid_time($uuid);
ok(abs($extracted - $now) < 10, "v6 timestamp within 10 seconds of now");

# Lexical sort order matches temporal order
my @uuids;
for (1..20) {
    push @uuids, uuid_v6();
}
my @sorted = sort @uuids;
is_deeply(\@uuids, \@sorted, 'v6 UUIDs sort lexically in temporal order');

# Validate
ok(uuid_validate($uuid), 'uuid_validate accepts v6');

# Uniqueness
my %seen;
my $dupes = 0;
for (1..100) {
    my $u = uuid_v6();
    $dupes++ if $seen{$u}++;
}
is($dupes, 0, 'no duplicates in 100 v6 UUIDs');
