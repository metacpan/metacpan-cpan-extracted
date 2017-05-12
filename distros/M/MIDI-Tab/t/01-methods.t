#!perl -T
use strict;
use warnings;
use Test::More 'no_plan';

BEGIN {
    use_ok('MIDI::Tab');
    use_ok('MIDI::Simple');
}

my $file = 't/drums.mid';
my $tab = <<'EOF';
CYM: 8-------------------------------
BD:  8-4---8-2-8-----8-4---8-2-8-----
SD:  ----8-------8-------8-------8---
HH:  66--6-6-66--6-6-66--6-6-66--6-6-
OHH: --6-------6-------6-------6-----
EOF
new_score;
synch( sub { from_drum_tab($_[0], $tab, 'sn') } );
write_score($file);
ok -s $file, 'drums';

$file = 't/guitar.mid';
$tab = <<'EOF';
E5: +---0-------0---+---0-----------
B4: --------3-------1-------0-------
G4: --------------------------0---0-
D4: --2---2---2---2---2---2-----2---
A3: 3-------------------------------
E3: --------------------------------
EOF
new_score;
patch_change 2, 24;
synch( sub { from_guitar_tab($_[0], $tab, 'sn', 'c2') } );
write_score($file);
ok -s $file, 'guitar';

$file = 't/piano.mid';
$tab = <<'EOF';
C5: 5-9-|5--9
C3: -5-9|5--9
EOF
new_score;
synch( sub { from_piano_tab($_[0], $tab, 'wn') } );
write_score($file);
ok -s $file, 'piano';

$file = 't/control.mid';
$tab = <<'EOF';
CTL: --------3-3-3-3---------
HH:  959595959595959595959595
EOF
new_score;
synch( sub { from_drum_tab($_[0], $tab, 'en') } );
write_score($file);
ok -s $file, 'control';
