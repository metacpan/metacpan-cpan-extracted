#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Scalar::Util qw(refaddr);
use HAMT::Set;

# union, intersect, difference, is_subset and is_disjoint against the same
# questions asked of two Perl hashes: 500 random pairs at each of four hash
# widths, related in each of three ways, with the checker run on every
# result.

END { HAMT::_hash_bits(64) }

my $seed = $ENV{HAMT_TEST_SEED} // 20261013;
my $state;
sub rnd { $state = ($state * 1103515245 + 12345) % 2147483648; return ($state >> 8) % $_[0] }

sub members { join ',', sort $_[0]->members }
sub from    { join ',', sort keys %{ $_[0] } }

for my $bits (64, 10, 5, 0) {
    HAMT::_hash_bits($bits);
    $state = $seed + $bits;
    my $pairs = $bits ? 500 : 150;
    my $universe = $bits ? 400 : 60;
    my %bad;
    my $checks = 0;

    for my $pair (1 .. $pairs) {
        my $kind = $pair % 3;       # 0 unrelated, 1 disjoint, 2 one a version of the other
        my (%a, %b);
        $a{ 'm' . rnd($universe) } = 1 for 1 .. rnd($universe) + 1;
        my ($sa, $sb);
        $sa = HAMT::Set->new(keys %a);

        if ($kind == 0) {
            $b{ 'm' . rnd($universe) } = 1 for 1 .. rnd($universe) + 1;
            $sb = HAMT::Set->new(keys %b);
        }
        elsif ($kind == 1) {
            $b{ 'n' . rnd($universe) } = 1 for 1 .. rnd($universe) + 1;
            $sb = HAMT::Set->new(keys %b);
        }
        else {
            %b = %a;
            $sb = $sa;
            for (1 .. rnd(6)) {
                my $k = 'm' . rnd($universe);
                if (rnd(2)) { $b{$k} = 1; $sb = $sb->add($k) } else { delete $b{$k}; $sb = $sb->remove($k) }
            }
        }

        my %want = (
            union      => { %a, %b },
            intersect  => { map { ($_ => 1) } grep { $b{$_} } keys %a },
            difference => { map { ($_ => 1) } grep { !$b{$_} } keys %a },
        );
        for my $op (qw(union intersect difference)) {
            my $r = $sa->$op($sb);
            $bad{$op}       ||= "pair $pair (kind $kind): members" if members($r) ne from($want{$op});
            $bad{"$op count"} ||= "pair $pair (kind $kind): count " . $r->count if $r->count != keys %{ $want{$op} };
            $bad{"$op check"} ||= "pair $pair (kind $kind): rule " . $r->_check if $r->_check;
            $checks++;
        }
        my $sub = !grep { !$b{$_} } keys %a;
        my $dis = !grep { $b{$_} } keys %a;
        $bad{is_subset}   ||= "pair $pair (kind $kind)" if !!$sa->is_subset($sb) != !!$sub;
        $bad{is_disjoint} ||= "pair $pair (kind $kind)" if !!$sa->is_disjoint($sb) != !!$dis;
        $bad{equals}      ||= "pair $pair (kind $kind)" if !!$sa->equals($sb) != !!(from(\%a) eq from(\%b));
        $bad{'receiver unchanged'} ||= "pair $pair (kind $kind)"
            if members($sa) ne from(\%a) || members($sb) ne from(\%b);
    }

    for my $what (qw(union intersect difference is_subset is_disjoint equals), 'receiver unchanged',
                  map { ("$_ count", "$_ check") } qw(union intersect difference)) {
        ok(!$bad{$what}, "$bits bits: $what over $pairs pairs")
            or diag("$bad{$what} (HAMT_TEST_SEED=$seed)");
    }
    cmp_ok($checks, '==', 3 * $pairs, "$bits bits: the checker ran on all $checks results");
}
HAMT::_hash_bits(64);

my $a = HAMT::Set->new(1 .. 1000);
my $b = HAMT::Set->new(2000 .. 2999);
my $e = HAMT::Set->new;

# ---- answers that are one of the operands, each with a case that is not ----------
{
    my $part = HAMT::Set->new(1 .. 500);
    my $more = $a->add(5000);

    is(refaddr($a->union($part)), refaddr($a), 'union with a subset is the receiver');
    isnt(refaddr($a->union($b)), refaddr($a), 'union with something new is not');
    is(refaddr($a->union($a)), refaddr($a), 'union with itself is itself');
    is(refaddr($a->union($e)), refaddr($a), 'union with the empty set is the receiver');
    is(refaddr($e->union($a)), refaddr($a), 'the empty set\'s union with a set is that set');
    is(refaddr($a->union($more)), refaddr($more), 'union with a version that holds everything is that version');

    is(refaddr($a->intersect($more)), refaddr($a), 'intersect with a superset is the receiver');
    isnt(refaddr($a->intersect($part)), refaddr($a), 'intersect with a subset is not');
    ok($a->intersect($part)->equals($part), 'it is the subset');
    is(refaddr($a->intersect($a)), refaddr($a), 'intersect with itself is itself');
    is($a->intersect($e)->count, 0, 'intersect with the empty set is empty');
    is($a->intersect($b)->count, 0, 'and so is intersect with a disjoint one');
    is(refaddr($e->intersect($a)), refaddr($e), 'the empty set intersected with anything is the receiver');

    is(refaddr($a->difference($b)), refaddr($a), 'difference with a disjoint set is the receiver');
    isnt(refaddr($a->difference($part)), refaddr($a), 'difference with something shared is not');
    is($a->difference($part)->count, 500, 'it is what is left');
    is(refaddr($a->difference($e)), refaddr($a), 'difference with the empty set is the receiver');
    is($a->difference($a)->count, 0, 'a set less itself is empty');
    is($a->difference($more)->count, 0, 'and less a superset');
    is($more->difference($a)->count, 1, 'a version less the one it came from is what was added');
    ok($more->difference($a)->has(5000), 'by name');
}

# ---- the questions ----------------------------------------------------------------
ok($e->is_subset($a) && $e->is_subset($e), 'the empty set is a subset of everything');
ok(!$a->is_subset($e), 'and nothing with members is a subset of it');
ok($a->is_subset($a), 'a set is a subset of itself');
ok($e->is_disjoint($a) && $a->is_disjoint($e) && $e->is_disjoint($e), 'the empty set is disjoint from everything');
ok(!$a->is_disjoint($a), 'a set with members is not disjoint from itself');
ok($a->is_disjoint($b) && $b->is_disjoint($a), 'two sets with nothing in common are disjoint');
ok(!$a->is_disjoint($b->add(500)), 'until one member is shared');

# ---- the laws, on sets large enough to have some depth -----------------------------
{
    my $x = HAMT::Set->new(map { $_ * 2 } 1 .. 3000);
    my $y = HAMT::Set->new(map { $_ * 3 } 1 .. 3000);
    my $z = HAMT::Set->new(map { $_ * 5 } 1 .. 3000);

    ok($x->union($y)->equals($y->union($x)), 'union commutes');
    ok($x->intersect($y)->equals($y->intersect($x)), 'intersect commutes');
    ok($x->union($y)->union($z)->equals($x->union($y->union($z))), 'union associates');
    ok($x->intersect($y->union($z))->equals($x->intersect($y)->union($x->intersect($z))),
       'intersect distributes over union');
    ok($x->difference($y)->union($x->intersect($y))->equals($x), 'what is left and what is shared make the whole');
    ok($x->difference($y)->is_disjoint($y), 'what is left is disjoint from what was taken');
    ok($x->intersect($y)->is_subset($x) && $x->intersect($y)->is_subset($y), 'the intersection is a subset of both');
    ok($x->is_subset($x->union($y)), 'each is a subset of the union');
    is($x->union($y)->count, $x->count + $y->count - $x->intersect($y)->count, 'and the counts add up');
    is($x->difference($y)->count, $x->count - $x->intersect($y)->count, 'both ways');
    is($x->union($y)->_check + $x->intersect($y)->_check + $x->difference($y)->_check, 0, 'all three check out');
}

done_testing;
