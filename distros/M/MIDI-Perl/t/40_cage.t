
use strict;
use Test;
BEGIN { plan tests => 35 }

use MIDI;
ok 1;

print map "#\t$_\n",
 q["I have nothing to say], q[ and I am saying it],
 q[ and that is poetry],    q[ as I needed it"],
 q[     -- John Cage]
;


my $in = "cage.mid";
for my $i ( "$in", "t/$in", "t\\$in", "t:$in" ) {
  if( -e $i ) { $in = $i; last; }
}

die "Can't find $in" unless -e $in;

ok -s $in, 39;

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
ok scalar(@{ $t->events_r } ), 3;
my @e = $t->events;
ok $e[0], $t->events_r->[0]; # tests coreference


my $it;
$it = $e[0];  print "# Event 0: [@$it]\n";
ok $it->[0], "patch_change";
ok scalar( @$it ), 4 or die;  
ok $it->[1], "0";
ok $it->[2], "0";
ok $it->[3], "0";


$it = $e[1];  print "# EVent 1: [@$it]\n";
ok $it->[0], "note_on";
ok scalar( @$it ), 5 or die;
ok $it->[1], "0";
ok $it->[2], "0";
ok $it->[3], "20";
ok $it->[4], "0";


$it = $e[2];  print "# Event 2: [@$it]\n";
ok $it->[0], "note_off";
ok scalar( @$it ), 5 or die;
ok $it->[1], "52416";
ok $it->[2], "0";
ok $it->[3], "20";
ok $it->[4], "0";




print "# Okay, all done!\n";
ok 1;

