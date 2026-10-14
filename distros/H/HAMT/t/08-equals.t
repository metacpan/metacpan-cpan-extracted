#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use HAMT::Map;

# equals: the same keys with equal values. Run at four hash widths, since two
# maps are compared node against node and a collision node is compared
# differently from the rest.

END { HAMT::_hash_bits(64) }

sub eq_ok   { my ($a, $b, $name) = @_; ok($a->equals($b) && $b->equals($a), $name) }
sub ne_ok   { my ($a, $b, $name) = @_; ok(!$a->equals($b) && !$b->equals($a), $name) }

for my $bits (64, 10, 5, 0) {
    HAMT::_hash_bits($bits);
    my $n = $bits ? 400 : 120;
    my %h = map { ("key$_" => "v$_") } 1 .. $n;

    my $a = HAMT::Map->new(%h);
    my $b = HAMT::Map->new(map { ($_ => $h{$_}) } reverse sort keys %h);
    eq_ok($a, $a, "$bits bits: a map equals itself");
    eq_ok($a, $b, "$bits bits: and one built in another order");

    # Through a history of unrelated inserts and deletes.
    my $c = $a;
    $c = $c->set("stranger$_" => 1) for 1 .. 50;
    $c = $c->delete("stranger$_") for 1 .. 50;
    eq_ok($a, $c, "$bits bits: and one that has been somewhere else and come back");

    ne_ok($a, $a->set(key7 => 'other'), "$bits bits: one value differing");
    ne_ok($a, $a->delete('key7')->set(key0 => 'v7'), "$bits bits: one key differing, the count the same");
    ne_ok($a, $a->delete('key7'), "$bits bits: one key fewer");
    ne_ok($a, $a->set(extra => 1), "$bits bits: one key more");
    eq_ok($a->set(key7 => 'other')->set(key7 => 'v7'), $a, "$bits bits: a value changed and changed back");

    undef $_ for $a, $b, $c;
}
HAMT::_hash_bits(64);

# ---- what "equal values" means ---------------------------------------------------
{
    my $ref = [1];
    my $m = sub { HAMT::Map->new(k => $_[0]) };

    eq_ok($m->('a'), $m->('a'), 'equal strings');
    ne_ok($m->('a'), $m->('b'), 'unequal strings');
    eq_ok($m->(1), $m->('1'), 'a number and its string form: values compare as strings');
    ne_ok($m->(1), $m->('1.0'), 'so 1 and "1.0" differ');
    eq_ok($m->(undef), $m->(undef), 'two undefs');
    ne_ok($m->(undef), $m->(''), 'undef and the empty string');
    ne_ok($m->(undef), $m->(0), 'undef and zero');
    eq_ok($m->($ref), $m->($ref), 'two references to the same array');
    ne_ok($m->([1]), $m->([1]), 'two arrays with the same contents: references compare by address');
    ne_ok($m->($ref), $m->("$ref"), 'a reference and the string it would make');
    eq_ok($m->(chr(0xe9)), $m->(do { my $s = chr(0xe9); utf8::upgrade($s); $s }),
          'one string in its two encodings');
}

# ---- a comparison sub --------------------------------------------------------------
{
    my $a = HAMT::Map->new(x => 1,   y => 2.0);
    my $b = HAMT::Map->new(x => '1.0', y => '2');
    ok(!$a->equals($b), 'as strings, 1 and "1.0" differ');
    ok($a->equals($b, sub { $_[0] == $_[1] }), 'with a numeric comparison they are equal');

    my @seen;
    $a->equals($b, sub { push @seen, [@_]; 1 });
    is(scalar @seen, 2, 'the sub is called for each pair of values that is not one scalar');
    is(scalar @{ $seen[0] }, 2, 'with two arguments');

    my $calls = 0;
    ok($a->equals($a, sub { $calls++; 0 }), 'a map equals itself whatever the sub says');
    is($calls, 0, 'because the sub is never asked');

    my $deep = sub { join(',', @{ $_[0] }) eq join(',', @{ $_[1] }) };
    ok(HAMT::Map->new(k => [1, 2])->equals(HAMT::Map->new(k => [1, 2]), $deep),
       'a sub can look inside references');

    ok(!HAMT::Map->new(a => 1)->equals(HAMT::Map->new(b => 1), sub { 1 }),
       'a sub that says yes to everything does not make different keys equal');

    ok(!eval { $a->equals($b, sub { die "cmp\n" }); 1 }, 'a die in the sub propagates');
    is($@, "cmp\n", 'unchanged');
    ok(!eval { $a->equals($b, 'x'); 1 }, 'something that is not a sub is refused');
    like($@, qr/^HAMT::Map::equals: not a code reference/, 'by name');
}

# ---- things that are not maps ------------------------------------------------------
{
    my $a = HAMT::Map->new(k => 1);
    ok(!$a->equals(undef), 'a map does not equal undef');
    ok(!$a->equals({ k => 1 }), 'nor a hash with the same contents');
    ok(!$a->equals('HAMT::Map'), 'nor a string');
    ok(!$a->equals(bless {}, 'HAMT::Map'), 'nor something merely blessed into the class');
    ok(HAMT::Map->new->equals(HAMT::Map->new), 'two empty maps are equal');
    ok(!HAMT::Map->new->equals($a), 'an empty map and a full one are not');
    {
        package Local::Sub; our @ISA = ('HAMT::Map');
    }
    ok($a->equals(Local::Sub->new(k => 1)), 'a subclass with the same contents is equal');
}

done_testing;
