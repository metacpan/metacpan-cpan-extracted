#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use HAMT::Map;

# A map and a plain hash, driven by the same random operations and compared
# as they go. Old versions are kept with a copy of the hash as it stood, and
# every one is compared again at the end: an update that reached back into
# an earlier version shows up there and nowhere else.
#
# Run at four hash widths. Narrowing the hash is the only way to reach a
# collision node or the deepest level of the trie with a few hundred keys.

END { HAMT::_hash_bits(64) }

my $seed = $ENV{HAMT_TEST_SEED} // 20261013;

# A small generator of its own, so a failure reproduces on any perl: rand()
# is not the same sequence everywhere.
my $state;
sub rnd { $state = ($state * 1103515245 + 12345) % 2147483648; return ($state >> 8) % $_[0] }

sub same {
    my ($m, $h) = @_;
    return 0 unless $m->count == keys %$h;
    for my $k (keys %$h) {
        return 0 unless $m->exists($k);
        my ($got, $want) = ($m->get($k), $h->{$k});
        return 0 if defined $got != defined $want;
        return 0 if defined $got && $got ne $want;
    }
    my %seen = $m->pairs;
    return 0 unless keys %seen == keys %$h;
    return 1;
}

sub run {
    my ($bits, $steps, $universe) = @_;
    HAMT::_hash_bits($bits);
    $state = $seed;

    my $m = HAMT::Map->new;
    my %h;
    my @kept;
    my ($bad, $checks) = (0, 0);

    for my $step (1 .. $steps) {
        my $key = 'k' . rnd($universe);
        my $op  = rnd(10);

        if ($op < 5) {
            my $val = rnd(4) ? "v$step" : undef;
            $m = $m->set($key, $val);
            $h{$key} = $val;
        }
        elsif ($op < 8) {
            $m = $m->delete($key);
            delete $h{$key};
            $bad ||= "step $step: rule " . $m->_check . ' broken after a delete' if $m->_check;
            $checks++;
        }
        else {
            my ($got, $want) = ($m->get($key), $h{$key});
            $bad ||= "step $step: get($key) disagrees"
                if defined $got != defined $want || (defined $got && $got ne $want);
            $bad ||= "step $step: exists($key) disagrees"
                if !!$m->exists($key) != !!exists $h{$key};
        }

        $bad ||= "step $step: count is " . $m->count . ', the hash has ' . keys %h
            if $m->count != keys %h;
        $bad ||= "step $step: the map and the hash differ" if $step % 500 == 0 && !same($m, \%h);
        push @kept, [ $m, { %h }, $step ] if $step % 100 == 0;
        last if $bad;
    }

    ok(!$bad, "$steps random operations over $universe keys at $bits hash bits")
        or diag("$bad (HAMT_TEST_SEED=$seed)");
    cmp_ok($checks, '>', $steps / 5, "the checker ran after each of $checks deletes");
    ok(same($m, \%h), 'the map and the hash agree at the end');

    my $stale = 0;
    for my $k (@kept) {
        my ($old, $was, $step) = @$k;
        next if same($old, $was) && $old->_check == 0;
        $stale++;
        diag("the version kept at step $step has changed (HAMT_TEST_SEED=$seed)");
        last;
    }
    is($stale, 0, 'every one of ' . @kept . ' kept versions is exactly what it was');

    @kept = ();
    undef $m;
    return;
}

run(64, 20_000, 2_000);
run(10, 20_000, 2_000);
run(5,  20_000, 600);
run(0,  6_000,  150);

done_testing;
