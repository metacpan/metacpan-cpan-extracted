
use strict;
use Test;
BEGIN { plan tests => 28 }

use MIDI;
ok 1;

my $in = "j07003.mid";
for my $i ( "$in", "t/$in", "t\\$in", "t:$in" ) {
  if( -e $i ) { $in = $i; last; }
}

die "Can't find $in" unless -e $in;

ok -s $in, 3445;

my $o = MIDI::Opus->new( { 'from_file' => $in } );
ok 1;
print "# Opus: [$o]\n";
ok ref($o), "MIDI::Opus", "checking opus classitude"; # sanity
ok $o->ticks, 96;
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
ok scalar(@{ $t->events_r } ), 653;
my @e = $t->events;
ok $e[0], $t->events_r->[0]; # tests coreference


my $it;
$it = $e[0];  print "# Event 0: [@$it]\n";
ok $it->[0], "set_tempo";
ok scalar( @$it ), 3 or die;  

$it = $e[1];  print "# EVent 1: [@$it]\n";
ok $it->[0], "patch_change";
ok scalar( @$it ), 4 or die;  

$it = $e[2];  print "# Event 2: [@$it]\n";
ok $it->[0], "text_event";
ok scalar( @$it ), 3 or die;  

$it = $e[3];  print "# Event 3: [@$it]\n";
ok $it->[0], "note_on";
ok scalar( @$it ), 5 or die;  

$it = $e[4];  print "# Event 4: [@$it]\n";
ok $it->[0], "note_on";
ok scalar( @$it ), 5 or die;  



print "# Okay, all done!\n";
ok 1;
