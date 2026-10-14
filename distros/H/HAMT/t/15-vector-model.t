#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use HAMT::Vector;

# A vector and a plain array, driven by the same random operations and
# compared as they go. Old versions are kept with a copy of the array as it
# stood, and every one is compared again at the end.

my $seed = $ENV{HAMT_TEST_SEED} // 20261013;
my $state;
sub rnd { $state = ($state * 1103515245 + 12345) % 2147483648; return ($state >> 8) % $_[0] }

sub same {
    my ($v, $a) = @_;
    return 0 unless $v->count == @$a;
    return 1 unless @$a;
    for my $i (0, $#$a, map { rnd(scalar @$a) } 1 .. 12) {
        my ($got, $want) = ($v->get($i), $a->[$i]);
        return 0 if defined $got != defined $want || (defined $got && $got ne $want);
    }
    return 1;
}
sub same_all {
    my ($v, $a) = @_;
    no warnings 'uninitialized';
    return $v->count == @$a && join("\0", $v->list) eq join("\0", @$a);
}

sub run {
    my ($steps, $up, $label, $through_transient) = @_;
    $state = $seed + $steps + $up;
    my $v = HAMT::Vector->new;
    my $t = $through_transient ? $v->transient : undef;
    my (@a, @kept, $bad);
    my $checks = 0;

    for my $step (1 .. $steps) {
        my $op = rnd(100);
        if ($op < $up || !@a) {
            my $val = rnd(9) ? "v$step" : undef;
            if ($t) { $t->push($val) } else { $v = $v->push($val) }
            push @a, $val;
        }
        elsif ($op < 80) {
            if ($t) { $t->pop } else { $v = $v->pop }
            pop @a;
        }
        elsif ($op < 95) {
            my $i = rnd(scalar @a);
            if ($t) { $t->set($i, "s$step") } else { $v = $v->set($i, "s$step") }
            $a[$i] = "s$step";
        }
        else {
            my $i = rnd(@a + 5) - 2;
            my $got = $t ? $t->get($i) : $v->get($i);
            my $want = ($i >= @a || $i < -@a) ? undef : $a[$i];
            $bad ||= "step $step: get($i)" if defined $got != defined $want || (defined $got && $got ne $want);
        }
        my $now = $t || $v;
        $bad ||= "step $step: count " . $now->count . ' against ' . @a if $now->count != @a;

        if ($step % 400 == 0) {
            if ($t) { $v = $t->persistent; $t = $v->transient }
            $bad ||= "step $step: rule " . $v->_check if $v->_check;
            $bad ||= "step $step: the vector and the array differ" unless same_all($v, \@a);
            $checks++;
            push @kept, [ $v, [@a], $step ];
        }
        last if $bad;
    }
    $v = $t->persistent if $t;

    ok(!$bad, "$steps random operations, $label") or diag("$bad (HAMT_TEST_SEED=$seed)");
    ok(same_all($v, \@a) && $v->_check == 0, 'the vector and the array agree at the end, and it checks out');
    my $stale = 0;
    for my $k (@kept) {
        my ($old, $was, $step) = @$k;
        next if same_all($old, $was) && $old->_check == 0;
        $stale++;
        diag("the version kept at step $step has changed (HAMT_TEST_SEED=$seed)");
        last;
    }
    is($stale, 0, 'every one of ' . @kept . ' kept versions is exactly what it was');
    cmp_ok($checks, '>=', int($steps / 400), 'the checker ran on each');
    return;
}

run(50_000, 55, 'growing');
run(50_000, 40, 'hovering near empty');
run(50_000, 70, 'growing fast, past two levels');
run(50_000, 55, 'growing, through a transient reopened every 400 steps', 1);
run(50_000, 45, 'near empty, through a transient', 1);

done_testing;
