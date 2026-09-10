#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Frozen ();

# The custom ops: that they FIRE, that they are guarded, and that a program
# which is not Frozen's is untouched.
#
# A test that only checked answers would pass with the hook never firing -
# which is exactly the state the first version of this file was in, and the
# state Search::Trigram ships in. So the counters are the assertion.

my %cat = (a => { b => { c => 'deep' } }, x => 'top', n => 5);
my $fz  = Frozen->attach(Frozen->freeze(\%cat, flat => '.'));

my ($hooked) = Frozen::_xop_stats();
cmp_ok($hooked, '>', 0, "the check hook rewrote $hooked entersubs at compile time");

# ---- it fires for the METHOD form, which is the whole point --------------
#
# cv_set_call_checker cannot do this: a method call resolves at runtime, so a
# checker attached to the CV never runs. Verified against this workspace's own
# Search::Trigram, whose seven checkers never fire for its documented API.

{
    Frozen::_xop_reset();
    my ($v) = $fz->get('a.b.c');
    is($v, 'deep', 'the method form returns the right value');
    my (undef, $hits, $miss) = Frozen::_xop_stats();
    is($hits, 1, '...and it took the fast path');
    is($miss, 0, '...without delegating');
}

{
    Frozen::_xop_reset();
    my $r = $fz->root;
    ok($r, 'root returns a handle');
    my (undef, $hits) = Frozen::_xop_stats();
    is($hits, 1, 'root took the fast path too');
}

{
    Frozen::_xop_reset();
    my $s = $fz->find('x');
    ok(defined $s, 'find returns a slot');
    my (undef, $hits) = Frozen::_xop_stats();
    is($hits, 1, 'find took the fast path');
}

# ---- every hooked door fires, and agrees with its XSUB ------------------
#
# `get` alone was not enough: a caller holding a handle and descending pays a
# frame per segment, which is most of what descent costs. Ten doors are hooked
# and each is asserted separately, because a door that silently stopped firing
# would still return right answers.

{
    my $root = $fz->root;
    my $h    = $fz->child($root, 'a');

    my @doors = (
        ['fetch',  sub { ($fz->fetch($root, 'x'))[0] },   'top'   ],
        ['child',  sub { defined $fz->child($root, 'a') }, 1      ],
        ['exists', sub { $fz->exists($root, 'x') ? 1 : 0 }, 1     ],
        ['count',  sub { $fz->count($root) },              3      ],
        ['kind',   sub { $fz->kind($root) },               'hash' ],
        ['value',  sub { $fz->value($fz->child($h, 'b')) },
                   undef ],
    );

    for my $d (@doors) {
        my ($name, $code, $want) = @$d;
        Frozen::_xop_reset();
        my $got = $code->();
        my (undef, $hits, $miss) = Frozen::_xop_stats();
        cmp_ok($hits, '>', 0, "$name took the fast path");
        is($miss, 0, "$name did not delegate");
        is($got, $want, "$name returned the right answer") if defined $want;
    }
}

# ---- an array door ------------------------------------------------------

{
    my $ar = Frozen->attach(Frozen->freeze({ l => ['p', 'q', 'r'] }));
    Frozen::_xop_reset();
    my $lh = $ar->child($ar->root, 'l');
    is($ar->kind($lh), 'array', 'an array handle');
    is(($ar->at($lh, 1))[0], 'q', 'at() indexes it');
    my @past = $ar->at($lh, 99);
    is(scalar @past, 0, 'and past the end is an empty list, as the XSUB gives');
    my (undef, $hits, $miss) = Frozen::_xop_stats();
    cmp_ok($hits, '>=', 4, 'the array doors fired');
    is($miss, 0, 'without delegating');
}

# ---- a bad handle still croaks, through the op --------------------------
#
# The op validates the handle exactly as the XSUB does, and where it cannot it
# hands the call back rather than guessing.

{
    for my $bad (0x7FFFFFF7, 0x7FFFFFF8) {
        eval { $fz->count($bad); 1 };
        ok($@, "a forged handle ($bad) is refused through the op too");
    }
}

# ---- the op and the XSUB agree ------------------------------------------
#
# Two implementations of one door is two things to keep in step, so this
# compares them on every shape rather than on one.

{
    for my $p ('a.b.c', 'x', 'a.b', 'a', 'nope', 'a.nope', '', 'n') {
        my @via_op = $fz->get($p);
        # The direct call is not hooked (no method_named), so it is the XSUB.
        my @via_xs = Frozen::get($fz, $p);
        is_deeply(\@via_op, \@via_xs, "op and XSUB agree on '$p'");
    }
}

# ---- the guard: a class that is not ours is untouched --------------------
#
# The hook sees every `->get` in the program, so this is the assertion that
# matters most: somebody else's get must behave exactly as it did.

{
    package Other::Thing;
    sub new  { bless { v => 'other' }, shift }
    sub get  { my ($s, $k) = @_; return "other:$k" }
    sub root { 'other-root' }
    sub find { 'other-find' }
}

{
    Frozen::_xop_reset();
    my $o = Other::Thing->new;
    is($o->get('k'), 'other:k', "another class's get is unaffected");
    is($o->root,     'other-root', "...and its root");
    is($o->find('z'),'other-find', "...and its find");
    my (undef, $hits, $miss) = Frozen::_xop_stats();
    is($hits, 0, 'the fast path was not taken for it');
    cmp_ok($miss, '>=', 3, 'it delegated to the ordinary call every time');
}

# A hashref that is not blessed at all, and a plain string invocant.
{
    Frozen::_xop_reset();
    eval { my $x = {}; $x->get('k'); 1 };
    ok($@, 'an unblessed ref still dies the way it always did');
    eval { my $x = 'Other::Thing'; my $v = $x->get('k');
           is($v, 'other:k', 'a class-name invocant still works'); 1 } or diag $@;
}

# ---- a closed container falls through to the XSUB's croak ---------------

{
    my $tmp = Frozen->attach(Frozen->freeze({ k => 'v' }));
    $tmp->close;
    eval { $tmp->get('k'); 1 };
    like($@, qr/closed/, 'a closed container croaks, not crashes');
}

# ---- the op is still an entersub to every dumper ------------------------
#
# op_ppaddr is swapped and op_type is left alone, so B::Concise and B::Deparse
# keep working. A dist that replaced the op type would break every debugger.

SKIP: {
    eval { require B::Deparse; 1 } or skip 'no B::Deparse', 1;
    my $sub = sub { my $f = shift; return $f->get('a.b.c') };
    my $src = B::Deparse->new->coderef2text($sub);
    like($src, qr/->get\(/, 'B::Deparse still shows an ordinary method call');
}

done_testing;
