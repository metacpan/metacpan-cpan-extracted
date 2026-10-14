#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use HAMT::Map;

# A key is a string, and two keys are the same key exactly when a Perl hash
# would say so. Every case is run against a hash beside the map, so the
# expectation is perl's and not this file's.

plan skip_all => 'HAMT::Map is not built yet' unless HAMT::Map->can('new');

# Built with chr and never typed: a literal in a source file depends on the
# file's encoding and on `use utf8`, and this test is about exactly that
# difference.
my $e_acute  = chr(0xe9);
my $latin1   = $e_acute;            utf8::downgrade($latin1);
my $upgraded = $e_acute;            utf8::upgrade($upgraded);
my $wide     = chr(0x100);
my $wide_raw = $wide;               utf8::encode($wide_raw);

ok(!utf8::is_utf8($latin1) && utf8::is_utf8($upgraded),
   'the two spellings of e-acute really are stored differently');

sub agrees {
    my ($name, @pairs) = @_;
    my (%h, $m);
    $m = HAMT::Map->new;
    while (my ($k, $v) = splice @pairs, 0, 2) {
        no warnings 'uninitialized';
        $h{$k} = $v;
        $m = $m->set($k, $v);
    }
    is($m->count, scalar keys %h, "$name: as many keys as the hash has");
    is_deeply([ sort $m->keys ], [ sort keys %h ], "$name: and the same ones");
    for my $k (keys %h) {
        is($m->get($k), $h{$k}, "$name: the same value");
    }
    return $m;
}

{
    my $m = agrees('two spellings of one character', $latin1 => 1, $upgraded => 2);
    is($m->count, 1, 'e-acute as Latin-1 and as UTF-8 is one key');
    is($m->get($latin1), 2, 'read by the first spelling');
    is($m->get($upgraded), 2, 'and by the second');
    ok($m->exists($latin1) && $m->exists($upgraded), 'and exists by both');
    is($m->delete($upgraded)->count, 0, 'and is deleted by either');
}

{
    my $m = agrees('a wide character and its encoded bytes', $wide => 'char', $wide_raw => 'bytes');
    is($m->count, 2, 'U+0100 and the two bytes that encode it are two keys');
    is($m->get($wide), 'char', 'the character');
    is($m->get($wide_raw), 'bytes', 'the bytes');
    my ($back) = grep { length == 1 } $m->keys;
    ok(defined $back && utf8::is_utf8($back) && $back eq $wide,
       'the wide key comes back out as one character');
}

{
    my $m = agrees('the empty string', '' => 'empty', 'x' => 1);
    ok($m->exists(''), 'the empty string is a key');
    is($m->get(''), 'empty', 'with a value');
}

{
    my $m = agrees('a key with a NUL inside', "a\0b" => 1, "a\0c" => 2, "a" => 3);
    is($m->count, 3, 'three keys, not one cut at the NUL');
}

{
    my $big = 'k' x 70_000;
    my $m = agrees('a 70,000-byte key', $big => 1, substr($big, 1) . 'j' => 2);
    is($m->get($big), 1, 'found by its full length');
}

{
    my $m = agrees('a number and its string form', 5 => 'int', '5' => 'str', 5.0 => 'num', '5.0' => 'dotted');
    is($m->count, 2, '5, "5" and 5.0 are one key and "5.0" is another');
}

{
    my $ref = [];
    my $m = agrees('a reference', $ref => 1);
    is($m->get("$ref"), 1, 'a reference is a key by its string form');
}

{
    my @warned;
    local $SIG{__WARN__} = sub { push @warned, @_ };
    my $m = do { use warnings; HAMT::Map->new->set(undef, 1) };
    is($m->get(''), 1, 'undef as a key is the empty string');
    is(scalar @warned, 1, 'with one warning, as a hash gives');
}

done_testing;
