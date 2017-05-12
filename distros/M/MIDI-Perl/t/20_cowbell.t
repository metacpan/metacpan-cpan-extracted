
use strict;
use Test;
BEGIN { plan tests => 47 }

use MIDI;
ok 1;

my $out = "temp20.mid";
unlink $out if -e $out;
{
 my @events = (
   ['text_event',0, 'MORE COWBELL'],
   ['set_tempo', 0, 450_000], # 1qn = .45 seconds
 );

 for (1 .. 20) {
   push @events,
     ['note_on' , 90,  9, 56, 127],
     ['note_off',  6,  9, 56, 127],
   ;
 }
 foreach my $delay (reverse(1..96)) {
   push @events,
     ['note_on' ,      0,  9, 56, 127],
     ['note_off', $delay,  9, 56, 127],
   ;
 }

 my $cowbell_track = MIDI::Track->new({ 'events' => \@events });
 ok 1;
 my $opus = MIDI::Opus->new(
  { 'format' => 0, 'ticks' => 96, 'tracks' => [ $cowbell_track ] } );
 ok 1;
 $opus->write_to_file( $out );
 ok 1;
}
sleep 1; # festina lente
ok -e $out or die;
ok -s $out;
ok -s $out >  900;
ok -s $out < 1100;

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
ok scalar(@{ $t->events_r } ), 234;
my @e = $t->events;
ok $e[0], $t->events_r->[0]; # tests coreference

print "# First event: [@{$e[0]}]\n";

ok ref($e[0]), "ARRAY" or die;
ok scalar( @{ $e[0] } ), 3 or die;
ok $e[0][0], "text_event";
ok $e[0][1], "0";
ok $e[0][2], "MORE COWBELL";

print "# Second event: [@{$e[1]}]\n";

ok scalar( @{ $e[1] } ), 3 or die;
ok $e[1][0], "set_tempo";
ok $e[1][1], "0";
ok $e[1][2], "450000";

print "# Third event: [@{$e[2]}]\n";

ok scalar( @{ $e[2] } ), 5 or die;
ok $e[2][0], "note_on";
ok $e[2][1], "90";
ok $e[2][2], "9";
ok $e[2][3], "56";
ok $e[2][4], "127";


print "# Fourth event: [@{$e[3]}]\n";
ok $e[3][0], "note_off";
ok $e[3][1], "6";
ok $e[3][2], "9";
ok $e[3][3], "56";
ok $e[3][4], "127";

$t->type("Muck");
ok $t->type, "Muck";

unlink $out;
print "# Okay, all done!\n";
ok 1;
