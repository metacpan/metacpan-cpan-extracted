#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use HAMT::Vector;

# Every kind of edit at random against an array, the checker after each one.
# A tree only gets into a bad shape after many seams, so this is the test
# that finds one drifting. Old versions are kept and compared again at the
# end, and the library's block count says nothing was leaked.

my $seed = $ENV{HAMT_TEST_SEED} // 20261013;
my $state;
sub rnd { $state = ($state * 1103515245 + 12345) % 2147483648; return ($state >> 8) % $_[0] }

sub same_all {
    my ($v, $a) = @_;
    return $v->count == @$a && join("\0", $v->list) eq join("\0", @$a);
}

my $blocks = HAMT::_live_blocks();

sub run {
    my ($steps, $ceiling, $label) = @_;
    $state = $seed + $steps + $ceiling;
    my $v = HAMT::Vector->new;
    my (@a, @kept, $bad);

    for my $step (1 .. $steps) {
        my $op = rnd(100);
        $op = 62 if @a > $ceiling;
        if ($op < 25 || !@a) {
            my $at = rnd(@a + 1);
            my @vals = map { "i$step.$_" } 1 .. 1 + rnd(3);
            $v = $v->insert($at, @vals);
            splice @a, $at, 0, @vals;
        }
        elsif ($op < 40) {
            my ($at, $len) = (rnd(scalar @a), 1 + rnd(5));
            $v = $v->remove($at, $len);
            splice @a, $at, $len;
        }
        elsif ($op < 55) {
            my @run = map { "r$step.$_" } 1 .. 1 + rnd(39);
            if (rnd(2)) { $v = HAMT::Vector->new(@run)->concat($v); unshift @a, @run }
            else        { $v = $v->concat(HAMT::Vector->new(@run)); push @a, @run }
        }
        elsif ($op < 65) {
            my $from = rnd(scalar @a);
            my $len  = 1 + rnd(@a - $from);
            ($from, $len) = (int(@a / 4), int(@a / 2)) if @a > $ceiling;
            $v = $v->slice($from, $len);
            @a = @a[$from .. $from + $len - 1];
        }
        elsif ($op < 80) { $v = $v->push("p$step"); push @a, "p$step" }
        elsif ($op < 90) { $v = $v->pop; pop @a }
        else {
            my $i = rnd(scalar @a);
            $v = $v->set($i, "s$step");
            $a[$i] = "s$step";
        }

        $bad ||= "step $step: count " . $v->count . ' against ' . @a if $v->count != @a;
        $bad ||= "step $step: rule " . $v->_check if $v->_check;
        if (!$bad && @a) {
            my $i = rnd(scalar @a);
            $bad ||= "step $step: index $i" if $v->get($i) ne $a[$i];
        }
        $bad ||= "step $step: the vector and the array differ" if $step % 50 == 0 && !same_all($v, \@a);
        push @kept, [ $v, [@a], $step ] if $step % int($steps / 30) == 0;
        last if $bad;
    }
    ok(!$bad, "$steps random edits, $label") or diag("$bad (HAMT_TEST_SEED=$seed)");
    ok(same_all($v, \@a), 'the vector and the array agree at the end');
    my $stale = 0;
    for my $k (@kept) {
        my ($old, $was, $step) = @$k;
        next if same_all($old, $was) && $old->_check == 0;
        $stale++;
        diag("the version kept at step $step has changed (HAMT_TEST_SEED=$seed)");
        last;
    }
    is($stale, 0, 'every one of ' . @kept . ' kept versions is exactly what it was');
    return;
}

run(6000, 20_000, 'left to grow to 20,000');
run(6000, 600, 'held under 600, where every edit is near the root');
run(4000, 40, 'held under 40, where the tail is most of the vector');

is(HAMT::_live_blocks(), $blocks, 'and with every vector gone, the library holds what it held before');

done_testing;
