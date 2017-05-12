
use strict;
use Test;
BEGIN { plan tests => 51 }
ok 1;
use MIDI;

my $out = 'temp30.mid';
-e $out and unlink $out;

{ no strict;
  no warnings;
 use MIDI::Simple;
 new_score;
 @Score = ();

 text_event 'so, by Thy power/ no foot shall slide';
 set_tempo 500000;  # 1 qn => .5 seconds (500,000 microseconds)
 patch_change 1, 8;  # Patch 8 = Celesta

 noop c1, f, o5;  # Setup
 # Now play
 n qn, Cs;    n F;   n Ds;  n hn, Gs_d1;
 n qn, Cs;    n Ds;  n F;   n hn, Cs;
 n qn, F;     n Cs;  n Ds;  n hn, Gs_d1;
 n qn, Gs_d1; n Ds;  n F;   n hn, Cs;

 write_score $out;
 ok 1;
}

sleep 1; #  "IT'S OH SO QUIET.  SHHHHHHH.  SHHHHHHH.  IT'S OH SO STILL."
ok -e $out or die;
ok -s $out;
ok -s $out > 200;
ok -s $out < 400;

my $o = MIDI::Opus->new( { 'from_file' => $out } );
ok 1;
print "# Opus: [$o]\n";
ok ref($o), "MIDI::Opus", "checking opus classitude"; # sanity
ok $o->ticks, 96;
$o->ticks(123);
ok $o->ticks, 123;
ok $o->format, 0;
$o->format(1);
ok $o->format, 1;

my @t = $o->tracks;
print "# Tracks: [@t]\n";
ok scalar(@t), 1, "checking track count"  or die;

my $t = $t[0];
ok ref($t), "MIDI::Track";
ok $t->type, "MTrk";


ok defined( $o->tracks_r );
ok ref( $o->tracks_r ), 'ARRAY' or die;
ok scalar( @{ $o->tracks_r } ), 1;
ok $o->tracks_r->[0], $t; 

ok defined($t->events_r);
ok ref($t->events_r), "ARRAY" or die;
ok scalar(@{ $t->events_r } ),		35;
my @e = $t->events;
ok $e[0], $t->events_r->[0]; # tests coreference


my $it; # just a scratch var

ok ref($e[0]), "ARRAY" or die;
ok scalar( @{ $it = $e[0] } ), 3 or die;  print "# First event: [@$it]\n";
ok $it->[0], "text_event";
ok $it->[1], "0";
ok $it->[2], "so, by Thy power/ no foot shall slide";


ok scalar( @{ $it = $e[1] } ), 3 or die;  print "# Second event: [@$it]\n";
ok $it->[0], "set_tempo";
ok $it->[1], "0";
ok $it->[2], "500000";

ok scalar( @{ $it = $e[2] } ), 4 or die;  print "# Third event: [@$it]\n";
ok $it->[0], "patch_change";
ok $it->[1], "0";
ok $it->[2], "1";
ok $it->[3], "8";

ok scalar( @{ $it = $e[3] } ), 5 or die;  print "# Fourth event: [@$it]\n";
ok $it->[0], "note_on";
ok $it->[1], "0";
ok $it->[2], "1";
ok $it->[3], "61";
ok $it->[4], "96";


ok scalar( @{ $it = $e[4] } ), 5 or die;  print "# Fifth event: [@$it]\n";
ok $it->[0], "note_off";
ok $it->[1], "96";
ok $it->[2], "1";
ok $it->[3], "61";
ok $it->[4], "0";

$t->type("Muck");
ok $t->type, "Muck";

unlink $out;
print "# Okay, all done!\n";
ok 1;

