package MIDI::Music;

use strict;
use Carp;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Fcntl;

require Exporter;
require DynaLoader;
require AutoLoader;

@ISA = qw(Exporter DynaLoader);
@EXPORT = qw();
$VERSION = '0.01';

sub AUTOLOAD {

    my $constname;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "& not defined" if $constname eq 'constant';
    my $val = constant($constname, @_ ? $_[0] : 0);
    if ($! != 0) {
	if ($! =~ /Invalid/) {
	    $AutoLoader::AUTOLOAD = $AUTOLOAD;
	    goto &AutoLoader::AUTOLOAD;
	}
	else {
		croak "Your vendor has not defined MIDI::Music macro $constname";
	}
    }
    no strict 'refs';
    *$AUTOLOAD = sub { $val };
    goto &$AUTOLOAD;
}

bootstrap MIDI::Music $VERSION;

sub DESTROY {
    my $mm = shift;
    $mm->close() if ($mm->{'_initialized'});
}

################################################################################
################################# Constructor ##################################
sub new {

    my $class = shift;
    my %param = @_;

    ######################################
    # Device number (0 == first available)
    my $device = $param{'device'} || 0;    # Device number

    ##############################
    # Recording-related parameters
    my $readbuf  = $param{'readbuf'}  || 4096; # events per read * 8
    #my $actsense = $param{'actsense'} || 0;    # enable active sensing
    my $realtime = $param{'realtime'} || 0;    # realtime messages on
    #my $timing   = $param{'timing'}   || 0;    # timer on (requires rt(?))

    #############################
    # Playback-related parameters
    #my $extbuf      = $param{'extbuf'}  || 0;    # ?? not documented
    my $gmdrum      = $param{'gmdrum'}  || [];   # Drums to cache
    my $gminstr     = $param{'gminstr'} || [];   # Patches to cache

    ###################################
    # Initial timing parameters
    my $timebase = $param{'timebase'} || 96;  # Ticks per quarter-note
    my $tempo    = $param{'tempo'}    || 120; # BPM
    my $timesig  = $param{'timesig'}  || [0x04, 0x02, 0x18, 0x08]; # 4/4

    my $ppqn_per_clock = $timebase / 24; # Clocks (pulses) per quarter-note

    my $self = {'_device'      => $device,
                '_errstr'      => '',
                '_initialized' => 0,

                '_event_times' => [], # For the storage of
                '_midistruct'  => {}, #   MIDI file data

                '_readbuf'   => $readbuf,
                #'_actsense'  => $actsense,
                '_realtime'  => $realtime,
                #'_timing'    => $timing,
                '_rec_dtime' => 0, # if timing is enabled, this is
                                   #   calculated and supplied as
                                   #   1th element of text events

                #'_extbuf'         => $extbuf,
                '_gmdrum'         => $gmdrum,
                '_gminstr'        => $gminstr,

                '_tempo'          => $tempo,
                '_timebase'       => $timebase,
                '_ppqn_per_clock' => $ppqn_per_clock,

                '_timesig' => $timesig,
                };

    return bless $self, $class;
}

################################################################################
########################### Misc. ##############################################
sub errstr {
    my $mm = shift;
    return $mm->{'_errstr'};
}


################################################################################
####################### MIDI File Methods ######################################
sub _clear {

    my $mm = shift;
    $mm->{'_midistruct'}  = {};
    $mm->{'_event_times'} = [];
}

sub _loadmidifile {

    my $mm       = shift;
    my $midifile = shift;

    if (eval 'require MIDI') {

        my $opus = MIDI::Opus->new({'from_file' => $midifile});

        $mm->{'_timebase'} = $opus->ticks();
        my $format         = $opus->format();
        my $pos            = 0;

        foreach my $track (@{$opus->tracks_r}) {

            my $events_r = $track->events_r;
            $pos         = 0 unless ($format == 2);

            foreach my $event (@{$events_r}) {

                $pos += $event->[1]; # Add current dtime to last position

                push(@{$mm->{'_midistruct'}->{$pos}}, $event);
            }
        }
        $mm->{'_event_times'} = [ sort { $a <=> $b } keys %{$mm->{'_midistruct'}} ];

    } else {
        $mm->{'_errstr'} = ref($mm) . "::_loadmidifile(): require MIDI: $!";
        return 0;
    }
    return 1;
}

sub playmidifile {

    my $mm       = shift;
    my $midifile = shift || '';

    if ($midifile) {

        unless ($mm->_loadmidifile($midifile)) {
            $mm->{'_errstr'} = ref($mm) . '::playmidifile(): ' . $mm->{'_errstr'};
            return 0;
        }

    } else {
        $mm->{'_errstr'} = ref($mm) . '::playmidifile(): no file supplied';
        return 0;
    }

    unless ($mm->{'_initialized'}) {

        unless ($mm->init('mode' => O_WRONLY)) {
            $mm->{'_errstr'} = ref($mm) . '::playmidifile(): ' . $mm->{'_errstr'};
            return 0;
        }
    }

    $mm->_playloaded() || do {
        $mm->{'_errstr'} = ref($mm) . '::playmidifile(): ' . $mm->{'_errstr'};
        return 0;
    };
    $mm->close();
    $mm->_clear();

    return 1;
}

sub _playloaded {

    my $mm    = shift;
    my $dtime = 0;
    my $last  = 0;

    my $events = [];
    for (0 .. $#{$mm->{'_event_times'}}) {

        my $pos   = $mm->{'_event_times'}->[$_];
        my $dtime = $pos - $last;

        foreach my $event (@{ $mm->{'_midistruct'}->{$pos} }) {

            $event->[1] = $dtime;
            push @$events, $event;

            $dtime = 0;
        }
        $last = $pos;
    }
    $mm->playevents($events) || do {
        $mm->{'_errstr'} = ref($mm) . '::_playloaded(): ' . $mm->{'_errstr'};
        return 0;
    };
    $mm->dumpbuf();
    return 1;
}

################################################################################
############################## Recording #######################################
sub _readevents_OSS {

    my $mm      = shift;
    my $data    = $mm->_readblock();
    my $events  = [];

    $events = [ map { [ unpack('C8', substr($data, ($_ * 8), 8)) ]
                    } (0 .. ((length($data) / 8) - 1))
              ] if ($data);

    return $events;
}

sub readevents {

    my $mm      = shift;
    my $events  = $mm->_readevents_OSS();
    my $decoded = [];

    if (@{$events}) {

        for (0 .. $#{$events}) {

            my $event      = $events->[$_];
            my $ev_decoded = [];

            if ($event->[0] == &EV_CHN_VOICE) {

                if ($event->[2] == &MIDI_NOTEON) {

                    $ev_decoded->[0] = 'note_on';
                    $ev_decoded->[1] = $mm->{'_rec_dtime'};
                    $ev_decoded->[2] = $event->[3]; # channel
                    $ev_decoded->[3] = $event->[4]; # note
                    $ev_decoded->[4] = $event->[5]; # velocity

                    $mm->{'_rec_dtime'} = 0;

                } elsif ($event->[2] == &MIDI_NOTEOFF) {

                    $ev_decoded->[0] = 'note_off';
                    $ev_decoded->[1] = $mm->{'_rec_dtime'};
                    $ev_decoded->[2] = $event->[3]; # channel
                    $ev_decoded->[3] = $event->[4]; # note
                    $ev_decoded->[4] = $event->[5]; # velocity

                    $mm->{'_rec_dtime'} = 0;

                } elsif ($event->[2] == &MIDI_KEY_PRESSURE) {

                    $ev_decoded->[0] = 'key_after_touch';
                    $ev_decoded->[1] = $mm->{'_rec_dtime'};
                    $ev_decoded->[2] = $event->[3]; # channel
                    $ev_decoded->[3] = $event->[4]; # note
                    $ev_decoded->[4] = $event->[5]; # velocity

                    $mm->{'_rec_dtime'} = 0;
                }

            } elsif ($event->[0] == &EV_CHN_COMMON) {

                if ($event->[2] == &MIDI_CHN_PRESSURE) {

                    $ev_decoded->[0] = 'channel_after_touch';
                    $ev_decoded->[1] = $mm->{'_rec_dtime'};
                    $ev_decoded->[2] = $event->[3]; # channel
                    $ev_decoded->[3] = $event->[4]; # velocity

                    $mm->{'_rec_dtime'} = 0;

                } elsif ($event->[2] == &MIDI_PGM_CHANGE) {

                    $ev_decoded->[0] = 'patch_change';
                    $ev_decoded->[1] = $mm->{'_rec_dtime'};
                    $ev_decoded->[2] = $event->[3]; # channel
                    $ev_decoded->[3] = $event->[4]; # program

                    $mm->{'_rec_dtime'} = 0;

                } elsif ($event->[2] == &MIDI_CTL_CHANGE) { # control change

                    $ev_decoded->[0] = 'control_change';
                    $ev_decoded->[1] = $mm->{'_rec_dtime'};
                    $ev_decoded->[2] = $event->[3]; # channel
                    $ev_decoded->[3] = $event->[4]; # controller
                    $ev_decoded->[4] = $event->[5]; # value

                    $mm->{'_rec_dtime'} = 0;

                } elsif ($event->[2] == &MIDI_PITCH_BEND) {

                    $ev_decoded->[0] = 'pitch_wheel_change';
                    $ev_decoded->[1] = $mm->{'_rec_dtime'};
                    $ev_decoded->[2] = $event->[3];                # channel
                    $ev_decoded->[3] = ($event->[7] * 256) - 8192; # value

                }

#### fix this #####

            } elsif ($event->[0] == &EV_SYSEX) {

                $ev_decoded->[0] = 'sysex_f0'; # ???
                $ev_decoded->[1] = $mm->{'_rec_dtime'};
                $ev_decoded->[2] = $event->[2]; # data - six bytes at a time! (stupid)

	        for (;;) {
	            my $events_oss = $mm->_readevent_OSS();
	            
	        }

                $mm->{'_rec_dtime'} = 0;

            } elsif ($event->[0] == &EV_TIMING) {

                if      ($event->[1] == &TMR_START)    {
                } elsif ($event->[1] == &TMR_STOP)     {
                } elsif ($event->[1] == &TMR_CONTINUE) {
                } elsif ($event->[1] == &TMR_WAIT_ABS) {
                } elsif ($event->[1] == &TMR_WAIT_REL) {
                } elsif ($event->[1] == &TMR_ECHO)     {
                } elsif ($event->[1] == &TMR_TEMPO)    {

#### possible need for fix here ###
#
                    $ev_decoded->[0] = 'set_tempo';
                    $ev_decoded->[1] = $mm->{'_rec_dtime'};
                    $ev_decoded->[2] = $event->[4]; ## not sure if this is correct..

                    $mm->{'_rec_dtime'} = 0;

                } elsif ($event->[1] == &TMR_SPP) { # not sure how this differs
                                                    #   from 0xf2...

                    $ev_decoded->[0] = 'song_position';
                    $ev_decoded->[1] = $mm->{'_rec_dtime'};

                    $mm->{'_rec_dtime'} = 0;

                } elsif ($event->[1] == &TMR_TIMESIG) {

                    $ev_decoded->[0] = 'time_signature';
                    $ev_decoded->[1] = $mm->{'_rec_dtime'};

                    my $timesig = $event->[4];

                    $ev_decoded->[2] = ($timesig >> 0x18) & 0xff;
                    $ev_decoded->[3] = ($timesig >> 0x10) & 0xff;
                    $ev_decoded->[4] = ($timesig >> 0x08) & 0xff;
                    $ev_decoded->[5] =  $timesig          & 0xff;

                    $mm->{'_rec_dtime'} = 0;
                }

            } elsif ($event->[0] == &EV_SEQ_LOCAL) {
            } elsif ($event->[0] == &EV_SYSTEM)    {

                if ($event->[2] == 0xf0) { # sysex
                } elsif ($event->[2] == 0xf1) { # MTC Qframe

                } elsif ($event->[2] == 0xf2) {

                    $ev_decoded->[0] = 'song_position';
                    $ev_decoded->[1] = $mm->{'_rec_dtime'};

                    $mm->{'_rec_dtime'} = 0;

                } elsif ($event->[2] == 0xf3) { # song select

                    $ev_decoded->[0] = 'song_select';
                    $ev_decoded->[1] = $mm->{'_rec_dtime'};
                    $ev_decoded->[2] = $event->[3]; # song number

                    $mm->{'_rec_dtime'} = 0;

                } elsif ($event->[2] == 0xf4) {
                } elsif ($event->[2] == 0xf5) {
                } elsif ($event->[2] == 0xf6) { # tune request

                    $ev_decoded->[0] = 'tune_request';
                    $ev_decoded->[1] = $mm->{'_rec_dtime'};

                    $mm->{'_rec_dtime'} = 0;

                } elsif ($event->[2] == 0xf7) { # end-of-sysex
                } elsif ($event->[2] == 0xf8) { # timing clock

	           # print "Timing clock\n";

                    $mm->{'_rec_dtime'} += $mm->{'_ppqn_per_clock'};

                } elsif ($event->[2] == 0xf9) {
                } elsif ($event->[2] == 0xfa) { # start
                } elsif ($event->[2] == 0xfb) { # continue
                } elsif ($event->[2] == 0xfc) { # stop
                } elsif ($event->[2] == 0xfd) {
                } elsif ($event->[2] == 0xfe) { # active sensing

	           # print "Active sensing\n";

                } elsif ($event->[2] == 0xff) { # reset
                }
            }
            push(@{$decoded}, $ev_decoded) if (@{$ev_decoded});
        }
    }
    return $decoded;
}

1;

__END__

=head1 NAME

MIDI::Music - Perl interface to /dev/music.

=head1 SYNOPSIS

    use MIDI::Music;

    my $mm = new MIDI::Music;

    # Play a MIDI file through the
    # first available device
    $mm->playmidifile('foo.mid') || die $mm->errstr;

or:

    use MIDI::Music;
    use Fcntl;
    my $mm = new MIDI::Music;

    # Initialize device for writing
    $mm->init('mode'     => O_WRONLY,
              'timebase' => 96,
              'tempo'    => 60,
              'timesig'  => [2, 2, 24, 8],
              ) || die $mm->errstr;

    # Play a C-major chord
    $mm->playevents([['patch_change', 0, 0, 49],
                     ['note_on', 0, 0, 60, 64],
                     ['note_on', 0, 0, 64, 64],
                     ['note_on', 0, 0, 67, 64],
                     ['note_on', 0, 0, 72, 64],
                     ['note_off', 144, 0, 60, 64],
                     ['note_off', 0, 0, 64, 64],
                     ['note_off', 0, 0, 67, 64],
                     ['note_off', 0, 0, 72, 64],
                    ]) || die $mm->errstr;
    $mm->dumpbuf;
    $mm->close;

or:

    use MIDI::Music;
    use MIDI;
    use Fcntl;

    my $opus  = MIDI::Opus->new();
    my $track = MIDI::Track->new();

    my $mm = new MIDI::Music('tempo'    => 120, # These parameters
                             'realtime' => 1,   # can be passed to
                             );                 # the constructor

    # Record some MIDI data from
    # an external device..
    $mm->init('mode' => O_RDONLY) || die $mm->errstr;

    for (;;) {

        << break condition here... >>

        my $event_struct = $mm->readevents;

        push(@{ $track->events_r }, @$event_struct)
            if (defined $event_struct);
    }

    $mm->close;

    $opus->tracks($track);
    $opus->write_to_file('bar.mid');

=head1 DESCRIPTION

MIDI::Music is a high-level interface to /dev/music, and is designed to
function on any *NIX system supported by Open Sound System v.3.8 or higher.

Playback through internal and external MIDI devices is supported, as is
the "recording" of events from an external device. Additional goals in
designing MIDI::Music were:

=over 4

=item 1

to provide an API with as few methods necessary to satisfy 99% of MIDI
programmers' purposes.

=item 2

to provide easy integration with Sean M. Burke's MIDI-Perl suite by means 
of a common event specification.

=back

There are, at present, essentially three things you can do with MIDI::Music:

=over 4

=item 1 

Play a MIDI file.

=item 2 

Play a series of events defined in an event structure, which is a LoL
as described in the L<MIDI::Event> documentation.

=item 3

Read a series events from an external device. These events are returned as
the same type of event structure as in [2].

=back 

It is important to remember that MIDI::Music is not a "realtime" synthesizer
interface in the strictest, unbuffered sense of the term. :) Rather, a series 
of events are written to an internal buffer (in playback-related methods, 
anyway) which is flushed periodically. The "playevents" function may have, 
for example, long since returned, while the user continues to hear notes 
being played.

FWIW: The L<readevents()|"item_readevents"> method is fast to be sure, but the time involved in 
the interpretation of data from the external synthesizer should be taken
into account. This time will of course depend on how many messages are being 
processed at any given read, the speed of the machine doing the processing, 
etc.

=head1 INITIALIZATION PARAMETERS

These parameters are common to L<the constructor|"item_new"> and the L<init()|"item_init"> method.
A parameter supplied to the init() method will override the same parameter
supplied to new(). 

=head2 General

=over 4

=item 'device' => $device

where $device is the number identifying which synth device to use. The default 
value is 0 (first available device).

=back

=head2 Recording

=over 4

=item 'readbuf' => $buffer_size

where $buffer_size is the length in bytes of each read operation (if you 
are using MIDI::Music for recording), each event being read (at the underlying
level) as an 8-byte string. The default "read buffer" size is 4096 (512 events 
per read, maximum).

=cut
=item 'actsense' => $bool

Enable active sensing, if the device is to be opened for reading. Default is 1 
(true).
=pod

=item 'realtime' => $bool

Enable incoming realtime messages, if the device is to be opened for reading. 
Setting this to 1 allows the delta-times of recorded events to be calculated 
from "timing-clock" messages sent from the external device (otherwise, the
delta-time of any recorded event will be 0). Default is 0 (false).

=cut
=item 'timing' => $bool

Enable incoming timing messages, if the device is to be opened for reading. The
'realtime' option must be set to true for this to be useful. Default is 1 (true).
=pod

=back

=head2 Patch caching

Specifying these parameters may speed playback on hardware synths (if, for example, a 
large number of pattern-change messages are being processed over a short period of time (?)), 
though they have not been tested.

=over 4

=item 'gminstr' => \@instruments

where \@instruments is a reference to an array containing the program numbers
of instruments to cache on initialization. For example, passing 'gminstr'
the value:

    [ 0, 19, 56 ]

will result in the piano, the church organ, and the trumpet voices
(respectively) being cached.

=item 'gmdrum' => \@drum_kits

where \@drum_kits is a reference to an array containing the numbers identifying
drum kits to cache on initialization.

=back

=head2 Timing

=over 4

=item 'tempo' => $bpm

Initial tempo, where $bpm is number of beats per minute. Default is 120.

=item 'timebase' => $timebase

Initial number of ticks per quarter-note. Default is 96.

=item 'timesig' => \@timesig

Initial time signature, where \@timesig is a reference to an array containing
the time signature values:

    [ nn, dd, cc, bb ]

As described in the L<MIDI::Filespec> documentation.

=back

=head1 CONSTRUCTOR

=over 4

=item new(%init_parameters)

Return a new MIDI::Music. See section L<"INITIALIZATION PARAMETERS"> for a
description of options.

=back

=head1 METHODS

=over 4

=item playmidifile($path)

Play MIDI file supplied in $path. You must have Sean M. Burke's L<MIDI-Perl>
modules installed in order to use this method.

If L<init()|"item_init"> has not already been called, initialization will be handled
automatically.  The L<dumpbuf()|"item_dumpbuf"> method is also called automatically to
clear the play-buffer at the end of the "song," so there is no need to
bother with it.

Returns true on success, false on error (the last recorded error string 
being available through the L<errstr()|"item_errstr"> method).

Note: certain L<initialization parameters|"INITIALIZATION PARAMETERS"> supplied to the constructor,
such as timebase, may be overridden should they be specified differently in
the MIDI file header.

=item init(%init_param)

Opens and initializes the device according to parameters supplied. Returns
true on success, false on failure (in which case the error can be obtained by
calling the L<errstr()|"item_errstr"> method).

In addition to the options described in the L<"INITIALIZATION PARAMETERS">
section, init() accepts the 'mode' parameter, which value is an open-flag
(O_RDWR, O_WRONLY, O_RDONLY, etc.). Default is O_RDWR.

Open-flag constants are provided by L<Fcntl.pm>.

=item close()

Close the device. This is called automatically along with the destructor, but
you may need it in order to (for example) initialize a different device (only
one device/instance at a time is supported at present).

=item playevents(\@event_structure)

Play the events contained in the supplied reference to an event structure.
You almost always should call L<dumpbuf()|"item_dumpbuf"> after this in order to flush 
any events remain in the play-buffer.

Returns true on success, false on error (the last recorded error string 
being available through the L<errstr()|"item_errstr"> method).

The device must be L<initialized|"item_init"> for writing before a call to playevents().

=item readevents()

Read some events and return them as a reference to an event structure. There
will be a maximum of ($readbuf / 8) events contained in the structure, where
$readbuf is value of the L<initialization parameters|"INITIALIZATION PARAMETERS"> of the same name (default 
is 4096). 

(In the author's experience, there are rarely more than two or three non-timing 
events per read, and usually there is only one.)

If the 'realtime' initialization parameter was set to 1, delta-times will 
be computed to reflect the number of timing clocks that have occured from the
time the device was initialized (the running version of OSS must have realtime 
support for this to work). Otherwise, all delta-times will be zero.

The readevents() method returns undef if nothing but realtime messages are 
read.

The device must be initialized for reading before a call to readevents().

=item dumpbuf()

Dump any events remaining in the play-buffer.

=item errstr()

Return last recorded error message.

=back

=head1 NOTES

=over 4

=item *

To my knowledge, the "realtime" initialization option, allowing
timing-clocks to determine the delta-times of recorded events, will work only 
with the commercial release of OSS. This is not an issue unless you are 
interested in doing realtime recording (e.g. recording events while playing 
your keyboard/sequencer as opposed to "recording" in some sort of stepwise 
fashion). The commercial version of OSS may be obtained from the 4Front 
Technologies website:

    http://www.opensound.com/

It is worth the (resonable) price, and of course has the cross-platform 
advantage over ALSA.

=item *

MIDI::Music was developed and tested on an i686 running SuSE 6.4, with OSS
version 3.9.6 installed. A mid-1990s Yamaha QY22 sequencer was used in
testing the recording-related functions.

=back

=head1 TO DO

=over 4

=item *

Add methods for obtaining synthesizer information (number, types of available 
devices).

=item *

At present, MIDI::Music supports the interface with only one open device at a 
time. Future versions will allow for simultaneous instances of initialized 
devices, if possible.

=item *

At present, system-exclusive events (produced by bulk dumps, etc.) are not 
included in the event structures returned by L<readevents()|"item_readevents">. This should be 
fixed in the next release.

=item *

Streamline the L<playmidifile()|"item_playmidifile"> code for greater memory-efficiency, if possible.

=back

=head1 AUTHOR

Seth David Johnson, seth@pdamusic.com

=head1 SEE ALSO

The Open Sound System homepage (4Front Technologies):

    http://www.opensound.com/

The OSS Programming Guide (PDF), describing in some detail the /dev/music
API on which MIDI::Music is based:

    http://www.opensound.com/pguide/oss.pdf

Sean M. Burke's L<MIDI-Perl|MIDI> extensions provide methods for dealing 
with MIDI files; you will need to have them installed if you wish to use the
L<playmidifile()|"item_playmidifile"> method. The documentation for L<MIDI::Events> provides a 
description of the "event structures" common to MIDI::Music and MIDI-Perl.

Alex McLean's experimental L<MIDI::Realtime> is an earlier attempt to provide
a synthesizer interface to Perl. MIDI::Realtime takes an entirely different 
approach both in terms of interface and in terms of implementation, and may be 
better suited than MIDI::Music to specific purposes.

The aforementioned extensions can be obtained from the CPAN:

    http://www.cpan.org/

perl(1).

=cut
