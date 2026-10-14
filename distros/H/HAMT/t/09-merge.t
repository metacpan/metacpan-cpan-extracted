#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Scalar::Util qw(refaddr blessed);
use HAMT::Map;

# merge and update. merge is checked against the hash it should equal,
# (%a, %b), at four hash widths.

END { HAMT::_hash_bits(64) }

{
    package Local::Counted;
    our %alive; our $made = 0;
    sub new { my $o = bless { id => ++$made }, shift; $alive{ $o->{id} } = 1; $o }
    sub DESTROY { delete $alive{ $_[0]{id} } }
}
sub alive { scalar keys %Local::Counted::alive }
sub as_hash { +{ $_[0]->pairs } }

for my $bits (64, 10, 5, 0) {
    HAMT::_hash_bits($bits);
    my $n = $bits ? 600 : 120;
    my %a = map { ("key$_" => "a$_") } 1 .. $n;
    my %b = map { ("key$_" => "b$_") } $n / 2 .. $n + $n / 2;
    my $a = HAMT::Map->new(%a);
    my $b = HAMT::Map->new(%b);

    my $m = $a->merge($b);
    is_deeply(as_hash($m), { %a, %b }, "$bits bits: merge is (%a, %b): the other map wins");
    is($m->count, scalar keys %{ { %a, %b } }, "$bits bits: with the right count");
    is($m->_check, 0, "$bits bits: and it checks out");
    is_deeply(as_hash($a), \%a, "$bits bits: the receiver is unchanged");
    is_deeply(as_hash($b), \%b, "$bits bits: and so is the other map");
    ok($m->equals(HAMT::Map->new(%a, %b)), "$bits bits: equal to the same map built directly");

    my $r = $b->merge($a);
    is_deeply(as_hash($r), { %b, %a }, "$bits bits: the other way round, the other way wins");

    # A resolver sees exactly the keys in both.
    my %seen;
    my $s = $a->merge($b, sub { my ($k, $mine, $theirs) = @_; $seen{$k} = [$mine, $theirs]; "$mine+$theirs" });
    my %want = (%a, %b);
    $want{$_} = "$a{$_}+$b{$_}" for grep { exists $b{$_} } keys %a;
    is_deeply(as_hash($s), \%want, "$bits bits: a resolver's answer is stored for keys in both");
    is_deeply([ sort keys %seen ], [ sort grep { exists $b{$_} } keys %a ],
              "$bits bits: and it is asked about those keys and no others");
    is_deeply($seen{"key$n"}, [ $a{"key$n"}, $b{"key$n"} ],
              "$bits bits: with the receiver's value first and the other map's second");
    is($s->_check, 0, "$bits bits: and the result checks out");

    undef $_ for $a, $b, $m, $r, $s;
}
HAMT::_hash_bits(64);

my $a = HAMT::Map->new(map { ("key$_" => $_) } 1 .. 500);

# ---- answers that are one of the operands -----------------------------------------
{
    my $empty = HAMT::Map->new;
    is(refaddr($a->merge($empty)), refaddr($a), 'merging an empty map in is the receiver');
    is(refaddr($empty->merge($a)), refaddr($a), 'merging into an empty map is the other map');
    is(refaddr($a->merge($a)), refaddr($a), 'merging a map with itself is that map');
    is($empty->merge($empty)->count, 0, 'two empty maps merge to an empty one');

    my $more = $a->set(extra => 1);
    is(refaddr($more->merge($a)), refaddr($more), 'merging in a map that adds nothing is the receiver');
    is(refaddr($a->merge($more)), refaddr($more), 'merging in a map that already holds everything is that map');

    {
        package Local::Sub; our @ISA = ('HAMT::Map');
    }
    my $sub = Local::Sub->new;
    my $got = $sub->merge($a);
    is(blessed($got), 'Local::Sub', 'the result is of the receiver\'s class');
    isnt(refaddr($got), refaddr($a), 'so it cannot be the other map itself when that is of another');
    ok($got->equals($a), 'though it holds the same');
    is(blessed($a->merge($sub->set(z => 1))), 'HAMT::Map', 'and the other way round');
}

# ---- one step apart ------------------------------------------------------------------
{
    my $next = $a->set(key250 => 'changed');
    my $calls = 0;
    my $m = $a->merge($next, sub { $calls++; $_[2] });
    is($calls, 1, 'merging two versions one value apart asks the resolver once');
    is($m->get('key250'), 'changed', 'and takes its answer');
    is(refaddr($m), refaddr($next), 'which, being equal to the other map\'s value, makes the result the other map');

    $calls = 0;
    my $kept = $a->merge($next, sub { $calls++; $_[1] });
    is(refaddr($kept), refaddr($a), 'a resolver that keeps the receiver\'s value gives the receiver back');
    is(refaddr($a->merge($next, sub { 250 })), refaddr($a),
       'and so does one that returns an equal value of its own');
    isnt(refaddr($a->merge($next, sub { 'neither' })), refaddr($a), 'a third value makes a new map');
    is($a->merge($next, sub { 'neither' })->get('key250'), 'neither', 'holding it');

    # Against a pair that share nothing: the count CAN be larger.
    $calls = 0;
    my $apart = HAMT::Map->new(map { ("key$_" => "x$_") } 1 .. 500);
    $a->merge($apart, sub { $calls++; $_[2] })->count;
    is($calls, 500, 'two unrelated maps with the same keys ask it 500 times');
}

# ---- what the resolver is handed and may return -------------------------------------
{
    my $x = HAMT::Map->new(k => 'mine', only_x => 1);
    my $y = HAMT::Map->new(k => 'theirs', only_y => 1);
    my @args;
    my $m = $x->merge($y, sub { @args = @_; undef });
    is_deeply(\@args, ['k', 'mine', 'theirs'], 'the key, the receiver\'s value, the other\'s');
    ok($m->exists('k'), 'returning undef stores undef: the key stays');
    is($m->get('k'), undef, 'with undef as its value');
    is($m->count, 3, 'and the count is right');

    my $list = $x->merge($y, sub { return (1, 2, 3) });
    is($list->get('k'), 3, 'a resolver is called in scalar context');

    my $ref = [1];
    is(refaddr($x->merge($y, sub { $ref })->get('k')), refaddr($ref), 'a reference returned is stored as that reference');
    ok(!eval { my $r = $x->merge($y, sub { $_[1] = 'poked' }); 1 }, 'the values it is handed are read-only');
    like($@, qr/Modification of a read-only value/, "with perl's own message");
    is($x->get('k'), 'mine', 'so the receiver cannot be changed through them');
}

# ---- a resolver that dies ---------------------------------------------------------------
{
    my $before = alive();
    my $x = HAMT::Map->new(map { ("key$_" => Local::Counted->new) } 1 .. 300);
    my $y = HAMT::Map->new(map { ("key$_" => Local::Counted->new) } 150 .. 450);
    my $live = alive();
    for my $stop (1, 75, 151) {
        my $calls = 0;
        my $r = eval { $x->merge($y, sub { die "resolver $stop\n" if ++$calls == $stop; Local::Counted->new }) };
        is($@, "resolver $stop\n", "a resolver that dies at call $stop stops the merge with its own error");
        is($r, undef, 'nothing is returned');
        is(alive(), $live, 'and every value it had made by then is freed');
    }
    my $obj = eval { $x->merge($y, sub { die bless({ code => 7 }, 'Local::Error') }) };
    is(ref $@, 'Local::Error', 'an exception object comes through as the object');
    is($@->{code}, 7, 'intact');
    is($x->count, 300, 'the receiver is untouched');
    is($x->_check + $y->_check, 0, 'and both maps check out');
    undef $_ for $x, $y;
    is(alive(), $before, 'nothing outlives the maps');
}

# ---- nothing outlives a merge that worked ---------------------------------------------------
{
    my $before = alive();
    {
        my $x = HAMT::Map->new(map { ("key$_" => Local::Counted->new) } 1 .. 200);
        my $y = HAMT::Map->new(map { ("key$_" => Local::Counted->new) } 100 .. 300);
        my $plain    = $x->merge($y);
        my $resolved = $x->merge($y, sub { Local::Counted->new });
        my $kept     = $x->merge($y, sub { $_[1] });
        is($plain->count + $resolved->count + $kept->count, 900, 'three merges of two maps of counted values');
    }
    is(alive(), $before, 'and once all five maps are gone, so is every value');
}

# ---- errors, void context ------------------------------------------------------------------
ok(!eval { my $r = $a->merge({}); 1 }, 'merge refuses a hash');
like($@, qr/^HAMT::Map::merge: not a map/, 'by name');
ok(!eval { my $r = $a->merge($a, 'x'); 1 }, 'and a resolver that is not a sub');
like($@, qr/^HAMT::Map::merge: not a code reference/, 'by name');
{
    my @w;
    local $SIG{__WARN__} = sub { push @w, $_[0] };
    $a->merge($a);
    $a->update(key1 => sub { 1 });
    is(scalar @w, 2, 'merge and update warn in void context');
    like($w[0], qr/^Useless use of HAMT::Map::merge in void context/, 'merge by name');
    like($w[1], qr/^Useless use of HAMT::Map::update in void context/, 'update by name');
}

# ---- update ------------------------------------------------------------------------------------
{
    my $m = HAMT::Map->new(hits => 1, name => 'x');
    my $m2 = $m->update(hits => sub { $_[0] + 1 });
    is($m2->get('hits'), 2, 'update stores what the sub returns');
    is($m->get('hits'), 1, 'the receiver is unchanged');
    is($m2->count, 2, 'the count is unchanged for a key that was there');

    my @args;
    my $m3 = $m->update(fresh => sub { @args = @_; 'made' });
    is(scalar @args, 1, 'the sub gets one argument');
    is($args[0], undef, 'undef for a key that is not there');
    is($m3->get('fresh'), 'made', 'and its answer becomes the value');
    is($m3->count, 3, 'under a new key');

    is($m->update(hits => sub { ($_[0] // 0) + 1 })->update(hits => sub { $_[0] * 10 })->get('hits'),
       20, 'updates chain');
    is(refaddr($m->update(hits => sub { $_[0] })), refaddr($m),
       'a sub that returns what it was given changes nothing: the receiver comes back');
    is(refaddr($m->update(hits => sub { 1 })), refaddr($m),
       'and so does one that returns an equal value of its own');
    isnt(refaddr($m->update(hits => sub { 2 })), refaddr($m), 'an unequal value is a new map');
    isnt(refaddr($m->update(absent => sub { undef })), refaddr($m),
         'undef for a key that was not there is a new map: the key is new');
    {
        my $u = HAMT::Map->new(k => undef);
        is(refaddr($u->update(k => sub { undef })), refaddr($u), 'undef over a stored undef changes nothing');
        isnt(refaddr($u->update(k => sub { '' })), refaddr($u), 'the empty string over undef is a change');
        my $list = [1];
        my $r = HAMT::Map->new(k => $list);
        is(refaddr($r->update(k => sub { $list })), refaddr($r), 'the same reference changes nothing');
        isnt(refaddr($r->update(k => sub { [1] })), refaddr($r), 'another array with the same contents is a change');
    }
    is($m->update(hits => sub { return (7, 8, 9) })->get('hits'), 9, 'the sub is called in scalar context');
    is($m->update(hits => sub { undef })->get('hits'), undef, 'undef is stored');
    ok($m->update(hits => sub { undef })->exists('hits'), 'and the key stays');

    ok(!eval { my $r = $m->update(hits => sub { die "no\n" }); 1 }, 'a die in the sub propagates');
    is($@, "no\n", 'unchanged');
    is($m->get('hits'), 1, 'and the receiver is unchanged');
    ok(!eval { my $r = $m->update(hits => 5); 1 }, 'update refuses something that is not a sub');
    like($@, qr/^HAMT::Map::update: not a code reference/, 'by name');

    {
        package Local::Sub2; our @ISA = ('HAMT::Map');
    }
    isa_ok(Local::Sub2->new(a => 1)->update(a => sub { 2 }), 'Local::Sub2', 'update returns the receiver\'s class');

    # The key scalar may be gone by the time the sub returns.
    # Changed IN PLACE, so the scalar keeps its buffer and anything still
    # pointing into it reads the new bytes. It has to be a string that owns
    # its buffer for that. A literal shares one with the program text and so
    # does the result of a join, and perl gives such a scalar a new buffer
    # rather than write to the shared one; a string with its front chopped
    # off is its own.
    my $key = 'xhits';
    substr($key, 0, 1, '');
    my $m4 = $m->update($key => sub { substr($key, 0, 4) = 'HITS'; 99 });
    is($key, 'HITS', 'a key variable changed in place inside the sub');
    is($m4->get('hits'), 99, 'the key is read before the sub runs, not after');
    ok(!$m4->exists($key), 'so changing the key variable inside the sub moves nothing');

    my $before = alive();
    eval { my $r = HAMT::Map->new(k => Local::Counted->new)->update(k => sub { die "x\n" }) } for 1 .. 20;
    is(alive(), $before, 'an update that dies leaks nothing');
}

done_testing;
