#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use HAMT::Map;

# Who is destroyed and when. Values are objects whose DESTROY counts, so a
# leak is a count that is short and a double release is one that is over -
# on any perl, with nothing installed.

{
    package Local::Counted;
    our ($made, $destroyed, %alive) = (0, 0);
    sub new { my $o = bless { id => ++$made }, shift; $alive{ $o->{id} } = 1; $o }
    sub DESTROY { $destroyed++; delete $alive{ $_[0]{id} } }
    sub reset { ($made, $destroyed, %alive) = (0, 0) }
}
sub alive { scalar keys %Local::Counted::alive }

# ---- one map ----------------------------------------------------------------
Local::Counted->reset;
{
    my $m = HAMT::Map->new(map { ("k$_" => Local::Counted->new) } 1 .. 100);
    is(alive(), 100, 'a map keeps its 100 values alive');
    is($Local::Counted::destroyed, 0, 'and none was destroyed on the way in');
}
is(alive(), 0, 'dropping the map destroys them all');
is($Local::Counted::destroyed, 100, 'each exactly once');

# ---- a value outlives the map while something else holds it ------------------
Local::Counted->reset;
{
    my $held;
    {
        my $m = HAMT::Map->new(k => Local::Counted->new);
        $held = $m->get('k');
    }
    is(alive(), 1, 'a value taken out of a map survives the map');
    undef $held;
    is(alive(), 0, 'and goes when its last holder does');
}

# ---- a chain of versions, dropped three ways ---------------------------------
#
# Version i holds keys 1..i, so value i is held by versions i..N and must go
# exactly when the last of those does.
for my $order (qw(forward reverse random)) {
    Local::Counted->reset;
    my $n = 1000;
    my @v = (HAMT::Map->new);
    push @v, $v[-1]->set("k$_" => Local::Counted->new) for 1 .. $n;
    is(alive(), $n, "$order: $n versions hold $n values between them");

    my @idx = 0 .. $n;
    if ($order eq 'reverse') { @idx = reverse @idx }
    elsif ($order eq 'random') {
        my $s = 7;
        for my $i (reverse 1 .. $#idx) {
            $s = ($s * 1103515245 + 12345) % 2147483648;
            my $j = ($s >> 8) % ($i + 1);
            @idx[$i, $j] = @idx[$j, $i];
        }
    }

    my ($early, $late) = (0, 0);
    my $highest_alive = $n;
    my %dropped;
    for my $i (@idx) {
        undef $v[$i];
        $dropped{$i} = 1;
        $highest_alive-- while $highest_alive >= 0 && $dropped{$highest_alive};
        # Values 1..highest_alive are still held; everything above is not.
        my $want = $highest_alive < 0 ? 0 : $highest_alive;
        $early++ if alive() < $want;
        $late++  if alive() > $want;
    }
    is($early, 0, "$order: no value was destroyed while a version still held it");
    is($late, 0, "$order: and none outlived the last version that held it");
    is($Local::Counted::destroyed, $n, "$order: each destroyed exactly once");
}

# ---- the count CAN come up short ---------------------------------------------
#
# The same shape with one version deliberately kept: if the checks above
# could not fail, this one would not either.
Local::Counted->reset;
{
    my @v = (HAMT::Map->new);
    push @v, $v[-1]->set("k$_" => Local::Counted->new) for 1 .. 50;
    my $keep = $v[30];
    @v = ();
    is(alive(), 30, 'one kept version holds exactly its own 30 values');
    is($Local::Counted::destroyed, 20, 'and the other 20 are gone');
    undef $keep;
    is(alive(), 0, 'until it goes too');
}

# ---- replaced and deleted values ---------------------------------------------
Local::Counted->reset;
{
    my $m = HAMT::Map->new(k => Local::Counted->new, j => Local::Counted->new);
    my $m2 = $m->set(k => 'plain');
    is(alive(), 2, 'a replaced value lives on in the version that still has it');
    undef $m;
    is(alive(), 1, 'and goes with that version, leaving the one both shared');
    $m2 = $m2->delete('j');
    is(alive(), 0, 'a deleted value goes when no version holds it');
}

# ---- a DESTROY that uses the library -----------------------------------------
{
    package Local::Meddler;
    our ($ran, $result, $check, $target);
    sub new { bless [], shift }
    sub DESTROY {
        $ran++;
        my $next = $target->set("from-destroy-$ran" => $ran);
        $result = $next->get("from-destroy-$ran");
        $check  = $next->_check;
        $target = $next;
    }
}
{
    $Local::Meddler::target = HAMT::Map->new(map { ("t$_" => $_) } 1 .. 200);
    my $m = HAMT::Map->new(map { ("k$_" => $_) } 1 .. 200);
    $m = $m->set(loud => Local::Meddler->new);

    undef $m;
    is($Local::Meddler::ran, 1, 'dropping a map ran a value\'s DESTROY');
    is($Local::Meddler::result, 1, 'which built a new map and read it back');
    is($Local::Meddler::check, 0, 'and that map checks out');

    # The same from inside a replace and a delete, where the map being
    # changed is the one the DESTROY writes to.
    my $t = $Local::Meddler::target->set(loud => Local::Meddler->new);
    $Local::Meddler::target = $t;
    undef $t;
    $Local::Meddler::target = $Local::Meddler::target->set(loud => 'quiet');
    is($Local::Meddler::ran, 2, 'replacing a value ran its DESTROY');
    is($Local::Meddler::target->get('loud'), 'quiet', 'and the replacement stands');
    is($Local::Meddler::target->_check, 0, 'in a map that checks out');

    $Local::Meddler::target = $Local::Meddler::target->set(loud => Local::Meddler->new);
    $Local::Meddler::target = $Local::Meddler::target->delete('loud');
    is($Local::Meddler::ran, 3, 'deleting a key ran its value\'s DESTROY');
    ok(!$Local::Meddler::target->exists('loud'), 'and the key is gone');
    is($Local::Meddler::target->_check, 0, 'from a map that checks out');
    undef $Local::Meddler::target;
}

# ---- a croak half way through leaves nothing behind ---------------------------
{
    package Local::Bomb;
    sub TIESCALAR { bless [], shift }
    sub FETCH { die "no\n" }
}
Local::Counted->reset;
{
    tie my $bomb, 'Local::Bomb';
    my $m = HAMT::Map->new(a => 1);
    eval { my $x = $m->set(x => Local::Counted->new, y => Local::Counted->new, z => $bomb) };
    is($@, "no\n", 'a set that dies on its third pair');
    is(alive(), 0, 'frees the two values it had already taken');
    eval { my $x = HAMT::Map->new(x => Local::Counted->new, z => $bomb) };
    is(alive(), 0, 'and so does a new that dies');
    is($m->count, 1, 'the receiver is untouched');
}

done_testing;
