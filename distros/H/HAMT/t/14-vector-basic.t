#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Config;
use Scalar::Util qw(refaddr blessed readonly);
use HAMT::Vector;

# HAMT::Vector, one method at a time, and at every length where its shape
# changes.

my $empty = HAMT::Vector->new;
isa_ok($empty, 'HAMT::Vector');
is($empty->count, 0, 'a new vector is empty');
is_deeply([ $empty->list ], [], 'with nothing in it');
is($empty->get(0), undef, 'get on an empty vector is undef');
is($empty->first, undef, 'and so is first');
is($empty->last, undef, 'and last');
is($empty->_check, 0, 'and it checks out');

my $v = HAMT::Vector->new(qw(a b c));
is($v->count, 3, 'new takes a list');
is_deeply([ $v->list ], [qw(a b c)], 'and keeps its order');
is($v->get(0), 'a', 'get 0');
is($v->get(2), 'c', 'get 2');
is($v->get(-1), 'c', 'a negative index counts from the end');
is($v->get(-3), 'a', 'all the way to the start');
is($v->get(3), undef, 'past the end is undef');
is($v->get(-4), undef, 'and so is before the start');
is($v->first, 'a', 'first');
is($v->last, 'c', 'last');
is($v->get('1'), 'b', 'an index may be a string of digits');
is($v->get(1.9), 'b', 'and a fraction is cut down, as an array index is');

# ---- push ---------------------------------------------------------------------
my $v2 = $v->push('d', 'e');
isa_ok($v2, 'HAMT::Vector');
is_deeply([ $v2->list ], [qw(a b c d e)], 'push returns a vector with the values added');
is_deeply([ $v->list ], [qw(a b c)], 'and the receiver is unchanged');
is(refaddr($v->push), refaddr($v), 'pushing nothing is the receiver');
is($v->push(undef)->count, 4, 'undef is a value');
is($v->push(undef)->get(3), undef, 'that reads back as undef');

# ---- set ----------------------------------------------------------------------
my $v3 = $v2->set(0, 'A');
is_deeply([ $v3->list ], [qw(A b c d e)], 'set replaces one value');
is_deeply([ $v2->list ], [qw(a b c d e)], 'and the receiver is unchanged');
is($v2->set(-1, 'E')->get(4), 'E', 'set takes a negative index');
is(refaddr($v2->set(1, $v2->get(1))), refaddr($v2), 'setting an index to the scalar it holds is the receiver');
isnt(refaddr($v2->set(1, 'b')), refaddr($v2), 'an equal value from elsewhere is a new vector');
for my $bad (5, 6, -6, 100) {
    ok(!eval { my $r = $v2->set($bad, 'x'); 1 }, "set at $bad croaks: there is no extending by set");
    like($@, qr/^HAMT::Vector::set: index \Q$bad\E is out of range for 5 elements/, 'saying which and how many');
}
ok(!eval { my $r = $empty->set(0, 'x'); 1 }, 'set on an empty vector croaks');

# ---- pop ----------------------------------------------------------------------
my $v4 = $v2->pop;
is_deeply([ $v4->list ], [qw(a b c d)], 'pop returns the vector without its last value');
is_deeply([ $v2->list ], [qw(a b c d e)], 'and the receiver is unchanged');
is($v2->last, 'e', 'last reads what pop is about to drop');
is($v->pop->pop->pop->count, 0, 'popping everything leaves an empty vector');
is(refaddr($empty->pop), refaddr($empty), 'popping an empty vector is the receiver');
is($v->pop->pop->pop->push('z')->get(0), 'z', 'an emptied vector can be pushed to again');

# ---- values of every kind ------------------------------------------------------
{
    my $aref = [1, 2];
    my $obj  = bless {}, 'Local::Thing';
    my $k = HAMT::Vector->new(undef, 0, '', -7, 1.5, 'text', $aref, sub { 42 }, $obj, chr(0x263a));
    is($k->count, 10, 'ten kinds of value');
    is($k->get(0), undef, 'undef');
    is($k->get(1), 0, 'zero');
    is($k->get(2), '', 'the empty string');
    is($k->get(3), -7, 'a negative integer');
    is($k->get(4), 1.5, 'a fraction');
    is($k->get(5), 'text', 'a string');
    is(refaddr($k->get(6)), refaddr($aref), 'an array reference is the same array');
    is($k->get(7)->(), 42, 'a code reference still calls');
    is(blessed($k->get(8)), 'Local::Thing', 'an object keeps its class');
    is($k->get(9), chr(0x263a), 'a wide character');
}

# ---- values are read-only, and shallow ------------------------------------------
{
    my $list = [1];
    my $r = HAMT::Vector->new('text', $list);
    ok(readonly($r->get(0)), 'a stored value is read-only');
    ok(!eval { $_ = 'poked' for $r->get(0); 1 }, 'and cannot be written through get');
    like($@, qr/Modification of a read-only value/, "with perl's own message");
    ok(!eval { $_ = 'poked' for $r->list; 1 }, 'nor through list');
    ok(!eval { $_ = 'poked' for $r->first; 1 } && !eval { $_ = 'poked' for $r->last; 1 }, 'nor first, nor last');
    is($r->get(0), 'text', 'and nothing changed');
    my $mine = 'caller';
    my $s = $r->push($mine);
    ok(!readonly($mine), "the caller's variable is not made read-only");
    $mine = 'changed';
    is($s->get(2), 'caller', 'and changing it does not reach the vector');
    push @{ $r->get(1) }, 2;
    is_deeply($r->get(1), [1, 2], 'a stored array can still be pushed to: the vector is shallow');
    ok(eval { $_ = 'fine' for $r->get(99); 1 }, 'the undef for a missing index is writable');
}

# ---- list, to_array, each -------------------------------------------------------
{
    my @src = map { "v$_" } 0 .. 499;
    my $big = HAMT::Vector->new(@src);
    is_deeply([ $big->list ], \@src, 'list returns every value in order');
    is(scalar($big->list), 500, 'and the count in scalar context');
    my $arr = $big->to_array;
    is(ref $arr, 'ARRAY', 'to_array returns an array reference');
    is_deeply($arr, \@src, 'holding every value in order');
    $arr->[0] = 'changed'; push @$arr, 'more';
    is($big->get(0), 'v0', 'writing to it does not reach the vector');
    is($big->count, 500, 'nor does adding to it');
    isnt(refaddr($big->to_array), refaddr($arr), 'each call makes a new array');
    is_deeply($empty->to_array, [], 'an empty vector is an empty array');

    my (@vals, @idx);
    is(refaddr($big->each(sub { push @vals, $_[0]; push @idx, $_[1] })), refaddr($big), 'each returns the vector');
    is_deeply(\@vals, \@src, 'and calls the sub with each value in order');
    is_deeply(\@idx, [ 0 .. 499 ], 'and its index');
    my $n = 0;
    ok(!eval { $big->each(sub { die "stop\n" if ++$n == 40 }); 1 } && $@ eq "stop\n" && $n == 40,
       'a die in the sub stops the walk and passes through');
    my $doomed = HAMT::Vector->new(1 .. 100);
    my $calls = 0;
    $doomed->each(sub { undef $doomed; $calls++ });
    is($calls, 100, 'a walk finishes over a vector its own sub let go of');
    my $walked = $big;
    $big->each(sub { $walked = $walked->push($_[1]) });
    is($walked->count, 1000, 'a sub that pushes to the vector being walked gets new vectors');
    is($big->count, 500, 'and the walk is over the one it started on');
    ok(!eval { $big->each('x'); 1 } && $@ =~ /^HAMT::Vector::each: not a code reference/, 'each refuses a non-sub');
    my ($low, $high);
    $big->each(sub { my $t = HAMT::_tmps_ix(); $low //= $t; $high //= $t; $low = $t if $t < $low; $high = $t if $t > $high });
    cmp_ok($high - $low, '<=', 2, '500 calls hold no more temporaries than one does');

    # The index comes in one scalar written over each call, unless the sub
    # kept it: a sub that keeps references ends up with 500 different ones.
    my @irefs;
    $big->each(sub { push @irefs, \$_[1] });
    is_deeply([ map { $$_ } @irefs ], [ 0 .. 499 ], 'a sub that keeps a reference to every index keeps the right ones');
    my @over;
    $big->each(sub { push @over, $_[1]; $_[1] = 'x' });
    is_deeply(\@over, [ 0 .. 499 ], 'and writing over the index does not change the next');
}

# ---- every length where the shape changes -----------------------------------------
{
    my @edges = (0, 1, 31, 32, 33, 63, 64, 65, 1023, 1024, 1025, 1055, 1056, 1057, 1088, 1089,
                 32767, 32768, 32769, 32799, 32800, 32801);
    my %edge = map { ($_ => 1) } @edges;
    my $t = HAMT::Vector->new->transient;
    my (@kept, $bad);
    for my $n (0 .. 32801) {
        if ($edge{$n}) {
            my $p = $t->persistent;
            $bad ||= "length $n: rule " . $p->_check if $p->_check;
            $bad ||= "length $n: count " . $p->count if $p->count != $n;
            if ($n) {
                $bad ||= "length $n: first" if $p->first != 0;
                $bad ||= "length $n: last"  if $p->last != $n - 1;
                $bad ||= "length $n: middle" if $p->get(int($n / 2)) != int($n / 2);
            }
            push @kept, [ $n, $p ];
            $t = $p->transient;
        }
        $t->push($n);
    }
    ok(!$bad, 'built to 32,801 one push at a time, right at all ' . @edges . ' lengths where the shape changes')
        or diag($bad);

    # Each kept vector, updated every way, against the same done to an array.
    my $wrong;
    for my $k (@kept) {
        my ($n, $p) = @$k;
        my @a = (0 .. $n - 1);
        for my $op (qw(push pop set-first set-last set-mid)) {
            next if $n == 0 && $op ne 'push';
            my @b = @a;
            my $q;
            if    ($op eq 'push')      { push @b, 'x'; $q = $p->push('x') }
            elsif ($op eq 'pop')       { pop @b; $q = $p->pop }
            elsif ($op eq 'set-first') { $b[0] = 'x'; $q = $p->set(0, 'x') }
            elsif ($op eq 'set-last')  { $b[-1] = 'x'; $q = $p->set(-1, 'x') }
            else                       { $b[ int($n / 2) ] = 'x'; $q = $p->set(int($n / 2), 'x') }
            $wrong ||= "length $n, $op: rule " . $q->_check if $q->_check;
            $wrong ||= "length $n, $op: count" if $q->count != @b;
            if ($n <= 1100) { $wrong ||= "length $n, $op: contents" if join(',', $q->list) ne join(',', @b) }
            else {
                for my $i (0, 1, 31, 32, 1023, 1024, $#b - 33, $#b - 1, $#b) {
                    next if $i < 0 || $i > $#b;
                    $wrong ||= "length $n, $op: index $i" if $q->get($i) ne $b[$i];
                }
            }
            $wrong ||= "length $n, $op: the receiver moved"
                if $p->count != $n || ($n && ($p->first != 0 || $p->last != $n - 1));
            last if $wrong;
        }
        last if $wrong;
    }
    ok(!$wrong, 'each of them pushed, popped and set at both ends and the middle, receiver unchanged')
        or diag($wrong);

    # And back down to nothing.
    my $down = $kept[-1][1]->transient;
    my $low;
    for my $n (reverse 1 .. 32801) {
        $down->pop;
        if ($edge{ $n - 1 }) {
            my $p = $down->persistent;
            $low ||= 'length ' . ($n - 1) . ': rule ' . $p->_check if $p->_check;
            $low ||= 'length ' . ($n - 1) . ': count' if $p->count != $n - 1;
            $low ||= 'length ' . ($n - 1) . ': last' if $n > 1 && $p->last != $n - 2;
            $down = $p->transient;
        }
    }
    ok(!$low, 'and popped back down through the same lengths') or diag($low);
}

# ---- equals ---------------------------------------------------------------------
{
    my $a = HAMT::Vector->new(1 .. 2000);
    ok($a->equals($a), 'a vector equals itself');
    ok($a->equals(HAMT::Vector->new(1 .. 2000)), 'and another with the same values in the same order');
    ok(!$a->equals(HAMT::Vector->new(reverse 1 .. 2000)), 'but not the same values in another order');
    ok(!$a->equals($a->set(1000, 'x')), 'nor with one value differing');
    ok(!$a->equals($a->push(2001)), 'nor one value longer');
    ok(!$a->equals($a->pop), 'nor one shorter');
    ok($a->equals($a->push(1)->pop), 'there and back again is equal');
    ok($a->set(5, 'x')->set(5, 6)->equals($a), 'and so is a value changed and changed back');
    ok(HAMT::Vector->new(1, '2')->equals(HAMT::Vector->new('1', 2)), 'values compare as strings');
    ok(!HAMT::Vector->new(1)->equals(HAMT::Vector->new('1.0')), 'so 1 and "1.0" differ');
    ok(HAMT::Vector->new(1)->equals(HAMT::Vector->new('1.0'), sub { $_[0] == $_[1] }), 'unless a sub says otherwise');
    ok(!HAMT::Vector->new([1])->equals(HAMT::Vector->new([1])), 'references compare by address');
    ok(HAMT::Vector->new(undef)->equals(HAMT::Vector->new(undef)), 'undef equals undef');
    ok(!HAMT::Vector->new(undef)->equals(HAMT::Vector->new('')), 'and not the empty string');
    ok(!$a->equals(undef) && !$a->equals([1 .. 2000]) && !$a->equals('x'), 'something that is not a vector is not equal');
    ok($empty->equals(HAMT::Vector->new), 'two empty vectors are equal');
    ok(!eval { $a->equals($a->set(0, 9), sub { die "cmp\n" }); 1 } && $@ eq "cmp\n", 'a die in the sub passes through');
    ok(!eval { $a->equals($a, 'x'); 1 } && $@ =~ /^HAMT::Vector::equals: not a code reference/, 'a non-sub is refused');
}

# ---- things that are not a vector ---------------------------------------------------
for my $thing ('x', undef, [], bless([], 'HAMT::Vector'), bless(\(my $n = 12345), 'HAMT::Vector'),
               HAMT::_foreign_handle('HAMT::Vector')) {
    no warnings 'uninitialized';
    for my $method (qw(count get first last list to_array pop push set transient _check)) {
        my @args = $method eq 'get' ? (0) : $method eq 'set' ? (0, 1) : $method eq 'push' ? (1) : ();
        ok(!eval { my @r = HAMT::Vector->can($method)->($thing, @args); 1 }
           && $@ =~ /^HAMT::Vector::\Q$method\E: not a vector/, "$method refuses what is not a vector");
    }
}

# ---- void context ---------------------------------------------------------------------
{
    my @w;
    local $SIG{__WARN__} = sub { push @w, $_[0] };
    $v->push('x'); $v->set(0, 'x'); $v->pop;
    is(scalar @w, 3, 'push, set and pop warn in void context');
    like($w[$_->[0]], qr/^Useless use of HAMT::Vector::$_->[1] in void context/, "$_->[1] by name")
        for [0, 'push'], [1, 'set'], [2, 'pop'];
    is_deeply([ $v->list ], [qw(a b c)], 'and did nothing');
    @w = ();
    { no warnings 'void'; $v->push('x'); $v->pop; }
    $v->get(0); $v->count; $v->list; $v->first;
    is(scalar @w, 0, 'no warnings \'void\' silences them, and a read never warned');
    ok(!eval { $v->set(99, 'x'); 1 }, 'a bad index still croaks in void context');
}

# ---- subclasses ---------------------------------------------------------------------------
{
    package Local::Stack; our @ISA = ('HAMT::Vector');
    sub top { $_[0]->last }
}
{
    my $s = Local::Stack->new(1, 2);
    isa_ok($s, 'Local::Stack');
    is($s->push(3)->top, 3, 'push returns the subclass');
    isa_ok($s->pop, 'Local::Stack', 'so does pop');
    isa_ok($s->set(0, 9), 'Local::Stack', 'and set');
    isa_ok($s->transient->push(4)->persistent, 'Local::Stack', 'and a transient closes into it');
    isa_ok($s->new, 'Local::Stack', 'new called on an object makes one of its class');
}

# ---- the transient ----------------------------------------------------------------------------
{
    my $base = HAMT::Vector->new(1 .. 100);
    my $t = $base->transient;
    isa_ok($t, 'HAMT::Vector::Transient');
    is($t->count, 100, 'a transient starts with what the vector holds');
    is(refaddr($t->push(101, 102)), refaddr($t), 'push returns the transient');
    is(refaddr($t->set(0, 'first')), refaddr($t), 'set returns the transient');
    is(refaddr($t->pop), refaddr($t), 'pop returns the transient');
    is($t->get(0), 'first', 'set took effect in it');
    is($t->get(-1), 101, 'and so did push and pop');
    is($t->count, 101, 'with the count following');
    is($t->_check, 0, 'and it checks out');
    is_deeply([ $base->list ], [ 1 .. 100 ], 'the vector it was opened from has seen none of it');
    ok(!eval { $t->set(500, 'x'); 1 } && $@ =~ /^HAMT::Vector::Transient::set: index 500 is out of range for 101/,
       'set out of range croaks');

    my $p = $t->persistent;
    isa_ok($p, 'HAMT::Vector');
    is_deeply([ $p->list ], [ 'first', 2 .. 101 ], 'persistent returns a vector of what it held');
    for my $call ([ push => 1 ], [ set => 0, 1 ], [ 'pop' ], [ get => 0 ], [ 'count' ], [ 'persistent' ]) {
        my ($method, @args) = @$call;
        ok(!eval { my @r = $t->$method(@args); 1 }
           && $@ =~ /^HAMT::Vector::Transient::\Q$method\E: this transient is closed/,
           "$method on a closed transient croaks by name");
    }
    my ($x, $y) = ($p->transient, $p->transient);
    $x->push('x')->set(1, 'X'); $y->pop->set(1, 'Y');
    ok($x->get(1) eq 'X' && $y->get(1) eq 'Y' && $p->get(1) == 2 && $x->count == 102 && $y->count == 100 && $p->count == 101,
       'two transients on one vector see neither each other nor the vector them');
    my $emptied = HAMT::Vector->new(1)->transient;
    is($emptied->pop->pop->pop->count, 0, 'popping an empty transient leaves it empty');
    ok(!eval { HAMT::Vector::Transient::count($p); 1 } && $@ =~ /not a transient/, 'a vector is not a transient');

    my @w;
    local $SIG{__WARN__} = sub { push @w, @_ };
    $x->push(1); $x->set(0, 1); $x->pop;
    is(scalar @w, 0, 'push, set and pop on a transient do not warn in void context');
}

# ---- threads ---------------------------------------------------------------------------------
SKIP: {
    skip 'this perl has no ithreads', 3 unless $Config{useithreads};
    skip 'threads.pm does not load', 3 unless eval { require threads; 1 };
    is(HAMT::Vector->CLONE_SKIP, 1, 'the class asks not to be cloned');
    is(HAMT::Vector::Transient->CLONE_SKIP, 1, 'and so does its transient');
    my $shared = HAMT::Vector->new(1 .. 50);
    my ($state, $own) = threads->create({ context => 'list' }, sub {
        return ((eval { $shared->count; 1 } ? 'usable' : 'dead'), HAMT::Vector->new(1, 2)->push(3)->count);
    })->join;
    is("$state $own", 'dead 3', 'a new thread does not get the parent\'s vector, and can make its own');
}

done_testing;
