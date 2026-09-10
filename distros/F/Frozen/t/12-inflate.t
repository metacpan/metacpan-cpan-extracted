#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Frozen ();

# inflate: the whole structure back, identical. This is the round-trip the
# earlier phases could not assert, because until Phase 06 there was no reader
# to compare against.

my $data = {
    string   => 'hello',
    utf8     => do { my $s = "caf\xc3\xa9"; utf8::decode($s); $s },
    bytes    => "caf\xc3\xa9",
    empty    => '',
    nul      => "a\0b",
    int      => 42,
    neg      => -17,
    zero     => 0,
    float    => 1.5,
    undefd   => undef,
    truthy   => \1,
    falsy    => \0,
    hash     => { a => 1, b => { c => 2 } },
    array    => [1, 'two', [3, 4], { five => 5 }],
    empty_h  => {},
    empty_a  => [],
};

my $fz  = Frozen->attach(Frozen->freeze($data));
my $got = $fz->inflate;

# Booleans come back as 0/1 rather than as references, which is a documented
# narrowing: the block stores a bool as a tag, and the tag has no idea which
# spelling it arrived as.
my %expect = %$data;
$expect{truthy} = 1;
$expect{falsy}  = 0;

is_deeply($got, \%expect, 'the whole structure inflates identically');

# Flags, which is_deeply does not check.
ok(utf8::is_utf8($got->{utf8}),  'a character string keeps its UTF-8 flag');
ok(!utf8::is_utf8($got->{bytes}),'and a byte string keeps its absence');
is($got->{bytes}, $data->{bytes}, 'the byte string is unchanged');
is(length $got->{nul}, 3, 'a string containing NUL keeps its length');

# The integer/string distinction survives, which a naive round-trip loses.
{
    my $b = Frozen->attach(Frozen->freeze({ s => '007', i => 7 }));
    my $r = $b->inflate;
    is($r->{s}, '007', 'a string of digits stays a string');
    is($r->{i}, 7,     'and an integer stays an integer');
    isnt("$r->{s}", "$r->{i}", 'they are not the same value');
}

# A subtree, from a handle.
{
    my $h = $fz->child($fz->root, 'hash');
    is_deeply($fz->inflate($h), $data->{hash}, 'inflate of a subtree');
}

# A leaf, from a handle.
{
    my $h = $fz->child($fz->root, 'string');
    is($fz->inflate($h), 'hello', 'inflate of a leaf is the value');
}

# Round-trip twice: inflating and re-freezing must produce the same bytes,
# which is a stronger statement than is_deeply because it covers every
# distinction the format makes.
{
    my $once  = Frozen->freeze($data);
    my $twice = Frozen->freeze(Frozen->attach($once)->inflate);
    # Booleans are the one documented narrowing, so compare a structure that
    # has none.
    my %nb = %$data;
    delete @nb{qw(truthy falsy)};
    my $a = Frozen->freeze(\%nb);
    my $b = Frozen->freeze(Frozen->attach($a)->inflate);
    is($b, $a, 'inflate then freeze reproduces the same bytes');
}

done_testing;
