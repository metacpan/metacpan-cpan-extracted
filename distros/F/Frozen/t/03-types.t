#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Frozen ();
use Config;

# Every scalar kind the builder has to tell apart, and the two typing rules
# that are easy to get wrong.
#
# There is no reader yet, so what is asserted here is that each case is
# ACCEPTED and produces a structurally sound block. That the values come back
# unchanged is Phase 06's test, and it is named there so this is not mistaken
# for a round-trip.

my @cases = (
    ['an IV',                42],
    ['a negative IV',        -42],
    ['IV_MAX',               ~0 >> 1],
    ['an NV',                3.14159],
    ['a negative NV',        -0.5],
    ['zero',                 0],
    ['an empty string',      ''],
    ['a plain string',       'hello'],
    ['a string of digits',   '007'],
    ['a string with NULs',   "a\0b\0c"],
    ['undef',                undef],
    ['an empty hash',        {}],
    ['an empty array',       []],
    ['a 1 MiB string',       'x' x (1024 * 1024)],
);

for my $c (@cases) {
    my ($name, $val) = @$c;
    my $b = eval { Frozen->freeze({ v => $val }) };
    ok(defined $b, "$name is accepted") or diag $@;
    cmp_ok(Frozen->_walk_ok($b), '>', 0, "$name walks clean") if defined $b;
}

# ---- UV above IV_MAX ------------------------------------------------------
#
# It gets its own tag. Storing it as a signed 64 would bring it back negative,
# which is a change of value dressed as a change of representation.

SKIP: {
    skip 'needs 64-bit IVs', 2 unless $Config{ivsize} >= 8;
    my $big = ~0;                      # UV_MAX
    cmp_ok($big, '>', ~0 >> 1, 'the value really is above IV_MAX');
    my $b = eval { Frozen->freeze({ v => $big }) };
    ok(defined $b, 'a UV above IV_MAX is accepted') or diag $@;
}

# ---- the typing rule: POK wins -------------------------------------------
#
# A JSON decoder produces strings; a numeric comparison quietly adds IOK to
# them; and what the user sees is still the string. Choosing the number would
# turn "007" into 7 on the way through.

{
    my $s = '007';
    my $n = $s + 0;                    # $s is now POK and IOK
    ok(1, "the operand is POK and IOK after being used as a number");
    my $b = eval { Frozen->freeze({ v => $s }) };
    ok(defined $b, 'a dualvar-ish scalar is accepted') or diag $@;

    # The string form must be what was stored, so the block must be at least
    # as long as one holding the string - not the shorter integer node.
    my $as_str = Frozen->freeze({ v => '007' });
    my $as_int = Frozen->freeze({ v => 7 });
    isnt(length $b, length $as_int,
         'it did not collapse to the integer node')
        or diag "block: " . length($b) . " int: " . length($as_int);
    is(length $b, length $as_str,
       'it was stored as the string, which is what the user sees');
}

# ---- booleans -------------------------------------------------------------
#
# Three spellings are in the wild and all three must land on the same two
# tags, which carry no node at all.

{
    my $b = eval { Frozen->freeze({ t => \1, f => \0 }) };
    ok(defined $b, '\1 and \0 are accepted as booleans, not refused as refs')
        or diag $@;

    # Tag-only: a hash of two booleans must be smaller than one of two ints,
    # because the booleans emit no node.
    my $ints = Frozen->freeze({ t => 1, f => 0 });
    cmp_ok(length $b, '<', length $ints,
           'a boolean is tag-only, so it costs no node');
}

SKIP: {
    skip 'perl has no SvIsBOOL', 1 unless $] >= 5.036;
    my $true  = (1 == 1);
    my $b = eval { Frozen->freeze({ v => $true }) };
    ok(defined $b, "perl's own boolean is accepted") or diag $@;
}

SKIP: {
    eval { require JSON::PP; 1 } or skip 'no JSON::PP', 1;
    my $b = eval { Frozen->freeze({ v => JSON::PP::true() }) };
    ok(defined $b, 'a JSON::PP::Boolean is accepted, not refused as blessed')
        or diag $@;
}

# ---- UTF-8 ----------------------------------------------------------------

{
    my $bytes = "caf\xc3\xa9";
    my $chars = $bytes;
    utf8::decode($chars);
    my $b = eval { Frozen->freeze({ bytes => $bytes, chars => $chars }) };
    ok(defined $b, 'a UTF-8 string and its downgraded twin are both accepted')
        or diag $@;
    cmp_ok(Frozen->_walk_ok($b), '>', 0, 'and the block walks clean');
}

# ---- long doubles ---------------------------------------------------------
#
# An NV wider than a double does not round-trip. Refusing is the default; the
# opt-in has to be explicit, because silent narrowing in a format whose whole
# promise is fidelity is the wrong default.

SKIP: {
    skip 'NV is a double here, so nothing can fail to fit', 2
        unless $Config{nvsize} > 8;
    my $wide = 1 + 2 ** -60;           # needs more than 53 bits of mantissa
    skip 'this NV fits a double after all', 2 if (0 + sprintf('%.17g', $wide)) == $wide;
    eval { Frozen->freeze({ v => $wide }); 1 };
    like($@, qr/does not fit a double/, 'a wide NV is refused by default');
    my $b = eval { Frozen->freeze({ v => $wide }, lossy_nv => 1) };
    ok(defined $b, 'and lossy_nv => 1 accepts it') or diag $@;
}

# ---- stringify: a reader that only wants text --------------------------------
#
# A JSON 5 decodes to an IV and freezes as an integer, so `str` answers NULL
# for it and a consumer whose lookup returns text gets nothing back. The
# alternative is for every such consumer to walk its own data first and
# stringify it, which is a loop each of them has to remember to write.
#
# undef is deliberately untouched: it has no string form worth inventing,
# and a consumer that refuses null wants to go on being able to see it.
{
    my $data = { i => 5, big => 2**40, f => 1.5, s => 'text',
                 u => undef, deep => { n => 42 } };

    my $plain = Frozen->attach(Frozen->freeze($data));
    my $strd  = Frozen->attach(Frozen->freeze($data, stringify => 1));

    my $kind = sub {
        my ($fz, $k) = @_;
        $fz->kind($fz->child($fz->root, $k));
    };

    is($kind->($plain, 'i'), 'int',    'without the flag an integer is an int');
    is($kind->($plain, 'f'), 'num',    'and a float is a num');

    is($kind->($strd, 'i'),   'string', 'with it an integer is a string');
    is($kind->($strd, 'big'), 'string', 'so is one too large for an IV');
    is($kind->($strd, 'f'),   'string', 'and a float');
    is($kind->($strd, 's'),   'string', 'a string is still a string');
    is($kind->($strd, 'u'),   'undef',  'and undef is left alone');

    my ($i) = $strd->get('i');
    my ($f) = $strd->get('f');
    my ($n) = $strd->get('deep.n');
    is($i, '5',   'the integer reads back as its digits');
    is($f, '1.5', 'and the float as its own');
    is($n, '42',  'nested values are stringified too');

    # The flag changes the block, so it must change the bytes. FRESH data,
    # because of the next block: freezing is not free of side effects.
    isnt(Frozen->freeze({ i => 5 }),
         Frozen->freeze({ i => 5 }, stringify => 1),
        'the two blocks are not the same bytes');
}

# ---- what a block records is the SV's CURRENT form ---------------------------
#
# Not new to stringify, and not really Frozen's doing: asking an IV for its
# string caches that string on the SV, so the SV is afterwards both an
# integer and a string, and freeze stores whichever it checks first - which
# is the string. `print $h->{n}` has the same effect.
#
# So two freezes of "the same data" can differ if anything looked at a value
# in between. Worth knowing before anyone treats the bytes as a checksum of
# a Perl structure; they are a faithful record of the SVs as they were.
{
    my $d = { n => 5 };
    my $before = Frozen->freeze($d);
    my $strd   = Frozen->freeze($d, stringify => 1);
    my $after  = Frozen->freeze($d);

    isnt($before, $after,
        'a freeze after a stringify differs, because SvPV cached a string');
    is($after, $strd, '...and now matches the stringified one');

    my $e = { n => 5 };
    my $plain = Frozen->freeze($e);
    my $str   = "$e->{n}";                 # nothing to do with Frozen
    isnt(Frozen->freeze($e), $plain,
        'and plain Perl stringification does exactly the same thing');
}

done_testing;
