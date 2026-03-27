use 5.008003;
use strict;
use warnings;
use Test::More tests => 8;
use Horus qw(:all);

# Default OO constructor
my $gen = Horus->new();
isa_ok($gen, 'Horus');

my $uuid = $gen->generate;
like($uuid, qr/^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/,
     'default generate produces v4 STR');

# Custom version and format
my $gen7 = Horus->new(version => 7, format => UUID_FMT_HEX);
my $v7 = $gen7->generate;
like($v7, qr/^[0-9a-f]{32}$/, 'generate with version=7 format=HEX');
is(uuid_version(uuid_convert($v7, UUID_FMT_STR)), 7, 'generated UUID is version 7');

# Bulk generation
my @batch = $gen->bulk(100);
is(scalar @batch, 100, 'bulk generates correct count');
like($batch[0], qr/^[0-9a-f]{8}-/, 'bulk items are formatted UUIDs');

# Bulk with v7
my @v7_batch = $gen7->bulk(50);
is(scalar @v7_batch, 50, 'v7 bulk generates correct count');

# All unique
my %seen;
my $dupes = 0;
for my $u (@batch) { $dupes++ if $seen{$u}++ }
is($dupes, 0, 'bulk UUIDs are unique');
