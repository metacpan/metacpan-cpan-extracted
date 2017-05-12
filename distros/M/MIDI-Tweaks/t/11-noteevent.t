#! perl

use strict;
use warnings;
use Test::More tests => 9;
use MIDI::Tweaks qw(is_note_event is_note_on is_note_off);

# -d "t" && chdir "t";
# require "./tools.pl";

ok(is_note_event(['note_on', 0, 0, 70, 77]), "noteev: note on");
ok(is_note_event(['note_off', 128, 0, 70, 0]), "noteev: note off");
ok(!is_note_event(['lyric', 0, 'The']), "not noteev: lyric");

ok(is_note_on(['note_on', 0, 0, 70, 77]), "note on: note on");
ok(!is_note_on(['note_on', 0, 0, 70, 0]), "not note on: note on zero");
ok(!is_note_on(['note_off', 0, 0, 70, 77]), "not note on: note off");

ok(!is_note_off(['note_on', 0, 0, 70, 77]), "not note off: note on");
ok(is_note_off(['note_on', 0, 0, 70, 0]), "note off: note on zero");
ok(is_note_off(['note_off', 0, 0, 70, 77]), "note off: note off");

