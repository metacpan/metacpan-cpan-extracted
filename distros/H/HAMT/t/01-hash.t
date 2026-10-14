#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use HAMT ();

# The hash and the entry, through the test doors: enough to say on every
# perl in the matrix that the 64-bit arithmetic gives 64 bits, that the seed
# and the mask do what they say, and that an entry holds exactly one
# reference to its value while it lives and none after.

END { HAMT::_hash_bits(64) }

HAMT::_seed(1);
HAMT::_hash_bits(64);

my $h = HAMT::_hash_of('alpha');
like($h, qr/^[0-9a-f]{16}$/, 'a hash is sixteen hex digits');
is(HAMT::_hash_of('alpha'), $h, 'the same key hashes the same twice');
isnt(HAMT::_hash_of('alphb'), $h, 'a one-byte change moves it');
isnt(HAMT::_hash_of('alpha', 1), $h, 'the UTF-8 flag is part of the key');
isnt(HAMT::_hash_of("a\0b"), HAMT::_hash_of("a\0c"), 'bytes after a NUL count');

# 64 bits and not 32 with a zero half: over 200 keys both halves vary.
{
    my (%hi, %lo);
    for my $i (1 .. 200) {
        my $x = HAMT::_hash_of("key-$i");
        $hi{ substr $x, 0, 8 }++;
        $lo{ substr $x, 8, 8 }++;
    }
    is(scalar keys %hi, 200, 'the high 32 bits differ across 200 keys');
    is(scalar keys %lo, 200, 'and so do the low 32');
}

HAMT::_seed(2);
isnt(HAMT::_hash_of('alpha'), $h, 'another seed, another hash');
HAMT::_seed(1);
is(HAMT::_hash_of('alpha'), $h, 'and the first seed gives the first hash back');

HAMT::_hash_bits(0);
is(HAMT::_hash_of('alpha'), '0' x 16, '0 bits: every key hashes to zero');
is(HAMT::_hash_of('beta', 1), '0' x 16, 'whatever its flag');

HAMT::_hash_bits(5);
{
    my %seen;
    $seen{ HAMT::_hash_of("key-$_") }++ for 1 .. 1000;
    is(scalar keys %seen, 32, '5 bits: a thousand keys land on exactly 32 values');
    ok(!(grep { hex(substr $_, 8) > 31 || substr($_, 0, 8) ne '00000000' } keys %seen),
       'all of them under 32');
}

HAMT::_hash_bits(32);
is(substr(HAMT::_hash_of('alpha'), 0, 8), '00000000', '32 bits: the high half is clear');
is(substr(HAMT::_hash_of('alpha'), 8), substr($h, 8), 'and the low half is the whole hash\'s');

HAMT::_hash_bits(64);
is(HAMT::_hash_of('alpha'), $h, '64 bits: the whole hash is back');
HAMT::_hash_bits(1000);
is(HAMT::_hash_of('alpha'), $h, 'and more than 64 means 64');

# ---- the seed a process starts with ---------------------------------------
#
# Two fresh processes must not agree, or the seed is a constant.
{
    my @cmd = ($^X, (map { "-I$_" } @INC), '-MHAMT', '-e', 'print HAMT::_hash_of(q(alpha))');
    my %got;
    for (1 .. 3) {
        open my $fh, '-|', @cmd or do { %got = (); last };
        my $x = <$fh>;
        close $fh;
        $got{$x}++ if defined $x && $x =~ /^[0-9a-f]{16}$/;
    }
  SKIP: {
        skip 'could not start a child perl', 1 unless %got;
        cmp_ok(scalar keys %got, '>', 1, 'fresh processes start with different seeds');
    }
}

# ---- an entry and the value it holds --------------------------------------
{
    my $v = 'value';
    my $before = Internals::SvREFCNT($v);
    my ($held, $self_eq, $flag_eq) = HAMT::_entry_probe('alpha', 0, $v);
    is($held, $before + 1, 'a live entry holds one reference to its value');
    is(Internals::SvREFCNT($v), $before, 'and gives it back when it goes');
    ok($self_eq, 'its key equals itself');
    ok(!$flag_eq, 'and not the same bytes under the other flag');

    ($held, $self_eq, $flag_eq) = HAMT::_entry_probe('', 1, $v);
    ok($self_eq && !$flag_eq, 'the empty key likewise');

    my $big = 'k' x 70_000;
    ($held, $self_eq, $flag_eq) = HAMT::_entry_probe($big, 0, $v);
    ok($self_eq && !$flag_eq, 'and a 70,000-byte one');
    is(Internals::SvREFCNT($v), $before, 'the value is where it started after all three');
}

# A value whose last reference is the entry's: its DESTROY runs when the
# entry goes, and what it does then must find nothing half-freed.
{
    package Local::Counted;
    our $destroyed = 0;
    our $reentered;
    sub new { bless [], shift }
    sub DESTROY {
        $destroyed++;
        $reentered = join ',', HAMT::_entry_probe('inner', 0, 'x');
    }
}
{
    my $ref = \my $slot;
    $slot = Local::Counted->new;
    HAMT::_entry_probe('outer', 0, $slot);
    is($Local::Counted::destroyed, 0, 'an object outlives a probe that only borrowed it');
    undef $slot;
    is($Local::Counted::destroyed, 1, 'and is destroyed once, when its owner lets go');
    like($Local::Counted::reentered, qr/^\d+,1,0$/,
         'its DESTROY came back into the library and got a right answer');
}

done_testing;
