use Test::More tests => 2 + 4 + 2 * 127;

# Test rounding in pitch conversion

use MIDI::Pitch qw(name2pitch pitch2name);

# Test some special cases ------------------------------------------------

# "middle C" = C4 = 60
is(pitch2name(59.5), 'c4');
is(pitch2name(60.49), 'c4');

# Test "round trip" ------------------------------------------------------

is(name2pitch(pitch2name(-0.5)), undef);
is(name2pitch(pitch2name(-0.49)), 0);
is(name2pitch(pitch2name(0.49)), 0);
is(name2pitch(pitch2name(0.5)), 1);

for (1..127) {
    is(name2pitch(pitch2name($_ - 0.5)), $_);
    is(name2pitch(pitch2name($_ + 0.49)), $_);
}