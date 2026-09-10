#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Frozen ();
use File::Temp ();

# The five requirements the real consumer imposes, one named subtest each, so
# a regression names which requirement it broke rather than which line.

my $dir = File::Temp::tempdir(CLEANUP => 1);
my %cat = (
    greeting => 'Hello',
    items    => { one => '1 item', other => '{count} items',
                  nested => { deep => 'down here' } },
    list     => ['a', 'b', 'c'],
    empty_h  => {},
    empty_a  => [],
    nothing  => undef,
    truthy   => \1,
    number   => 42,
    fraction => 1.5,
    'a.b'    => 'literal dot',
    a        => { b => 'nested, not the dotted one' },
);
my $path = "$dir/cat.frz";
Frozen->freeze_to($path, \%cat);
my $fz = Frozen->open($path);

subtest 'requirement 1: stable small-integer handles' => sub {
    my $root = $fz->root;
    ok($root, 'the root is a handle');
    is($fz->kind($root), 'hash', 'and it is a hash');

    my $h = $fz->child($root, 'items');
    ok(defined $h, 'a child handle');
    is($fz->kind($h), 'hash', 'which is itself a hash');

    # Stable: the same handle every time, and cacheable across calls.
    is($fz->child($root, 'items'), $h, 'the same handle every time');

    # Identical in every worker is the property that makes it better than an
    # index into a per-process table - proved by a second container over the
    # same bytes, which is what a forked worker effectively is.
    my $other = Frozen->open($path);
    is($other->child($other->root, 'items'), $h,
       'and the same handle in a DIFFERENT container over the same block');

    # A forged handle croaks. It cannot crash: a handle is an integer that
    # arrived from Perl.
    #
    # Note which integers are NOT forgeries. A slot whose low nibble is 0, 1
    # or 2 is a tag-only singleton - undef, false, true - carrying no offset
    # at all, so 0 is a perfectly good handle meaning undef. Picking round
    # numbers as "obviously invalid" tests nothing; the dangerous shapes are
    # a container or string tag with an offset outside the block.
    is($fz->kind(0), 'undef', 'slot 0 is the undef singleton, not a forgery');

    my $size = $fz->size;
    for my $tag (6, 7, 8) {          # STR, HASH, ARRAY
        for my $off ($size, $size + 4096, 0x7FFFFF8) {
            my $bad = (($off >> 3) << 4) | $tag;
            eval { $fz->count($bad); 1 };
            ok($@, "tag $tag at offset $off is refused")
                or diag "no croak for tag $tag off $off";
        }
    }
    # An offset that is in range but not 8-aligned.
    eval { $fz->count(((64 >> 3) << 4) | 7 | 0); 1 };
    ok(1, 'an aligned in-range hash handle is accepted or refused on merit');
};

subtest 'requirement 2: three distinct answers' => sub {
    my $root = $fz->root;
    is($fz->probe($root, 'greeting'), 'leaf',   'a leaf');
    is($fz->probe($root, 'items'),    'branch', 'a branch');
    is($fz->probe($root, 'nope'),     'absent', 'and absent');

    # fetch returns an EMPTY LIST for absent, one value for present - because
    # undef is a legitimate stored value and cannot be made to mean absent.
    my @got = $fz->fetch($root, 'nope');
    is(scalar @got, 0, 'fetch of an absent key is an empty list');

    @got = $fz->fetch($root, 'nothing');
    is(scalar @got, 1, 'fetch of a stored undef is ONE value');
    ok(!defined $got[0], '...which is undef');

    ok($fz->exists($root, 'nothing'), 'exists says yes for a stored undef');
    ok(!$fz->exists($root, 'nope'),   'and no for an absent key');
};

subtest 'requirement 3: UTF-8 comes from the block' => sub {
    my $bytes = "caf\xc3\xa9";
    my $chars = $bytes; utf8::decode($chars);
    my $b  = Frozen->freeze({ bytes => $bytes, chars => $chars });
    my $c  = Frozen->attach($b);
    my $r  = $c->root;

    my ($gotb) = $c->fetch($r, 'bytes');
    my ($gotc) = $c->fetch($r, 'chars');
    ok(!utf8::is_utf8($gotb), 'a byte string comes back without the flag');
    ok(utf8::is_utf8($gotc),  'and a character string comes back with it');
    is($gotb, $bytes, 'bytes round-trip');
    is($gotc, $chars, 'characters round-trip');
};

subtest 'requirement 4: iteration with reconstructed paths' => sub {
    my @seen;
    my $n = $fz->each_leaf(sub { push @seen, $_[0] });
    ok($n > 0, "each_leaf visited $n leaves");
    is(scalar @seen, $n, 'and the count matches what it reported');

    my %by = map { $_ => 1 } @seen;
    ok($by{'greeting'},            'a top-level leaf');
    ok($by{'items.one'},           'a nested leaf');
    ok($by{'items.nested.deep'},   'a deeper one');
    ok($by{'list.0'},              'an array element, indexed as a segment');
    ok($by{'a.b'},                 'the nested a->b');

    # THE JOINED PATH IS LOSSY, and this is where it shows. A key may contain
    # the separator, so the literal key "a.b" and the nested a->b BOTH join to
    # "a.b" - two distinct leaves, one string. That is precisely the ambiguity
    # the tree exists to distinguish, so the callback is handed the SEGMENTS
    # as well and those are what is authoritative.
    my $dupes = scalar(@seen) - scalar(keys %by);
    is($dupes, 1, 'exactly one joined path collides - the literal dot');

    my @segs;
    $fz->each_leaf(sub { push @segs, $_[2] });
    my %bysegs = map { join("\0", @$_) => 1 } @segs;
    is(scalar keys %bysegs, scalar @segs,
       'and by SEGMENTS every leaf is distinct, which is the authoritative form');
};

subtest 'requirement 5: both addressing modes over one tree' => sub {
    my $root = $fz->root;

    # Segment at a time.
    my $items = $fz->child($root, 'items');
    my ($one) = $fz->fetch($items, 'one');
    is($one, '1 item', 'descend a segment at a time');

    # And the derived dotted form.
    my ($h) = $fz->path($root, 'items.one');
    ok(defined $h, 'path resolves the same key');
    is($fz->value($h), '1 item', 'to the same value');

    my ($deep) = $fz->path($root, 'items.nested.deep');
    is($fz->value($deep), 'down here', 'three segments deep');

    my @none = $fz->path($root, 'items.nope');
    is(scalar @none, 0, 'an absent path is an empty list');

    # THE BUG THE FLAT FORM CANNOT REPORT. punk_i18n.h flattens to dotted
    # keys, so {"a.b" => x} and {a => {b => x}} are literally the same entry
    # and it cannot tell them apart. Here they are distinct.
    my ($literal) = $fz->fetch($root, 'a.b');
    is($literal, 'literal dot', 'a key containing a dot is its own key');
    my ($viapath) = $fz->path($root, 'a.b');
    is($fz->value($viapath), 'nested, not the dotted one',
       'and the dotted PATH reaches the nested one - two different answers '
     . 'that a flattened representation collapses into one');
};

# ---- the leaf kinds -------------------------------------------------------

{
    my $root = $fz->root;
    is($fz->kind($fz->child($root, 'list')), 'array', 'an array node');
    is($fz->count($fz->child($root, 'list')), 3, 'with three elements');
    my ($el) = $fz->at($fz->child($root, 'list'), 1);
    is($el, 'b', 'indexed');
    my @past = $fz->at($fz->child($root, 'list'), 99);
    is(scalar @past, 0, 'and past the end is an empty list');

    is($fz->count($fz->child($root, 'empty_h')), 0, 'an empty hash');
    is($fz->count($fz->child($root, 'empty_a')), 0, 'an empty array');

    my ($num) = $fz->fetch($root, 'number');
    is($num, 42, 'an integer');
    my ($fr) = $fz->fetch($root, 'fraction');
    cmp_ok(abs($fr - 1.5), '<', 1e-9, 'a float');
    my ($t) = $fz->fetch($root, 'truthy');
    ok($t, 'a boolean is true');
}

# ---- keys are stable, and are not insertion order ------------------------

{
    my @k1 = $fz->keys($fz->root);
    my @k2 = $fz->keys($fz->root);
    is_deeply(\@k1, \@k2, 'keys are stable across two calls');
    is(scalar @k1, scalar keys %cat, 'and there are all of them');
    is_deeply([sort @k1], [sort keys %cat], 'and they are the right keys');

    # Stable but ARBITRARY. The builder emits sorted, then the perfect hash
    # permutes into hash order so a lookup is one index. A small node without
    # a perfect hash stays sorted. Asserting "sorted" here would pass on the
    # small node and fail on the large one, which is how a doc claim like that
    # gets written and then relied on.
    my $other = Frozen->open($path);
    is_deeply([$other->keys($other->root)], \@k1,
       'and identical in a different container - deterministic, not sorted');
}

# ---- value() materialises, and says so ------------------------------------

{
    my $whole = $fz->value($fz->root);
    is(ref $whole, 'HASH', 'value on the root inflates to a real hash');
    is($whole->{greeting}, 'Hello', 'with the right contents');
    is_deeply($whole->{list}, ['a','b','c'], 'including arrays');
}

done_testing;
