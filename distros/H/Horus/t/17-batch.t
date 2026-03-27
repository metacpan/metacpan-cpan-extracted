use 5.008003;
use strict;
use warnings;
use Test::More tests => 5;
use Horus qw(:all);

# Batch v4
my @uuids = uuid_v4_bulk(1000);
is(scalar @uuids, 1000, 'uuid_v4_bulk returns correct count');

# All valid v4
my $all_valid = 1;
for my $u (@uuids) {
    unless ($u =~ /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/) {
        $all_valid = 0;
        last;
    }
}
ok($all_valid, 'all batch UUIDs match v4 pattern');

# All unique
my %seen;
my $dupes = 0;
for my $u (@uuids) { $dupes++ if $seen{$u}++ }
is($dupes, 0, 'no duplicates in 1000 batch UUIDs');

# Large batch (triggers bulk random path)
my @large = uuid_v4_bulk(500);
is(scalar @large, 500, 'large batch returns correct count');

# Batch with format
my @hex_batch = uuid_v4_bulk(10, UUID_FMT_HEX);
like($hex_batch[0], qr/^[0-9a-f]{32}$/, 'batch with HEX format');
