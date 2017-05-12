
use strict;
use Test;
BEGIN { plan tests => 60 }

use MIDI;
ok 1;

my $in = "dr_m.mid";
for my $i ( "$in", "t/$in", "t\\$in", "t:$in" ) {
  if( -e $i ) { $in = $i; last; }
}

die "Can't find $in" unless -e $in;

ok -s $in, 254;

my $o = MIDI::Opus->new( { 'from_file' => $in } );
ok 1;
print "# Opus: [$o]\n";
ok ref($o), "MIDI::Opus", "checking opus classitude"; # sanity
ok $o->ticks, 384;
ok $o->format, 0;


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
ok scalar(@{ $t->events_r } ), 45;
my @e = $t->events;
ok $e[0], $t->events_r->[0]; # tests coreference

# And just test the first few events...



my $it;
$it = $e[0];  print "# Event 0: [@$it]\n";
ok $it->[0], "copyright_text_event";
ok scalar( @$it ), 3 or die;  
ok $it->[1], "0";
ok $it->[2], "";

$it = $e[1];  print "# EVent 1: [@$it]\n";
ok $it->[0], "track_name";
ok scalar( @$it ), 3 or die;  
ok $it->[1], "0";
ok $it->[2], "MIDI by MidiGen 0.9";


$it = $e[2];  print "# Event 2: [@$it]\n";
ok $it->[0], "control_change";
ok scalar( @$it ), 5 or die;  
ok $it->[1], "0";
ok $it->[2], "0";
ok $it->[3], "7";
ok $it->[4], "127";


ok($it = $e[3]) or die;  print "# Event 3: [@$it]\n";
ok $it->[0], "set_tempo";
ok scalar( @$it ), 3 or die;  
ok $it->[1], "0";
ok $it->[2], "400000";


$it = $e[4];  print "# Event 4: [@$it]\n";
ok $it->[0], "patch_change";
ok scalar( @$it ), 4 or die;  
ok $it->[1], "0";
ok $it->[2], "0";
ok $it->[3], "1";



$it = $e[5];  print "# Event 5: [@$it]\n";

ok $it->[0], "note_on";
ok scalar( @$it ), 5 or die;  
ok $it->[1], "0";
ok $it->[2], "0";
ok $it->[3], "69";
ok $it->[4], "100";

$it = $e[6];  print "# Event 6: [@$it]\n";

ok $it->[0], "note_off";
ok scalar( @$it ), 5 or die;  
ok $it->[1], "192";
ok $it->[2], "0";
ok $it->[3], "69";
ok $it->[4], "0";

$it = $e[7];  print "# Event 7: [@$it]\n";

ok $it->[0], "note_on";
ok scalar( @$it ), 5 or die;  
ok $it->[1], "0";
ok $it->[2], "0";
ok $it->[3], "68";
ok $it->[4], "100";


print "# Okay, all done!\n";
ok 1;

