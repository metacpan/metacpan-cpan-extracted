#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use HAMT::Map;
use HAMT::Set;
use HAMT::Vector;

# `last` and `next` in a sub HAMT calls. In a walk - each and diff - `last`
# stops it and `next` goes on to the next call. Anywhere else either is the
# error perl gives outside a loop. Either way the loop around the method is
# untouched and the program runs on.

my $m = HAMT::Map->new(map { ("k$_" => $_) } 1 .. 50);
my $s = HAMT::Set->new(map { "m$_" } 1 .. 50);
my $v = HAMT::Vector->new(1 .. 50);
my @mkeys = $m->keys;
my @smembers = $s->members;

my @warned;
local $SIG{__WARN__} = sub { push @warned, $_[0] };

# ---- each: last stops ---------------------------------------------------------
{
    my (@ran, @after);
    for my $i (1 .. 3) {
        my @seen;
        my $ret = $m->each(sub { push @seen, $_[0]; last if @seen == 5 });
        is($ret, $m, "map each with last returns the map ($i)");
        is_deeply(\@seen, [ @mkeys[0 .. 4] ], "map each stopped at the fifth key ($i)");
        push @after, $i;
    }
    is_deeply(\@after, [1, 2, 3], 'the loop around map each ran every iteration');

    my @seen;
    $s->each(sub { push @seen, $_[0]; last if @seen == 3 });
    is_deeply(\@seen, [ @smembers[0 .. 2] ], 'set each stopped at the third member');

    @seen = ();
    my $ret = $v->each(sub { push @seen, $_[1]; last if $_[0] == 40 });
    is($ret, $v, 'vector each with last returns the vector');
    is_deeply(\@seen, [0 .. 39], 'vector each stopped at the value 40');

    @seen = ();
    $v->each(sub { push @seen, $_[0]; last });
    is_deeply(\@seen, [1], 'last on the first call stops at once');
}

# ---- each: next skips -----------------------------------------------------------
{
    my @seen;
    $m->each(sub { next if $_[1] % 2; push @seen, $_[1] });
    is_deeply([ sort { $a <=> $b } @seen ], [ grep { !($_ % 2) } 1 .. 50 ],
        'map each with next skips to the following pair');

    @seen = ();
    $s->each(sub { next if $_[0] =~ /5/; push @seen, $_[0] });
    is_deeply(\@seen, [ grep { !/5/ } @smembers ], 'set each with next');

    @seen = ();
    $v->each(sub { next if $_[0] > 10; push @seen, $_[0] });
    is_deeply(\@seen, [1 .. 10], 'vector each with next walks to the end');
}

# ---- a walk inside a walk -------------------------------------------------------
{
    my @pairs;
    my $small = HAMT::Vector->new(qw(a b c));
    $v->each(sub {
        my $x = $_[0];
        $small->each(sub { last if $_[0] eq 'b'; push @pairs, "$x$_[0]" });
        last if $x == 3;
    });
    is_deeply(\@pairs, [qw(1a 2a 3a)], 'last in an inner walk stops only that walk');
}

# ---- diff: last stops, next goes on ---------------------------------------------
{
    my $other = HAMT::Map->new(map { ("k$_" => $_ + 1) } 1 .. 50);
    my $calls = 0;
    my $n = $m->diff($other, sub { $calls++; last if $calls == 4 });
    is($calls, 4, 'diff stopped on the fourth call');
    is($n, 4, 'and counts the differences it reported');

    $calls = 0;
    $n = $m->diff($other, sub { $calls++; next });
    is($calls, 50, 'diff with next is called for every difference');
    is($n, 50, 'and counts them all');
}

# ---- elsewhere both are errors ----------------------------------------------------
for my $word (qw(last next)) {
    my $want = qr/^Can't "$word" outside a loop block/;
    my $code = $word eq 'last' ? sub { last } : sub { next };
    my @after;
    for my $i (1 .. 2) {
        my $r = eval { $m->update(k1 => $code) };
        like($@, $want, "update: $word is an error ($i)");
        ok(!defined $r, 'and nothing is returned');
        push @after, $i;
    }
    is_deeply(\@after, [1, 2], "the loop around update ran on after $word");

    my $r = eval { $m->merge(HAMT::Map->new(k1 => 9), $code) };
    like($@, $want, "merge resolver: $word is an error");
    ok(!defined $r, 'and nothing is returned');

    eval { $m->equals(HAMT::Map->new(map { ("k$_" => "x") } 1 .. 50), $code) };
    like($@, $want, "map equals: $word is an error");

    eval { $v->equals(HAMT::Vector->new(map { "x" } 1 .. 50), $code) };
    like($@, $want, "vector equals: $word is an error");
}

# ---- redo is not stop or skip -------------------------------------------------------
{
    my $calls = 0;
    eval { $m->each(sub { $calls++; redo }) };
    like($@, qr/^Can't "redo" outside a loop block/, 'redo in each is an error');
    is($calls, 1, 'raised from the first call');
}

# ---- die still passes through, object and all -----------------------------------
{
    my $calls = 0;
    eval { $m->each(sub { $calls++; die { code => 7 } if $calls == 2 }) };
    is(ref $@, 'HASH', 'a die object passes through each');
    is($@->{code}, 7, 'unchanged');
    is($calls, 2, 'and stops the walk');

    eval { $m->diff(HAMT::Map->new, sub { die "diff died\n" }) };
    is($@, "diff died\n", 'a die passes through diff');
    eval { $v->each(sub { die "vector died\n" }) };
    is($@, "vector died\n", 'and through vector each');
}

# ---- $@ is the caller's ---------------------------------------------------------
{
    $@ = 'before';
    $m->each(sub { last });
    is($@, 'before', 'a walk that stops leaves $@ as it was');
    $@ = 'before';
    $v->each(sub { next });
    is($@, 'before', 'so does one that skips');
    $@ = 'before';
    my $m2 = $m->update(k1 => sub { 99 });
    is($@, 'before', 'and a call that returns');
}

# ---- warnings -------------------------------------------------------------------
{
    @warned = ();
    $m->each(sub { last });
    is(scalar @warned, 1, 'last in each warns once');
    like($warned[0] // '', qr/^Exiting subroutine via last/, 'as perl does for any sub');

    @warned = ();
    $m->each(sub { no warnings 'exiting'; last });
    is(scalar @warned, 0, "no warnings 'exiting' silences it");

    @warned = ();
    $m->each(sub { warn "mine\n"; last });
    is_deeply([ grep { !/^Exiting/ } @warned ], ["mine\n"],
        'other warnings in the sub reach the hook');

    @warned = ();
    my @inner;
    $m->each(sub {
        local $SIG{__WARN__} = sub { push @inner, $_[0] };
        warn "inner\n";
        last;
    });
    is_deeply([ grep { !/^Exiting/ } @inner ], ["inner\n"], 'a hook the sub sets is its own');

    @warned = ();
    warn "after\n";
    is_deeply(\@warned, ["after\n"], 'the hook is the caller\'s again after the walk');
}

done_testing;
