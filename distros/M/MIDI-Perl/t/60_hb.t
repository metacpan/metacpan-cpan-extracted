
use strict;
use Test;
BEGIN { plan tests => 65 }

use MIDI;
ok 1;

my $in = "hb.mid";
for my $i ( "$in", "t/$in", "t\\$in", "t:$in" ) {
  if( -e $i ) { $in = $i; last; }
}

die "Can't find $in" unless -e $in;

ok -s $in, 1310;

my $o = MIDI::Opus->new( { 'from_file' => $in } );
ok 1;
print "# Opus: [$o]\n";
ok ref($o), "MIDI::Opus", "checking opus classitude"; # sanity
ok $o->ticks, 480;
ok $o->format, 1;


my @t = $o->tracks;
print "# Tracks: [@t]\n";
ok scalar(@t), 4, "checking track count"  or die;

my $t;

print "#### TRACK 0\n";

$t = $t[0];
ok ref($t), "MIDI::Track";
ok $t->type, "MTrk";
my @e;

ok defined( $o->tracks_r );
ok ref( $o->tracks_r ), 'ARRAY' or die;
ok scalar( @{ $o->tracks_r } ), 4;
ok $o->tracks_r->[0], $t; 



ok defined($t->events_r);
ok ref($t->events_r), "ARRAY" or die;
ok scalar(@{ $t->events_r } ), 6;
@e = $t->events;
ok $e[0], $t->events_r->[0]; # tests coreference

my $it;

$it = $e[0];  print "# Event 0: [@$it]\n";
ok $it->[0], "track_name";
ok scalar( $it and @$it ), 3 or die;  

$it = $e[1];  print "# EVent 1: [@$it]\n";
ok $it->[0], "smpte_offset";
ok scalar( $it and @$it ), 7 or die;  

$it = $e[2];  print "# Event 2: [@$it]\n";
ok $it->[0], "set_tempo";
ok $it->[1], "0";
ok $it->[2], "600000";
ok scalar( $it and @$it ), 3 or die;  

$it = $e[3];  print "# Event 3: [@$it]\n";
ok $it->[0], "time_signature";
ok scalar( $it and  @$it ), 6 or die;  
ok $it->[1], "0";
ok $it->[2], "4";
ok $it->[3], "2";
ok $it->[4], "24";
ok $it->[5], "8";

$it = $e[4];  print "# Event 4: [@$it]\n";
ok $it->[0], "set_tempo";
ok $it->[1], "11514";
ok $it->[2], "750000";
ok scalar( $it and @$it ), 3 or die;  

$it = $e[5];  print "# Event 5: [@$it]\n";
ok $it->[0], "text_event";
ok $it->[1], "7686";
ok $it->[2], "";
ok scalar( $it and @$it ), 3 or die;  


print "#### TRACK 1\n";
$t = $t[1];
ok ref($t), "MIDI::Track";
ok $t->type, "MTrk";

ok defined($t->events_r);
ok ref($t->events_r), "ARRAY" or die;
ok scalar(@{ $t->events_r } ), 158;
@e = $t->events;
ok $e[0], $t->events_r->[0]; # tests coreference

$it = $e[0];  print "# Event 0: [@$it]\n";
ok $it->[0], "instrument_name";
ok scalar( $it and @$it ), 3 or die;  




print "#### TRACK 2\n";
$t = $t[2];
ok ref($t), "MIDI::Track";
ok $t->type, "MTrk";

ok defined($t->events_r);
ok ref($t->events_r), "ARRAY" or die;
ok scalar(@{ $t->events_r } ), 58;
@e = $t->events;
ok $e[0], $t->events_r->[0]; # tests coreference

$it = $e[0];  print "# Event 0: [@$it]\n";
ok $it->[0], "instrument_name";
ok scalar( $it and @$it ), 3 or die;  



print "#### TRACK 3\n";
$t = $t[3];
ok ref($t), "MIDI::Track";
ok $t->type, "MTrk";

ok defined($t->events_r);
ok ref($t->events_r), "ARRAY" or die;
ok scalar(@{ $t->events_r } ), 144;
@e = $t->events;
ok $e[0], $t->events_r->[0]; # tests coreference

$it = $e[0];  print "# Event 0: [@$it]\n";
ok $it->[0], "instrument_name";
ok scalar( $it and @$it ), 3 or die;  



print "# Okay, all done!\n";
ok 1;

