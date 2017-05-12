package MIDI::Realtime;

use strict;
use vars qw($VERSION);

$VERSION = '0.01';

use Fcntl;
require 'sys/soundcard.ph';

=head1 NAME

MIDI::Realtime - Writes MIDI data to /dev/sequencer in real time 

=head1 WARNING

This is heavily experimental software and may change at any moment.

Use this software at your own risk.  It works fine for me, but could do 
anything to you, your pets or your computer.

=head1 DESCRIPTION

MIDI::Realtime aims to be a handy utility for handing the output, and
one day soon, the input of MIDI data.

This module only writes MIDI data at the moment.  There are many areas 
of expansion - for example, timing, and reading MIDI data is yet to be 
implemented, and people could make subclasses for sending system 
exclusive data to their particular synthesiser.

Please contact me if you have any ideas for this.  In fact, I'd like to 
hear from you if you get any use out of it at all.

For an example of how I'm using this module, see 
http://www.slab.org/void/music/

=head1 SYNOPSIS

  use MIDI::Realtime;

  my $midi = MIDI::Realtime->new();

  # Play note 47 with maximum velocity on channel 1
  $midi->note(47, 127, 1);

  # Now have some fun with randomness

  my @notes      = (37 .. 50);
  # use all the channels (with extra drums)
  my @channels   = (1 .. 16, 10, 10, 10); 
  my @velocities = (70 .. 100);

  for (0 .. 127) {
    $midi->note($notes[rand(@notes)],
	        $channels[rand(@channels)],
                $velocities[rand(@velocities)]
	       );

    # Wait for a tenth of a second
    select(undef,undef,undef, 0.10);
  }    

=head1 FUNCTIONS

=over 4

=item B<new>()

  my $midi = MIDI::Realtime->new(dev => '/dev/sequencer',
			         midi_device => 0
			        );

This is the object constructor.  It has two, optional parameters - 'dev' 
the device file to be written to (default is '/dev/sequencer'), and 
'midi_device' is the MIDI device to use (default is 0).

=cut

sub new {
  my ($pkg, %p) = @_;

  my $self = {_dev         => ($p{dev}         || '/dev/sequencer'),
	      _midi_device => ($p{midi_device} || 0               )
	     };
  
  bless $self, $pkg;

  sysopen(SEQ_FH, $self->dev(), O_WRONLY);
  
  return $self;
}

=item B<devices>()

Not yet written.  Might one day return information about available MIDI 
devices somehow.

=cut

sub devices {
  # TODO
  #ioctl(SEQ, SNDCTL_SEQ_NRMIDIS, blah);
}

=back

=head1 METHODS THAT SEND MIDI

All the following methods return the number of bytes sent - ie 0 if something
unexpectedly evil happened.

=over 4

=item B<patch>()

  $midi->patch(2);

Sends a patch change request to the MIDI device.  Just pass it the new
patch number.

=cut

sub patch {
  my ($self, $patch_no) = @_;
  
  die "patch method is writeonly at the moment" if not defined $patch_no;

  return $self->send_midi_bytes(0xc0, $patch_no);
}

=item B<song>()

  $midi->song(6);

Sends a patch change request to the MIDI device.  Just pass it the new
song number.  This didn't seem to make my synth do what I wanted it to -
change 'performance'.  My guess is I have to send it sysex data to do that,
and that this is just for sequencers.  Let me know if you find that this 
method works for you.

=cut

sub song {
  my ($self, $song_no) = @_;

  die "song method is writeonly at the moment" if not defined $song_no;

  return $self->send_midi_bytes(0xf3, $song_no);
}

=item B<note>()

  $midi->note(40, 10, 100)

Takes three parameters.  The first is the note number, and must be 
supplied.  The second is the channel number, and defaults to 1.  The third 
is the velocity and defaults to 127.

=cut

sub note {
  my ($self, $note_no, $channel, $velocity) = @_;
  
  die "Missing note parameter" if not defined $note_no;

  $channel  = 1   if not defined $channel;
  $velocity = 127 if not defined $velocity;

  return $self->send_midi_bytes(0x90 + $channel - 1, $note_no, $velocity);
}

=item B<send_midi_bytes>()

  $midi->send_midi_bytes(0x90, 40, 100);

This method sends the given bytes to the MIDI device.  It is intended for
only internal use and experiments.  If you find some nice bytes to send, 
please let me know, or put it in MIDI::Realtime.pm and send me a patch.

=cut

sub send_midi_bytes {
  my $self = shift;
  
  my $device = $self->midi_device;

  my $stuff = pack('C*', 
		   (map {&SEQ_MIDIPUTC(),
			 $_, 
		         $device,
		         0
		        }
		    @_
		   )
		  );

  my $bytes = syswrite(SEQ_FH, $stuff);

  if (not $bytes) {
    die("Couldn't write to "
	. $self->dev 
	. ": $!"
       );
  }

  return $bytes;
}

=back

=head1 ACCESSOR METHODS

=over 4

=item B<dev>(), B<midi_device>()

These two methods return the values that were supplied (or defaulted) when
you first called new().  They are read only.

=cut

sub dev         { $_[0]->{_dev}         }
sub midi_device { $_[0]->{_midi_device} }

=back

=head1 AUTHOR

Alex McLean - alex@slab.org

=cut

##

1;
