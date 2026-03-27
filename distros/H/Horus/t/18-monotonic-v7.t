use 5.008003;
use strict;
use warnings;
use Test::More tests => 2;
use Horus qw(:all);

# Generate 1000 v7 UUIDs in a tight loop
my @uuids;
for (1..1000) {
    push @uuids, uuid_v7();
}

# Verify strict ascending order (string comparison works for v7)
my $monotonic = 1;
for my $i (1..$#uuids) {
    if ($uuids[$i] le $uuids[$i-1]) {
        $monotonic = 0;
        diag("Non-monotonic at index $i: $uuids[$i-1] >= $uuids[$i]");
        last;
    }
}
ok($monotonic, 'v7 UUIDs are strictly ascending (monotonic)');

# All unique
my %seen;
my $dupes = 0;
for my $u (@uuids) { $dupes++ if $seen{$u}++ }
is($dupes, 0, 'no duplicates in 1000 monotonic v7 UUIDs');
