package MIDI::RtMidi::ScorePlayer;
our $AUTHORITY = 'cpan:GENE';

# ABSTRACT: Play a MIDI score in real-time

our $VERSION = '0.0202';

use strict;
use warnings;

use Data::Dumper::Compact qw(ddc);
use File::Basename qw(fileparse);
use MIDI::RtMidi::FFI::Device ();
use MIDI::Util qw(dura_size get_microseconds score2events set_chan_patch ticks);
use Path::Tiny qw(path);
use Time::HiRes qw(time usleep);


sub new {
    my ($class, %opts) = @_;

    die 'A MIDI score object is required' unless $opts{score};
    die 'A list of parts is required'
        unless $opts{parts} && ref $opts{parts} eq 'ARRAY';

    $opts{common}   ||= {};
    $opts{repeats}  ||= 1;
    $opts{sleep}    //= 1;
    $opts{loop}     ||= 1;
    $opts{infinite} //= 1;
    $opts{verbose}  //= 0;
    $opts{dump}     //= 0;
    $opts{deposit}  ||= '';

    if ($opts{deposit}) {
        ($opts{prefix}, $opts{path}) = fileparse($opts{deposit});
        die "Invalid path: $opts{path}\n" unless -d $opts{path};
    }

    $opts{device} = RtMidiOut->new;

    $opts{port} //= qr/wavetable|loopmidi|timidity|fluid/i;

    # For MacOS, DLSMusicDevice should receive input from this virtual port:
    $opts{device}->open_virtual_port('dummy') if $^O eq 'darwin';

    $opts{device}->open_port_by_name($opts{port});

    bless \%opts, $class;
}


sub play {
    my ($self) = @_;
    if ($self->{infinite}) {
        while (1) { $self->_play }
    }
    else {
        $self->_play for 1 .. $self->{loop};
    }
}

sub _play {
    my ($self) = @_;
    for my $n (1 .. $self->{repeats}) {
        for my $p (@{ $self->{parts} }) {
            if (ref($p) eq 'ARRAY') {
                $self->_sync_parts($p);
            }
            else {
                $self->_play_part($p, $n);
            }
        }
    }
    print ddc($self->{score}) if $self->{dump};
    my $micros = get_microseconds($self->{score});
    my $events = score2events($self->{score});
    for my $event (@$events) {
        next if $event->[0] =~ /set_tempo|time_signature/;
        if ($event->[0] eq 'text_event') {
            printf "%s\n", $event->[-1] if $self->{verbose};
            next;
        }
        my $useconds = $micros * $event->[1];
        usleep($useconds) if $useconds > 0 && $useconds < 1_000_000;
        $self->{device}->send_event($event->[0] => @{ $event }[ 2 .. $#$event ]);
    }
    if ($self->{deposit}) {
        my $filename = path($self->{path}, $self->{prefix} . time() . '.midi');
        $self->{score}->write_score("$filename");
    }
    sleep($self->{sleep});
    $self->_reset_score;
}

# This manipulates internals of MIDI::Score things and doing this isn't a good idea
sub _reset_score {
    my ($self) = @_;
    # sorry
    $self->{score}{Score} = [
        grep { $_->[0] !~ /^note/ && $_->[0] !~ /^patch/ }
        @{ $self->{score}{Score} }
    ];
    ${ $self->{score}{Time} } = 0;
    $self->{common}{seen} = {}
        if exists $self->{common}{seen};
}

sub _tick {
    my ($self, %args) = @_;
    return sub {} unless $args{'tick.durations'};
    my $sum = 0;
    for my $duration (@{ $args{'tick.durations'} }) {
        $sum += dura_size($duration);
    }
    my $ticks = ticks($self->{score});
    my $tick = sub {
        set_chan_patch($self->{score}, 9, 0);
        my $vol = $self->{score}->Volume;
        $self->{score}->Volume(0);
        $self->{score}->n('d' . $ticks, 33) for 1 .. $sum;
        $self->{score}->Volume($vol);
    };
    return $tick;
}

sub _play_part {
    my ($self, $p, $n) = @_;
    $n //= 1;
    my $part = $p->(%{ $self->{common} }, _part => $n);
    my $tick = $self->_tick(%{ $self->{common} });
    $self->{score}->synch($tick, $part);
}

# Build the code-ref MIDI of all parts to be played
sub _sync_parts {
    my ($self, $p) = @_;
    my @parts;
    my $n = 1;
    push @parts, $_->(%{ $self->{common} }, _part => $n++)
        for @$p;
    $self->{score}->synch(@parts); # Play the parts simultaneously
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MIDI::RtMidi::ScorePlayer - Play a MIDI score in real-time

=head1 VERSION

version 0.0202

=head1 SYNOPSIS

  use MIDI::RtMidi::ScorePlayer ();
  use MIDI::Util qw(setup_score);

  my $score = setup_score();

  # arguments given to the part functions
  my %common = (score => $score, seen => {}, etc => '...',);

  # 2 measure parts
  sub treble {
      my (%args) = @_;
      ...; # Setup things
      my $treble = sub {
          for my $i (1 .. 8) {
              if ($i % 2) {
                  $args{score}->n('qn', '...');
              }
              else {
                  $args{score}->r('qn', '...');
              }
          }
      };
      return $treble;
  }
  sub bass {
      my (%args) = @_;
      # to play alone, this is needed:
      $common{'tick.durations'} = [ ('hn') x 4 ];
      my $bass = sub {
      ...; # As above but different!
      };
      return $bass;
  }

  MIDI::RtMidi::ScorePlayer->new(
      score    => $score, # required MIDI score object
      parts    => [ \&bass, [ \&treble, \&bass ], \&bass ], # required part functions
      common   => \%common, # arguments given to the part functions
      repeats  => 4, # number of repeated synched parts (default: 1)
      sleep    => 2, # number of seconds to sleep between loops (default: 1)
      loop     => 4, # loop limit if finite (default: 1)
      infinite => 0, # loop infinitely (default: 1)
      deposit  => 'path/prefix-', # optionally make a file after each loop
      verbose  => 0, # print out text events (default: 0)
      dump     => 0, # dump the score before each play (default: 0)
  )->play;

=head1 DESCRIPTION

C<MIDI::RtMidi::ScorePlayer> plays a MIDI score in real-time.

In order to use this module, create subroutines for simultaneous MIDI
B<parts> that take a B<common> hash of named arguments. These parts
each return an anonymous subroutine that tells MIDI-perl to build up a
B<score>, by adding notes (C<n()>) and rests (C<r()>), etc. These
musical operations are described in the L<MIDI> modules, like
L<MIDI::Simple>.

Besides being handed the B<common> arguments, each B<part> function
gets a handy, increasing B<_part> number, starting at one, which can
be used in the part functions. These parts are synch'd together, given
the B<new> parameters that are described in the example above.

If you wish to set the patch or channel for a part, do so B<inside>
the scope of the coderef that is returned by the part.

If you wish to play a I<single> part, include it in the B<parts> list
by itself (i.e. not with any other tracks), AND tell
C<MIDI::RtMidi::ScorePlayer> how long (in musical durations) the part
is, by adding C<tick.durations> to the B<common> set of part arguments.
To play multiple parts simultaneously, add them to an array reference
in the B<parts> list.

=head2 Hints

B<Linux>:
If your distro does not install a service, you can use FluidSynth:
C<fluidsynth -a alsa -m alsa_seq some-soundfont.sf2>
Or try Timidity in daemon mode: C<timidity -iAD>, but YMMV, TBH.

B<MacOS>:
You can use FluidSynth like this:
C<fluidsynth -a coreaudio -m coremidi some-soundfont.sf2>
Also, you can use Timidity, as above. A digital audio workstation
(DAW) like Logic, with a software synth track selected, should work.
And if you wish, you can get General MIDI with a "DLSMusicDevice"
track open, and a soundfont in C<~/Library/Audio/Sounds/Banks/>. Make
sure the soundfont is selected for the track.

B<Windows>:
This should I<just work> out of the box.

=head1 METHODS

=head2 new

Instantiate a new C<MIDI::RtMidi::ScorePlayer> object.

=head2 play

Play a given MIDI score in real-time.

=head1 SEE ALSO

Examples are the F<eg/*> files in this distribution.

Also check out the F<t/01-methods.t> file for basic usage.

L<MIDI::RtMidi::FFI::Device>

L<MIDI::Util>

L<Time::HiRes>

=head1 AUTHOR

Gene Boggs <gene.boggs@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2024 by Gene Boggs.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
