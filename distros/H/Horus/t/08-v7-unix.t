use 5.008003;
use strict;
use warnings;
use Test::More tests => 7;
use Horus qw(:all);

# Timestamp extraction — capture time window around UUID generation
my $before = time();
my $uuid = uuid_v7();
my $after = time();

like($uuid, qr/^[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/,
     'uuid_v7 matches v7 pattern');

is(uuid_version($uuid), 7, 'uuid_version returns 7');
is(uuid_variant($uuid), 1, 'uuid_variant returns 1 (RFC 9562)');

my $extracted = uuid_time($uuid);
ok($extracted >= ($before - 1) && $extracted <= ($after + 1),
   "v7 timestamp within time window")
    || diag("extracted=$extracted before=$before after=$after diff_before=",
            $extracted - $before, " diff_after=", $extracted - $after);

# Lexical sort order matches temporal order
my @uuids;
for (1..100) {
    push @uuids, uuid_v7();
}
my @sorted = sort @uuids;
is_deeply(\@uuids, \@sorted, 'v7 UUIDs sort lexically in temporal order');

# Validate
ok(uuid_validate($uuid), 'uuid_validate accepts v7');

# Uniqueness
my %seen;
my $dupes = 0;
for (1..1000) {
    my $u = uuid_v7();
    $dupes++ if $seen{$u}++;
}
is($dupes, 0, 'no duplicates in 1000 v7 UUIDs');
