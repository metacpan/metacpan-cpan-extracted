use 5.008003;
use strict;
use warnings;
use Test::More;

BEGIN {
    # perl 5.10.0 shipped with a broken ithreads implementation - bare
    # `threads->create(sub { 1 })->join` SEGVs inside threads->create
    # itself, no XS code involved. Confirmed locally in a clean
    # perlbrew build of 5.10.0 x86_64-linux-thread-multi. Fixed in
    # 5.10.1. Skip the whole file on any 5.10.x to stay safe; modern
    # Perls cover this just fine.
    plan skip_all => 'perl 5.10 ithreads unsafe (broken in 5.10.0; '
                   . 'see comment in t/19-thread-safety.t)'
        if $] < 5.012;

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
