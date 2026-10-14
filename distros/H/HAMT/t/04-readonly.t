#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Scalar::Util qw(readonly refaddr);
use HAMT::Map;

# A stored value cannot be written through anything `get` hands out. If it
# could, a caller holding an alias would change the map under every other
# holder of it, and under every earlier version that shares the entry.
#
# Before 5.20 a copy-on-write string carried the read-only flag and meant
# the opposite, so each kind of value is tried from a source that is a
# shared hash key as well as from an ordinary one.

my $RO = qr/Modification of a read-only value/;

sub poke { $_[0] = 'poked' }

my %from_key = (shared => 1);
my ($hash_key) = keys %from_key;        # a shared hash key scalar

my @cases = (
    [ 'a string'             => 'text' ],
    [ 'a string from a hash key' => $hash_key ],
    [ 'an integer'           => 42 ],
    [ 'a fraction'           => 1.5 ],
    [ 'undef'                => undef ],
    [ 'the empty string'     => '' ],
    [ 'an array reference'   => [1, 2, 3] ],
    [ 'a long string'        => 'x' x 5000 ],
);

for my $c (@cases) {
    my ($name, $value) = @$c;
    my $m = HAMT::Map->new(k => $value);
    my $want = $m->get('k');

    ok(readonly($m->get('k')), "$name: the stored scalar is read-only");

    ok(!eval { $_ = 'poked' for $m->get('k'); 1 }, "$name: not writable through for");
    like($@, $RO, "$name: with perl's own message");

    ok(!eval { ${ \ $m->get('k') } = 'poked'; 1 }, "$name: not writable through a reference");
    like($@, $RO, "$name: with perl's own message");

    ok(!eval { poke($m->get('k')); 1 }, "$name: not writable through \@_");
    like($@, $RO, "$name: with perl's own message");

    my $now = $m->get('k');
    ok((defined $now ? defined $want && (ref $now ? refaddr($now) == refaddr($want) : $now eq $want)
                     : !defined $want),
       "$name: and it still holds what it held");
}

# The flags themselves, for the case the header comment is about. Below 5.20
# a scalar that is read-only AND "fake" is a copy-on-write string: perl
# unshares it at the first write and the write goes through. So the stored
# copy of a hash key must carry the first flag without the second.
{
    require B;
    my $m = HAMT::Map->new(k => $hash_key);
    my $flags = B::svref_2object(\ $m->get('k'))->FLAGS;
    my $src   = B::svref_2object(\$hash_key)->FLAGS;
    ok($flags & B::SVf_READONLY(), 'the stored copy of a hash key has the read-only flag');
    ok($] >= 5.020 || !($flags & B::SVf_FAKE()),
       'and, below 5.20, not the flag that would turn it into copy-on-write');
    note(sprintf 'source of the copy: read-only %d, fake %d; stored: read-only %d, fake %d',
         map { $_ ? 1 : 0 } $src & B::SVf_READONLY(), $src & B::SVf_FAKE(),
                             $flags & B::SVf_READONLY(), $flags & B::SVf_FAKE());
}

# What the caller passed in stays the caller's.
{
    my $mine = 'caller';
    my $m = HAMT::Map->new(k => $mine);
    ok(!readonly($mine), "the caller's own variable is not made read-only");
    $mine = 'changed';
    is($m->get('k'), 'caller', 'and changing it afterwards does not reach the map');

    my $copy = $m->get('k');
    ok(!readonly($copy), 'a value assigned out of the map is an ordinary copy');
    $copy .= ' and more';
    is($m->get('k'), 'caller', 'and changing the copy does not reach the map either');
}

# Shallow: the reference is fixed, what it points at is the caller's.
{
    my $list = [1, 2];
    my $m  = HAMT::Map->new(list => $list);
    my $m2 = $m->set(other => 1);
    push @{ $m->get('list') }, 3;
    is_deeply($m->get('list'), [1, 2, 3], 'a stored array can still be pushed to');
    is_deeply($m2->get('list'), [1, 2, 3], 'and every version sees it, since they share the array');
    is_deeply($list, [1, 2, 3], 'as does the caller, whose array it is');
    ok(!eval { $_ = [] for $m->get('list'); 1 }, 'the reference itself cannot be replaced');
    like($@, $RO, "with perl's own message");
}

# values and pairs hand out the same scalars get does.
{
    my $m = HAMT::Map->new(a => 'one', b => 'two');
    ok(!eval { $_ = 'poked' for $m->values; 1 }, 'values are read-only');
    like($@, $RO, "with perl's own message");
    ok(!eval { my @p = $m->pairs; $_ = 'poked' for $m->pairs; 1 }, 'so are pairs');
    is_deeply({ $m->pairs }, { a => 'one', b => 'two' }, 'and nothing changed');
    my @copy = $m->values;
    ok(!eval { $_ .= '!' for @copy; 0 } && !$@, 'a list assigned out of values is ordinary copies');
}

# A missing key is a fresh undef, not the interpreter's shared one.
{
    my $m = HAMT::Map->new;
    ok(eval { $_ = 'fine' for $m->get('absent'); 1 }, 'the undef for a missing key is writable')
        or diag $@;
    is($m->get('absent'), undef, 'and writing to it changed nothing');
    isnt(\ $m->get('absent'), \ undef, 'it is not the shared undef');
}

# A value is read once on the way in.
{
    package Local::Counting;
    sub TIESCALAR { my $n = 0; bless \$n, shift }
    sub FETCH { ${ $_[0] }++; 'fetched' }
}
{
    tie my $tied, 'Local::Counting';
    my $m = HAMT::Map->new(k => $tied);
    is(${ tied $tied }, 1, 'a tied value is fetched once by new');
    is($m->get('k'), 'fetched', 'and what it gave is stored');
    is(${ tied $tied }, 1, 'reading the map does not fetch it again');
    my $m2 = $m->set(j => $tied);
    is(${ tied $tied }, 2, 'and once more by set');

    my $text = 'abcdef';
    my $m3 = HAMT::Map->new(k => substr($text, 1, 3));
    is($m3->get('k'), 'bcd', 'a substr is stored as the string it was');
    substr($text, 1, 3) = 'XYZ';
    is($m3->get('k'), 'bcd', 'and does not follow the original');
}

# A key is read once too.
{
    tie my $key, 'Local::Counting';
    my $m = HAMT::Map->new($key => 1);
    is(${ tied $key }, 1, 'a tied key is fetched once');
    ok($m->exists('fetched'), 'and what it gave is the key');
}

done_testing;
