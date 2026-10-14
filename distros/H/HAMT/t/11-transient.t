#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Config;
use Scalar::Util qw(refaddr blessed);
use HAMT::Map;

# A transient is a map that IS changed in place. What has to hold: the map it
# was opened from never sees it, the map it is closed into never changes
# afterwards, and nothing reaches the trie through a transient once closed.

END { HAMT::_hash_bits(64) }

{
    package Local::Counted;
    our %alive; our $made = 0;
    sub new { my $o = bless { id => ++$made }, shift; $alive{ $o->{id} } = 1; $o }
    sub DESTROY { delete $alive{ $_[0]{id} } }
}
sub alive { scalar keys %Local::Counted::alive }
sub as_hash { +{ $_[0]->pairs } }

# ---- the surface ------------------------------------------------------------
{
    my $m = HAMT::Map->new(a => 1, b => 2);
    my $t = $m->transient;
    isa_ok($t, 'HAMT::Map::Transient');
    is($t->count, 2, 'a transient starts with what the map holds');
    is($t->get('a'), 1, 'and reads it');
    ok($t->exists('b') && !$t->exists('zz'), 'exists works');

    is(refaddr($t->set(c => 3)), refaddr($t), 'set returns the transient itself');
    is($t->get('c'), 3, 'which now holds the new pair');
    is($t->count, 3, 'and counts it');
    is(refaddr($t->delete('a')), refaddr($t), 'delete returns the transient itself');
    ok(!$t->exists('a'), 'and the key is gone from it');
    $t->set(d => 4, e => 5)->delete('b', 'nope')->set(c => 'three');
    is($t->count, 3, 'calls chain, with several pairs or keys at a time');
    is($t->_check, 0, 'and it checks out as it goes');

    is_deeply(as_hash($m), { a => 1, b => 2 }, 'the map it was opened from has seen none of it');

    my $p = $t->persistent;
    isa_ok($p, 'HAMT::Map');
    is_deeply(as_hash($p), { c => 'three', d => 4, e => 5 }, 'persistent returns a map of what the transient held');
    is($p->_check, 0, 'that checks out');
    is_deeply(as_hash($m), { a => 1, b => 2 }, 'and the original is still untouched');
}

# ---- no warning in void context: there, changing it is the point --------------
{
    my @w;
    local $SIG{__WARN__} = sub { push @w, @_ };
    my $t = HAMT::Map->new->transient;
    $t->set(a => 1);
    $t->delete('a');
    is(scalar @w, 0, 'set and delete on a transient do not warn in void context');
}

# ---- closed ------------------------------------------------------------------
{
    my $t = HAMT::Map->new(a => 1)->transient;
    my $p = $t->persistent;
    for my $call ([ set => a => 2 ], [ delete => 'a' ], [ get => 'a' ], [ exists => 'a' ],
                  [ 'count' ], [ 'persistent' ]) {
        my ($method, @args) = @$call;
        ok(!eval { my @r = $t->$method(@args); 1 }, "$method on a closed transient croaks");
        like($@, qr/^HAMT::Map::Transient::\Q$method\E: this transient is closed/, 'by name');
    }
    is_deeply(as_hash($p), { a => 1 }, 'and the map it was closed into is unharmed');

    for my $thing ('x', undef, {}, HAMT::Map->new, bless({}, 'HAMT::Map::Transient'),
                   bless(\(my $n = 12345), 'HAMT::Map::Transient')) {
        no warnings 'uninitialized';
        ok(!eval { HAMT::Map::Transient::count($thing); 1 }
           && $@ =~ /^HAMT::Map::Transient::count: not a transient/,
           'something that is not a transient is refused');
    }
    ok(!eval { HAMT::Map::get($t, 'a'); 1 } && $@ =~ /not a map/, 'a transient is not a map');
    my $open = HAMT::Map->new->transient;
    ok(!eval { $open->set('odd'); 1 }, 'an odd list croaks');
    like($@, qr/^HAMT::Map::Transient::set: odd number of arguments/, 'by name');
}

# ---- aliasing: the cases an over-eager in-place edit would break --------------
for my $bits (64, 5, 0) {
    HAMT::_hash_bits($bits);
    my %base = map { ("key$_" => $_) } 1 .. 200;

    # A map made by persistent, then a second transient opened on it.
    my $t1 = HAMT::Map->new(%base)->transient;
    $t1->set(extra => 1);
    my $a = $t1->persistent;
    my %a = (%base, extra => 1);
    my $t2 = $a->transient;
    $t2->set(key1 => 'changed', more => 1)->delete('key2');
    is_deeply(as_hash($a), \%a, "$bits bits: a map closed out of one transient is not changed by the next");
    my $b = $t2->persistent;
    is($b->get('key1'), 'changed', "$bits bits: which holds its own changes");
    ok(!$b->exists('key2') && $a->exists('key2'), "$bits bits: on its own side");

    # A persistent update of a map, then a transient on the result.
    my $c = $a->set(k => 1);
    my $t3 = $c->transient;
    $t3->set(k => 2)->set(key3 => 'x');
    is($a->exists('k') ? 'has k' : 'no k', 'no k', "$bits bits: the grandparent is untouched");
    is($c->get('k'), 1, "$bits bits: the parent is untouched");
    is($c->get('key3'), 3, "$bits bits: in every key");
    is($t3->get('k'), 2, "$bits bits: and the transient has its own value");

    # Two transients on one map do not see each other.
    my ($x, $y) = ($a->transient, $a->transient);
    $x->set(who => 'x')->delete('key5');
    $y->set(who => 'y')->delete('key6');
    is($x->get('who'), 'x', "$bits bits: two transients on one map: the first keeps its own");
    is($y->get('who'), 'y', "$bits bits: and the second its own");
    ok(!$x->exists('key5') && $x->exists('key6') && $y->exists('key5') && !$y->exists('key6'),
       "$bits bits: neither sees the other's deletes");
    ok(!$a->exists('who') && $a->exists('key5') && $a->exists('key6'),
       "$bits bits: and the map sees neither");
    is($a->_check + $x->_check + $y->_check, 0, "$bits bits: all three check out");

    # A value read out of a transient outlives being replaced in it.
    my $t4 = HAMT::Map->new(k => 'first')->transient;
    my $held = \ $t4->get('k');
    $t4->set(k => 'second');
    is($$held, 'first', "$bits bits: a scalar read from a transient survives being replaced there");

    undef $_ for $t1, $t2, $t3, $t4, $a, $b, $c, $x, $y;
}
HAMT::_hash_bits(64);

# ---- the model test, through a transient --------------------------------------
for my $bits (64, 10, 5, 0) {
    HAMT::_hash_bits($bits);
    my $universe = $bits ? 1500 : 120;
    my $steps    = $bits ? 15_000 : 4_000;
    my $state = 99;
    my $rnd = sub { $state = ($state * 1103515245 + 12345) % 2147483648; ($state >> 8) % $_[0] };

    my $t = HAMT::Map->new->transient;
    my (%h, @kept, $bad);
    for my $step (1 .. $steps) {
        my $key = 'k' . $rnd->($universe);
        my $op  = $rnd->(10);
        if ($op < 5)    { $t->set($key => "v$step"); $h{$key} = "v$step" }
        elsif ($op < 8) { $t->delete($key); delete $h{$key}; $bad ||= "step $step: check " . $t->_check if $t->_check }
        else {
            my ($got, $want) = ($t->get($key), $h{$key});
            $bad ||= "step $step: get($key)" if defined $got != defined $want || (defined $got && $got ne $want);
        }
        $bad ||= "step $step: count" if $t->count != keys %h;

        # Close, keep, reopen: the kept map must never move again.
        if ($step % 250 == 0) {
            my $p = $t->persistent;
            push @kept, [ $p, { %h }, $step ];
            $t = $p->transient;
        }
        last if $bad;
    }
    ok(!$bad, "$steps random operations through a transient at $bits hash bits") or diag($bad);
    my $final = $t->persistent;
    is_deeply(as_hash($final), \%h, "$bits bits: the transient ends agreeing with the hash");
    is($final->_check, 0, "$bits bits: and checks out");
    ok($final->equals(HAMT::Map->new(%h)), "$bits bits: equal to the same map built in one go");

    my $moved = 0;
    for my $k (@kept) {
        my ($p, $was, $step) = @$k;
        next if $p->count == keys %$was && $p->_check == 0 && $p->equals(HAMT::Map->new(%$was));
        $moved++;
        diag("the map closed at step $step has changed");
        last;
    }
    is($moved, 0, "$bits bits: none of " . @kept . ' maps closed along the way has changed since');
    @kept = ();
    undef $_ for $t, $final;
}
HAMT::_hash_bits(64);

# ---- subclasses ----------------------------------------------------------------
{
    package Local::Sub; our @ISA = ('HAMT::Map');
}
{
    my $t = Local::Sub->new(a => 1)->transient;
    is(blessed($t), 'HAMT::Map::Transient', 'a transient on a subclass is a plain transient');
    isa_ok($t->set(b => 2)->persistent, 'Local::Sub', 'and persistent returns the class it was opened from');
}

# ---- lifetime -------------------------------------------------------------------
{
    my $before = alive();
    {
        my $t = HAMT::Map->new(map { ("k$_" => Local::Counted->new) } 1 .. 100)->transient;
        $t->set("k$_" => Local::Counted->new) for 1 .. 50;          # 50 replaced in place
        is(alive() - $before, 100, 'a value replaced in a transient is destroyed at once');
        $t->delete("k$_") for 51 .. 75;
        is(alive() - $before, 75, 'and so is one deleted from it');
        $t->set("n$_" => Local::Counted->new) for 1 .. 25;
        is(alive() - $before, 100, 'new ones are held');
    }
    is(alive(), $before, 'a transient that is never closed frees everything when it goes');

    {
        my $m = HAMT::Map->new(map { ("k$_" => Local::Counted->new) } 1 .. 100);
        my $t = $m->transient;
        $t->set("k$_" => 'plain') for 1 .. 100;
        is(alive() - $before, 100, 'a value replaced in a transient lives on in the map it came from');
        my $p = $t->persistent;
        undef $m;
        is(alive(), $before, 'and goes when that map does');
        is($p->get('k1'), 'plain', 'leaving the new map as it was');
    }
    {
        my $p = HAMT::Map->new(k => Local::Counted->new)->transient->persistent;
        is(alive() - $before, 1, 'a value passes through a transient into the map it becomes');
    }
    is(alive(), $before, 'and goes with that map');
}

# ---- a DESTROY that uses the transient it is being released from -----------------
{
    package Local::Meddler;
    our ($ran, $target, $check, $err);
    sub new { bless [], shift }
    sub DESTROY {
        $ran++;
        eval { $target->set("from-destroy-$ran" => $ran); $check = $target->_check; 1 }
            or $err = $@;
    }
}
{
    my $t = HAMT::Map->new(map { ("k$_" => $_) } 1 .. 200)->transient;
    $Local::Meddler::target = $t;
    $t->set(loud => Local::Meddler->new);
    $t->set(loud => 'quiet');
    is($Local::Meddler::ran, 1, 'replacing a value in a transient ran its DESTROY');
    is($Local::Meddler::err, undef, 'which wrote to the same transient without error');
    is($Local::Meddler::check, 0, 'leaving it in a state that checks out');
    is($t->get('from-destroy-1'), 1, 'with its write in place');
    is($t->get('loud'), 'quiet', 'and the replacement too');

    $t->set(loud => Local::Meddler->new);
    $t->delete('loud');
    is($Local::Meddler::ran, 2, 'deleting a key ran its value\'s DESTROY');
    ok(!$t->exists('loud') && $t->get('from-destroy-2') == 2, 'with the same result');
    is($t->count, 202, 'and the count is right');
    is($t->persistent->_check, 0, 'and the map it closes into checks out');
    undef $Local::Meddler::target;
}

# A value whose magic closes the transient in the middle of a set.
{
    package Local::Closer;
    our ($t, $closed);
    sub TIESCALAR { bless [], shift }
    sub FETCH { $closed = $t->persistent; 'value' }
}
{
    my $t = HAMT::Map->new(a => 1)->transient;
    $Local::Closer::t = $t;
    tie my $v, 'Local::Closer';
    ok(!eval { $t->set(x => 1, y => $v, z => 3); 1 }, 'a value that closes the transient as it is read stops the set');
    like($@, qr/this transient is closed/, 'with the closed error');
    is($Local::Closer::closed->_check, 0, 'and the map it closed into checks out');
    ok($Local::Closer::closed->exists('x') && !$Local::Closer::closed->exists('z'),
       'holding what had been set before it closed and nothing after');
    undef $Local::Closer::t; undef $Local::Closer::closed;
}

# ---- threads --------------------------------------------------------------------
SKIP: {
    skip 'this perl has no ithreads', 2 unless $Config{useithreads};
    skip 'threads.pm does not load', 2 unless eval { require threads; 1 };
    is(HAMT::Map::Transient->CLONE_SKIP, 1, 'the transient class asks not to be cloned');
    my $t = HAMT::Map->new(a => 1)->transient;
    my ($state) = threads->create({ context => 'list' }, sub {
        return eval { $t->count; 1 } ? 'usable' : 'dead';
    })->join;
    is($state, 'dead', 'a new thread does not get the parent\'s transient');
}

done_testing;
