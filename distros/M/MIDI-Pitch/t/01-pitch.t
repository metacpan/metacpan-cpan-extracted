use Test::More tests => 15 + 9 + 11 + 128*2;

# test conversion to pitch

use MIDI::Pitch qw(name2pitch pitch2name);

# Test some special cases ------------------------------------------------

ok(!defined name2pitch());
ok(!defined pitch2name());

ok(!defined name2pitch('garbage'));
ok(!defined pitch2name('garbage'));

ok(!defined name2pitch(10));
ok(!defined pitch2name('c0'));

# "middle C" = 60
ok(name2pitch('c4') == 60);
ok(pitch2name(60) eq 'c4');

# undefined - -1
ok (!defined pitch2name(-1));

# lowest - c-1
ok(name2pitch('c-1') == 0);
ok(pitch2name(0) eq 'c-1');

# highest - g9
ok(name2pitch('g9') == 127);
ok(pitch2name(127) eq 'g9');

# undefined - g#9
ok(!defined name2pitch('g#9'));
ok(!defined pitch2name(128));

# Test enharmonic notes --------------------------------------------------

my @enh = (['c#', 'db'], ['d#', 'eb'], ['e', 'fb'], ['e#', 'f'],
           ['f#', 'gb'], ['g#', 'ab'], ['a#', 'bb'], ['b', 'cb'],
           ['b#', 'c']);

foreach (@enh) {
    my ($a1, $b1) = @{$_};
    
    ok(name2pitch($a1 . '4') == name2pitch($b1 . '4'));
}

# Test a few selected pitches --------------------------------------------

my @pitches = (['c#-1' => 1], [d0 => 14], ['d#1' => 27], [e2 => 40],
               [f3 => 53], ['f#4' => 66], [g5 => 79], ['g#6' => 92],
               [a7 => 105], ['a#8' => 118], [b8 => 119]);

foreach (@pitches) {
    my ($a2, $b2) = @{$_};
    
    ok($a2 eq pitch2name($b2));
}

# Test conversion back and forth -----------------------------------------

for (0..127) {
    my $r = pitch2name($_);
    ok(name2pitch(lc $r) == $_);
    ok(name2pitch(uc $r) == $_);
}

# http://www.harmony-central.com/MIDI/Doc/table2.html

# g9 = 127
# c9 = 120
# c8 = 108
# c7 = 96
# c6 = 84
# c5 = 72
# c4 = 60
# c3 = 48
# c2 = 36
# c1 = 24
# c0 = 12
# c-1 = 0



