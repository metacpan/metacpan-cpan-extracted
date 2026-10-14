#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Scalar::Util qw(refaddr blessed);
use HAMT::Vector;

# slice, insert and remove, against an array's own slices and splice.

sub same {
    my ($v, $want) = @_;
    no warnings 'uninitialized';
    return $v->count == @$want && $v->_check == 0 && join("\0", $v->list) eq join("\0", @$want);
}

# ---- every slice of every vector up to 70 long ------------------------------
{
    my ($bad, $n) = (undef, 0);
    SIZE: for my $size (0 .. 70) {
        my @a = (0 .. $size - 1);
        my $v = HAMT::Vector->new(@a);
        for my $from (0 .. $size) {
            for my $len (0 .. $size - $from) {
                $n++;
                next if same($v->slice($from, $len), [ @a[$from .. $from + $len - 1] ]);
                $bad = "size $size from $from len $len";
                last SIZE;
            }
        }
    }
    ok(!$bad, "all $n slices of every vector up to 70 long") or diag($bad);
}

my @a = map { "v$_" } 0 .. 39_999;
my $v = HAMT::Vector->new(@a);

# ---- random cuts of a large one ------------------------------------------------
{
    my $state = 4711;
    my $rnd = sub { $state = ($state * 1103515245 + 12345) % 2147483648; ($state >> 8) % $_[0] };
    my $bad;
    for my $k (1 .. 600) {
        my $from = $rnd->(40_000);
        my $len  = 1 + $rnd->(40_000 - $from);
        $len  = 1 + $rnd->(70) if $k % 4 == 0;
        $from = $from - $from % 32 if $k % 5 == 0;
        $len = 40_000 - $from if $from + $len > 40_000;
        my $s = $v->slice($from, $len);
        my $ok = $s->count == $len && $s->_check == 0
              && $s->first eq $a[$from] && $s->last eq $a[$from + $len - 1]
              && $s->get(int($len / 2)) eq $a[$from + int($len / 2)];
        $ok &&= join("\0", $s->list) eq join("\0", @a[$from .. $from + $len - 1]) if $len <= 2000;
        unless ($ok) { $bad = "from $from len $len"; last }
    }
    ok(!$bad, '600 random slices of a 40,000-long vector') or diag($bad);
    is($v->count, 40_000, 'which is itself unchanged');
    is($v->_check, 0, 'and valid');
}

# ---- how the arguments are read --------------------------------------------------
{
    my $s = HAMT::Vector->new('a' .. 'j');
    my @s = ('a' .. 'j');
    ok(same($s->slice(3), [ @s[3 .. 9] ]), 'no length: to the end');
    ok(same($s->slice(3, undef), [ @s[3 .. 9] ]), 'an undef length: to the end');
    ok(same($s->slice(3, 100), [ @s[3 .. 9] ]), 'a length past the end stops at the end');
    ok(same($s->slice(-3), [ @s[7 .. 9] ]), 'a negative start counts from the end');
    ok(same($s->slice(-3, 2), [ @s[7, 8] ]), 'with a length');
    ok(same($s->slice(-100, 2), [ @s[0, 1] ]), 'a negative start before the beginning is the beginning');
    ok(same($s->slice(10), []), 'a start at the end is empty');
    ok(same($s->slice(50, 3), []), 'and so is one past it');
    ok(same($s->slice(4, 0), []), 'and a length of zero');
    is(refaddr($s->slice(0)), refaddr($s), 'the whole vector is the receiver');
    is(refaddr($s->slice(0, 10)), refaddr($s), 'however it is asked for');
    is(refaddr($s->slice(-10, 99)), refaddr($s), 'or however roundabout');
    isnt(refaddr($s->slice(0, 9)), refaddr($s), 'one short of the whole is not');
    ok(!eval { my $r = $s->slice(0, -1); 1 } && $@ =~ /^HAMT::Vector::slice: length -1 is negative/,
       'a negative length croaks');
    ok(!eval { my $r = $s->slice(0, 1, 2); 1 } && $@ =~ /^HAMT::Vector::slice: too many arguments/,
       'and so does a third argument');
    ok(same(HAMT::Vector->new->slice(0, 5), []), 'a slice of an empty vector is empty');
}

# ---- a slice is a vector like any other ------------------------------------------------
{
    my $s = $v->slice(1000, 3000);
    my @s = @a[1000 .. 3999];
    is($s->push('x')->count, 3001, 'a slice can be pushed to');
    is($s->push('x')->last, 'x', 'at its end');
    is($s->set(0, 'F')->first, 'F', 'set at its cut start');
    is($s->set(-1, 'L')->last, 'L', 'and at its cut end');
    my $p = $s;
    $p = $p->pop for 1 .. 100;
    ok(same($p, [ @s[0 .. 2899] ]), 'popped a hundred times');
    ok(same($s->slice(10, 20), [ @s[10 .. 29] ]), 'a slice of a slice');
    ok(same($s->concat($s), [ @s, @s ]), 'a slice joined to itself');
    ok($s->equals(HAMT::Vector->new(@s)), 'equal to the same values built by pushing');
    my @idx;
    $s->each(sub { push @idx, $_[1] if $_[0] ne $s[ $_[1] ] });
    is(scalar @idx, 0, 'walked in order with indexes that start at zero');
    is(blessed($s), 'HAMT::Vector', 'of the receiver\'s class');
    {
        package Local::Seq; our @ISA = ('HAMT::Vector');
    }
    my $sub = Local::Seq->new(1 .. 100);
    isa_ok($sub->slice(10, 5), 'Local::Seq', 'a slice of a subclass');
    isa_ok($sub->slice(200), 'Local::Seq', 'even an empty one');
    isa_ok($sub->insert(3, 'x'), 'Local::Seq', 'and insert');
    isa_ok($sub->remove(3), 'Local::Seq', 'and remove');
}

# ---- insert -------------------------------------------------------------------------------
{
    my $s = HAMT::Vector->new('a' .. 'j');
    for my $case ([ 0, 'x' ], [ 5, 'x' ], [ 10, 'x' ], [ 3, 'x', 'y', 'z' ], [ -1, 'x' ], [ -10, 'x' ],
                  [ 5, undef ], [ 10, 1 .. 100 ]) {
        my ($at, @vals) = @$case;
        my @want = ('a' .. 'j');
        splice @want, $at, 0, @vals;
        no warnings 'uninitialized';
        ok(same($s->insert($at, @vals), \@want), "insert at $at is splice at $at");
    }
    is(refaddr($s->insert(3)), refaddr($s), 'inserting nothing is the receiver');
    ok(same($s, [ 'a' .. 'j' ]), 'and the receiver is unchanged by all of it');
    for my $bad (11, -11, 99) {
        ok(!eval { my $r = $s->insert($bad, 'x'); 1 }
           && $@ =~ /^HAMT::Vector::insert: index \Q$bad\E is out of range for 10 elements/,
           "insert at $bad croaks");
    }
    ok(same(HAMT::Vector->new->insert(0, 'only'), ['only']), 'insert into an empty vector');

    my @big = @a;
    my $b = $v;
    for my $at (0, 31, 32, 33, 1024, 20_000, 39_999, 40_005) {
        splice @big, $at, 0, "ins$at";
        $b = $b->insert($at, "ins$at");
    }
    ok($b->count == @big && $b->_check == 0 && join("\0", $b->list) eq join("\0", @big),
       'eight inserts into a 40,000-long vector, at the edges of its leaves and in the middle');
    my $ref = [1];
    is(refaddr($s->insert(2, $ref)->get(2)), refaddr($ref), 'an inserted reference is stored as that reference');
    ok(!eval { $_ = 'poked' for $s->insert(2, 'new')->get(2); 1 }, 'and an inserted value is read-only like any other');
}

# ---- remove -------------------------------------------------------------------------------
{
    my $s = HAMT::Vector->new('a' .. 'j');
    for my $case ([ 0 ], [ 9 ], [ 4 ], [ -1 ], [ -10 ], [ 2, 3 ], [ 0, 10 ], [ 7, 99 ], [ 0, 1 ], [ 5, 5 ]) {
        my ($at, @len) = @$case;
        my @want = ('a' .. 'j');
        splice @want, $at, @len ? $len[0] : 1;
        ok(same($s->remove($at, @len), \@want), "remove(@$case) is splice(@$case)");
    }
    is(refaddr($s->remove(10)), refaddr($s), 'removing at an index past the end is the receiver');
    is(refaddr($s->remove(-11)), refaddr($s), 'and before the start');
    is(refaddr($s->remove(3, 0)), refaddr($s), 'and removing nothing');
    is($s->remove(0, 10)->count, 0, 'removing everything leaves an empty vector');
    ok(same($s, [ 'a' .. 'j' ]), 'and the receiver is unchanged by all of it');
    ok(!eval { my $r = $s->remove(0, -1); 1 } && $@ =~ /^HAMT::Vector::remove: length -1 is negative/,
       'a negative length croaks');

    my @big = @a;
    my $b = $v;
    for my $case ([ 0, 1 ], [ 30, 5 ], [ 1000, 100 ], [ 20_000, 1 ], [ 35_000, 2000 ], [ 37_800, 99_999 ]) {
        splice @big, $case->[0], $case->[1];
        $b = $b->remove(@$case);
    }
    ok($b->count == @big && $b->_check == 0 && join("\0", $b->list) eq join("\0", @big),
       'six removals from a 40,000-long vector');
    is($v->count, 40_000, 'which is itself unchanged');
}

# ---- void context, wrong things ---------------------------------------------------------------
{
    my @w;
    local $SIG{__WARN__} = sub { push @w, $_[0] };
    $v->slice(1, 2); $v->insert(0, 'x'); $v->remove(0);
    is(scalar @w, 3, 'slice, insert and remove warn in void context');
    like($w[$_->[0]], qr/^Useless use of HAMT::Vector::$_->[1] in void context/, "$_->[1] by name")
        for [0, 'slice'], [1, 'insert'], [2, 'remove'];
    ok(!eval { $v->insert(99_999, 'x'); 1 }, 'a bad index still croaks in void context');
}
for my $method (qw(slice insert remove concat)) {
    my @args = $method eq 'concat' ? ($v) : (0, 1);
    ok(!eval { my @r = HAMT::Vector->can($method)->([], @args); 1 }
       && $@ =~ /^HAMT::Vector::\Q$method\E: not a vector/, "$method refuses what is not a vector");
}

done_testing;
