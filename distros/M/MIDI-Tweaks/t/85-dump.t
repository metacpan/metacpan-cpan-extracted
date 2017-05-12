#! perl

my $id = "85-dump";

# Test midi-dump

use strict;
use warnings;
use MIDI;

use constant INLINE => 0;

my @nlist = ( 2 .. 9 );
my @dlist = ( 4, 8 );

use Test::More;
use File::Spec;
-d "t" && chdir "t";
require "./tools.pl";

plan tests => scalar(@dlist)*scalar(@nlist) + INLINE;

# Get platform-independent file names.
my $dumper = File::Spec->catfile("../blib/script", "midi-dump");
require_ok($dumper) if INLINE;

my $opus = do { local $/; <DATA> };
my $op = eval $opus;
BAIL_OUT("Error in Opus data") unless $op;

for my $d ( @dlist ) {
    for my $n ( @nlist ) {
	my $t = $id . $n . $d;

      SKIP: {

	    skip "No test for $n/$d", 1 unless -s "$t.ref";

	    my @cln = map { "$t.$_" } qw(out mid);
	    unlink(@cln);

	    # Set the desires time signature.
	    $op->{tracks}->[0]->{events}->[1]
	      = [ 'time_signature', 0,
		  $n,
		  $d ==  1 ? ( 0, 96 ) :
		  $d ==  2 ? ( 1, 48 ) :
		  $d ==  4 ? ( 2, 24 ) :
		  $d ==  8 ? ( 3, 12 ) :
		  $d == 16 ? ( 4,  6 ) : die("d = $d?"),
		  8,
		];

	    if ( INLINE ) {
		open(my $fh, '>', "$t.out");
		select($fh);
		midi_dump($op);
		select(STDOUT);
	    }
	    else {
		$op->write_to_file("$t.mid");
		system("$^X $dumper $t.mid > $t.out");
	    }

	    if ( differ("$t.out", "$t.ref", 1) ) {
		fail("compare $n/$d");
	    }
	    else {
		pass("compare $n/$d");
		# Cleanup.
		unlink(@cln);
	    }
	}
    }
}

__END__
MIDI::Opus->new({
  'format' => 1,
  'ticks'  => 480,
  'tracks' => [

    MIDI::Track->new({
      'type' => 'MTrk',
      'events' => [
        ['set_tempo', 0, 500000],
        ['time_signature', 0, 'n', 'd', 'q', 8],
      ]
    }),

    MIDI::Track->new({
      'type' => 'MTrk',
      'events' => [

        ['track_name', 0, ''],
        ['patch_change', 0, 0, 0],
        ['control_change', 0, 0, 7, 100],
        ['control_change', 0, 0, 10, 64],
        ['note_on', 0, 0, 60, 100],
        ['note_off', 240, 0, 60, 127],
        ['note_on', 0, 0, 62, 100],
        ['note_off', 240, 0, 62, 127],
        ['note_on', 0, 0, 64, 100],
        ['note_off', 240, 0, 64, 127],
        ['note_on', 0, 0, 65, 100],
        ['note_off', 240, 0, 65, 127],
        ['note_on', 0, 0, 67, 100],
        ['note_off', 240, 0, 67, 127],
        ['note_on', 0, 0, 69, 100],
        ['note_off', 240, 0, 69, 127],
        ['note_on', 0, 0, 71, 100],
        ['note_off', 240, 0, 71, 127],
        ['note_on', 0, 0, 72, 100],
        ['note_off', 240, 0, 72, 127],
        ['note_on', 0, 0, 74, 100],
        ['note_off', 240, 0, 74, 127],
        ['note_on', 0, 0, 76, 100],
        ['note_off', 240, 0, 76, 127],
        ['note_on', 0, 0, 76, 100],
        ['note_off', 240, 0, 76, 127],
        ['note_on', 0, 0, 74, 100],
        ['note_off', 240, 0, 74, 127],
        ['note_on', 0, 0, 72, 100],
        ['note_off', 240, 0, 72, 127],
        ['note_on', 0, 0, 71, 100],
        ['note_off', 240, 0, 71, 127],
        ['note_on', 0, 0, 69, 100],
        ['note_off', 240, 0, 69, 127],
        ['note_on', 0, 0, 67, 100],
        ['note_off', 240, 0, 67, 127],
        ['note_on', 0, 0, 65, 100],
        ['note_off', 240, 0, 65, 127],
        ['note_on', 0, 0, 64, 100],
        ['note_off', 240, 0, 64, 127],
        ['note_on', 0, 0, 62, 100],
        ['note_off', 240, 0, 62, 127],
        ['note_on', 0, 0, 60, 100],
        ['note_off', 240, 0, 60, 127],
      ]
    }),
  ]
});
