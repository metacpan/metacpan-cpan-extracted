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

# ---- the typing rule: the PUBLIC flags decide -----------------------------
#
# A private flag says only that a cached conversion sits in that slot, and the
# conversion may be lossy: comparing 1.5 against an integer leaves the
# truncated 1 in its IV slot under pIOK alone. Dispatching on that stores 1
# and calls it an integer, which is a change of value nobody asked for.

{
    my $n   = 1.5;
    my $cmp = ($n == 1);               # $n is now NOK and pIOK, with IV 1
    my $fz  = Frozen->attach(Frozen->freeze({ v => $n }));
    my $h   = $fz->child($fz->root, 'v');
    is($fz->kind($h), 'num',
       'an NV that has been compared with an integer is still a num');
    cmp_ok($fz->value($h), '==', 1.5, 'and it kept the value it was given');
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
# A block holds a double, so on a perl whose NV is wider - uselongdouble,
# usequadmath - storing one rounds. Rounding to the nearest double is the
# format, and refusing it would refuse 0.1 on those perls. What is refused is
# a narrowing that destroys the value rather than its tail: a finite NV that
# comes back as an infinity, and a non-zero one that comes back as zero.

SKIP: {
    skip 'NV is a double here, so no narrowing can happen', 4
        unless $Config{nvsize} > 8;

    my $huge = 2 ** 2000;              # past DBL_MAX, inside a long double
    my $tiny = 2 ** -2000;             # under the smallest double denormal
    skip 'this NV is wider than a double but has its exponent range', 4
        unless $huge + $huge != $huge && $tiny != 0;

    eval { Frozen->freeze({ v => $huge }); 1 };
    like($@, qr/too large for a double/, 'an NV past DBL_MAX is refused by default');
    ok(defined eval { Frozen->freeze({ v => $huge }, lossy_nv => 1) },
       'and lossy_nv => 1 stores it as an infinity') or diag $@;

    eval { Frozen->freeze({ v => $tiny }); 1 };
    like($@, qr/too small for a double/, 'an NV under DBL_MIN is refused by default');
    ok(defined eval { Frozen->freeze({ v => $tiny }, lossy_nv => 1) },
       'and lossy_nv => 1 stores it as a zero') or diag $@;
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

# ---- a cached conversion does not change the block ---------------------------
#
# Asking an IV for its string caches that string on the SV, and reading it
# back is the ordinary way a program uses its own data. Neither changes what
# the value is, so neither may change the bytes: two freezes of untouched
# data have to agree however that data was read in between, or the block
# records the order someone looked at the structure rather than the
# structure.
#
# Before 5.36, perl set the public POK flag when it stringified a number,
# so a stringified integer carries exactly the flags of a numified string
# and the POK-wins rule above has to choose the string. 5.36 made that
# cache private. Those perls get the documented answer instead: the same
# bytes as stringify => 1.
{
    my $d = { n => 5 };
    my $before = Frozen->freeze($d);
    my $strd   = Frozen->freeze($d, stringify => 1);
    my $after  = Frozen->freeze($d);

    isnt($strd, $before, 'stringify => 1 gives its own bytes');

    my $e = { n => 5 };
    my $plain = Frozen->freeze($e);
    my $str   = "$e->{n}";                 # nothing to do with Frozen
    my $again = Frozen->freeze($e);

    if ($] >= 5.036) {
        is($after, $before, 'a freeze after a stringify gives the same bytes');
        is($again, $plain,  'and plain Perl stringification leaves it alone too');
    }
    else {
        is($after, $strd, 'before 5.36 a stringified integer freezes as its string');
        is($again, $strd, 'whoever did the stringifying');
    }
}

done_testing;
