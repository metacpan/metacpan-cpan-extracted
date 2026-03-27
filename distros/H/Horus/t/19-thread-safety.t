use 5.008003;
use strict;
use warnings;
use Test::More;

BEGIN {
    eval { require threads; threads->import(); 1 }
        or plan skip_all => 'threads not available';
}

plan tests => 2;

use Horus qw(uuid_v4 uuid_v7);

my @threads;
for my $i (1..4) {
    push @threads, threads->create(sub {
        my @uuids;
        for (1..250) {
            push @uuids, uuid_v4();
            push @uuids, uuid_v7();
        }
        return \@uuids;
    });
}

my @all_uuids;
for my $t (@threads) {
    my $result = $t->join;
    push @all_uuids, @$result;
}

is(scalar @all_uuids, 2000, '4 threads x 500 UUIDs = 2000 total');

my %seen;
my $dupes = 0;
for my $u (@all_uuids) { $dupes++ if $seen{$u}++ }
is($dupes, 0, 'no duplicates across threads');
