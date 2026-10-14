#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use HAMT::Vector;

# Who is destroyed and when, and that nothing is leaked: values are objects
# whose DESTROY counts, and the library's own block count is read as well.

{
    package Local::Counted;
    our ($made, $destroyed, %alive) = (0, 0);
    sub new { my $o = bless { id => ++$made }, shift; $alive{ $o->{id} } = 1; $o }
    sub DESTROY { $destroyed++; delete $alive{ $_[0]{id} } }
    sub reset { ($made, $destroyed, %alive) = (0, 0) }
}
sub alive { scalar keys %Local::Counted::alive }

{
    package Local::Bomb;
    sub TIESCALAR { bless [], shift }
    sub FETCH { die "no\n" }
}

my $blocks = HAMT::_live_blocks();

# ---- one vector -------------------------------------------------------------
Local::Counted->reset;
{
    my $v = HAMT::Vector->new(map { Local::Counted->new } 1 .. 1100);
    is(alive(), 1100, 'a vector keeps its 1,100 values alive');
    is($Local::Counted::destroyed, 0, 'and none was destroyed on the way in');
    cmp_ok(HAMT::_live_blocks() - $blocks, '>', 30, 'in some dozens of nodes');
}
is(alive(), 0, 'dropping the vector destroys them all');
is($Local::Counted::destroyed, 1100, 'each exactly once');
is(HAMT::_live_blocks(), $blocks, 'and frees every node');

# ---- a value outlives the vector while something else holds it ----------------
Local::Counted->reset;
{
    my $held;
    { my $v = HAMT::Vector->new(Local::Counted->new); $held = $v->get(0); }
    is(alive(), 1, 'a value taken out of a vector survives the vector');
    undef $held;
    is(alive(), 0, 'and goes when its last holder does');
}

# ---- a chain of versions, dropped three ways -----------------------------------
#
# Version i holds values 1..i, so value i must go exactly when the last of
# versions i..N does.
for my $order (qw(forward reverse random)) {
    Local::Counted->reset;
    my $n = 1200;
    my @v = (HAMT::Vector->new);
    push @v, $v[-1]->push(Local::Counted->new) for 1 .. $n;
    is(alive(), $n, "$order: $n versions hold $n values between them");

    my @idx = 0 .. $n;
    if ($order eq 'reverse') { @idx = reverse @idx }
    elsif ($order eq 'random') {
        my $s = 11;
        for my $i (reverse 1 .. $#idx) {
            $s = ($s * 1103515245 + 12345) % 2147483648;
            my $j = ($s >> 8) % ($i + 1);
            @idx[$i, $j] = @idx[$j, $i];
        }
    }
    my ($early, $late, $highest, %dropped) = (0, 0, $n);
    for my $i (@idx) {
        undef $v[$i];
        $dropped{$i} = 1;
        $highest-- while $highest >= 0 && $dropped{$highest};
        my $want = $highest < 0 ? 0 : $highest;
        $early++ if alive() < $want;
        $late++  if alive() > $want;
    }
    is($early, 0, "$order: no value was destroyed while a version still held it");
    is($late, 0, "$order: and none outlived the last version that held it");
    is($Local::Counted::destroyed, $n, "$order: each destroyed exactly once");
    is(HAMT::_live_blocks(), $blocks, "$order: and every node is freed");
}

# ---- the count CAN come up short ------------------------------------------------
Local::Counted->reset;
{
    my @v = (HAMT::Vector->new);
    push @v, $v[-1]->push(Local::Counted->new) for 1 .. 100;
    my $keep = $v[40];
    @v = ();
    is(alive(), 40, 'one kept version holds exactly its own 40 values');
    cmp_ok(HAMT::_live_blocks(), '>', $blocks, 'and its nodes');
    undef $keep;
    is(alive(), 0, 'until it goes too');
    is(HAMT::_live_blocks(), $blocks, 'and they with it');
}

# ---- set and pop ----------------------------------------------------------------
Local::Counted->reset;
{
    my $v  = HAMT::Vector->new(map { Local::Counted->new } 1 .. 70);
    my $v2 = $v->set(3, 'plain')->set(69, 'plain');
    is(alive(), 70, 'a replaced value lives on in the version that still has it');
    my $v3 = $v2->pop;
    undef $v;
    is(alive(), 68, 'and goes with that version, leaving what the others share');
    undef $v2; undef $v3;
    is(alive(), 0, 'all gone with the last');

    my $t = HAMT::Vector->new(map { Local::Counted->new } 1 .. 70)->transient;
    $t->set(5, 'plain');
    is(alive(), 69, 'a value replaced in a transient is destroyed at once');
    $t->pop for 1 .. 40;
    is(alive(), 29, 'and so are values popped from it, across the pull-up of a leaf');
    $t->push(Local::Counted->new) for 1 .. 10;
    is(alive(), 39, 'new ones are held');
    undef $t;
    is(alive(), 0, 'a transient never closed frees everything when it goes');
    is(HAMT::_live_blocks(), $blocks, 'nodes included');
}

# ---- a DESTROY that uses the vector it is being released from ----------------------
{
    package Local::Meddler;
    our ($ran, $target, $check, $err, $count_seen);
    sub new { bless [], shift }
    sub DESTROY {
        $ran++;
        eval { $count_seen = $target->count; $target->push("from-destroy-$ran"); $check = $target->_check; 1 }
            or $err = $@;
    }
}
{
    my $t = HAMT::Vector->new(1 .. 100)->transient;
    $Local::Meddler::target = $t;
    $t->set(50, Local::Meddler->new);
    $t->set(50, 'quiet');
    is($Local::Meddler::ran, 1, 'replacing a value in a transient ran its DESTROY');
    is($Local::Meddler::err, undef, 'which pushed onto the same transient without error');
    is($Local::Meddler::check, 0, 'leaving it in a state that checks out');
    is($t->get(100), 'from-destroy-1', 'with its push in place');
    is($t->get(50), 'quiet', 'and the replacement too');

    $t->push(Local::Meddler->new);
    $t->pop;
    is($Local::Meddler::ran, 2, 'popping a value ran its DESTROY');
    is($Local::Meddler::count_seen, 101, 'which saw the vector already without it');
    is($t->get(-1), 'from-destroy-2', 'and pushed in its place');
    is($t->persistent->_check, 0, 'and the vector it closes into checks out');
    undef $Local::Meddler::target;
}

# ---- a croak half way through leaves nothing behind -----------------------------------
Local::Counted->reset;
{
    tie my $bomb, 'Local::Bomb';
    my $v = HAMT::Vector->new(1);
    eval { my $x = $v->push(Local::Counted->new, Local::Counted->new, $bomb) };
    is($@, "no\n", 'a push that dies on its third value');
    is(alive(), 0, 'frees the two it had already taken');
    eval { my $x = HAMT::Vector->new(Local::Counted->new, $bomb) };
    is(alive(), 0, 'and so does a new that dies');
    is($v->count, 1, 'the receiver is untouched');
}
# ---- cutting and joining ------------------------------------------------------------------
Local::Counted->reset;
{
    my $before = HAMT::_live_blocks();
    {
        my $v = HAMT::Vector->new(map { Local::Counted->new } 1 .. 3000);
        my $w = HAMT::Vector->new(map { Local::Counted->new } 1 .. 2000);
        is(alive(), 5000, 'two vectors of counted values');
        my @r = ($v->concat($w), $w->concat($v), $v->slice(100, 2500), $v->slice(2990), $v->remove(10, 2900),
                 $v->insert(1500, Local::Counted->new, Local::Counted->new), $v->concat($v)->slice(2000, 2000));
        is(alive(), 5002, 'seven results built from them hold only the two values that were new');
        undef $v; undef $w;
        is(alive(), 5002, 'and keep everything alive that any of them still holds');
        @r = @r[2, 4];
        is(alive(), 2600, 'two kept, a slice of 2,500 and the 100 a removal left, which have nothing in common');
        eval { my $x = $r[0]->insert(5, Local::Counted->new, do { tie my $b, 'Local::Bomb'; $b }) };
        is($@, "no\n", 'an insert that dies on its second value');
        is(alive(), 2600, 'frees the one it had taken');
    }
    is(alive(), 0, 'and when the last goes, so does every value');
    is(HAMT::_live_blocks(), $before, 'and every node');
}

# ---- the walks that hold a vector let go of it ------------------------------------------
{
    my $before = HAMT::_live_blocks();
    {
        my $v = HAMT::Vector->new(1 .. 3000);
        my $w = $v->set(1500, 'x');
        my $n = 0;
        $v->each(sub { $n++ });
        eval { $v->each(sub { die "stop\n" }) } for 1 .. 5;
        $v->equals($w); $v->equals($w, sub { 1 }); $v->equals(HAMT::Vector->new(1 .. 3000));
        eval { $v->equals($w, sub { die "cmp\n" }) } for 1 .. 5;
        is($n, 3000, 'a vector walked, walked to a die, and compared four ways');
    }
    is(HAMT::_live_blocks(), $before, 'leaves nothing held once it is gone');
}

is(HAMT::_live_blocks(), $blocks, 'and after all of it the library holds what it held at the start');


done_testing;
