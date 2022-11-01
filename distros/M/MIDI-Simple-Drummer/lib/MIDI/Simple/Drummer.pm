package MIDI::Simple::Drummer;
our $AUTHORITY = 'cpan:GENE';

# ABSTRACT: An algorithmic MIDI drummer

our $VERSION = '0.0811';

use strict;
use warnings;

use MIDI::Simple ();
use Music::Duration ();

BEGIN {
    # Define a division structure to use for durations.
    use constant DIVISION => {
        w => { number =>  1, ordinal =>  '1st', name => 'whole' },
        h => { number =>  2, ordinal =>  '2nd', name => 'half' },
        q => { number =>  4, ordinal =>  '4th', name => 'quarter' },
        e => { number =>  8, ordinal =>  '8th', name => 'eighth' },
        s => { number => 16, ordinal => '16th', name => 'sixteenth' },
        x => { number => 32, ordinal => '32nd', name => 'thirtysecond' },
        y => { number => 64, ordinal => '64th', name => 'sixtyfourth' },
        z => { number => 128, ordinal => '128th', name => 'onetwentyeighth' },
    };

    # Add constants for each known duration.
    for my $n (keys %MIDI::Simple::Length) {
        # Get the duration part of the note name.
        my $name = $n =~ /([whqesxyz])n$/ ? $1 : '';

        if ($name) {
            # Create a meaningful prefix for the named constant.
            my $prefix = '';
            $prefix .= 'triplet'       if $n =~ /t\w/;
            $prefix .= 'double_dotted' if $n =~ /^dd/;
            $prefix .= 'dotted'        if $n =~ /^d[^d]/;
            $prefix .= '_' if $prefix;

            # Add name-based duration.
            my $key = uc($prefix . DIVISION->{$name}{name});
            constant->import($key => $n); # LeoNerd++ clue
            # Add a _prefix for numeric duration constants.
            $prefix .= '_' unless $prefix;
            # Add number-based duration.
            $key = uc($prefix . DIVISION->{$name}{ordinal});
            constant->import($key => $n);
        }
        else {
            warn "ERROR: Unknown note value '$n' - Skipping."
        }
    }
}

sub new { # Is there a drummer in the house?
    my $class = shift;
    # Our drummer is a set of attributes.
    my $self  = {
        # MIDI
        -channel    => 9,
        -volume     => 100,
        -pan        => 64,
        -pan_width  => 0,
        -patch      => 0,
        -reverb     => 20,
        -chorus     => 0,
        # Rhythm
        -accent     => 30,
        -bpm        => 120,
        -phrases    => 4,
        -bars       => 4,
        -beats      => 4,
        -divisions  => 4,
        -signature  => '',
        # The Goods™
        -score      => undef,
        -file       => 'Drummer.mid',
        -kit        => undef,
        -patterns   => undef,
        @_  # Capture any override or extra arguments.
    };

    # Make our drummer a proper object.
    bless $self, $class;

    # Perform any pre-flight default setting.
    $self->_setup;

    return $self;
}

sub _setup { # Where's my roadies, Man?
    my $self = shift;

    # Give unto us, a score with which to fondle.
    $self->{-score} ||= MIDI::Simple->new_score;
    $self->{-score}->noop('c'.$self->{-channel}, 'V'.$self->{-volume});
    $self->{-score}->set_tempo(int(60_000_000 / $self->{-bpm}));

    # Give unto us a drum, so that we might bang upon it all day, instead of working.
    $self->{-kit} ||= $self->_default_kit;
    $self->{-patterns} ||= $self->_default_patterns;

    # Set the groove dimensions if a time signature is given.
    if ($self->{-signature}) {
        $self->signature($self->{-signature});
    }
    else {
        # If no signature is provided, assume 4/4.
        $self->{-beats}     ||= 4;
        $self->{-divisions} ||= 4;
        $self->{-signature} = "$self->{-beats}/$self->{-divisions}";
    }

    $self->{-score}->time_signature(
        $self->{-beats},
        sqrt( $self->{-divisions} ),
        ( $self->{-divisions} == 8 ? 24 : 18 ),
        8
    );

    # Reset the backbeat if the signature is a 3 multiple.
    my $x = $self->{-beats} / 3;
    if ($x !~ /\./) {
        $self->backbeat('Acoustic Bass Drum', 'Acoustic Snare', 'Acoustic Bass Drum');
    }

    # Set the method name for the division metric. Ex: QUARTER for 4.
    for my $note (keys %{+DIVISION}) {
        if (DIVISION->{$note}{number} == $self->{-divisions}) {
            $self->div_name(uc DIVISION->{$note}{name});
        }
    }

    # Set effects.
    $self->reverb;
    $self->chorus;
    $self->pan_width;

    return $self;
}

# Convenience functions:
sub _durations { return \%MIDI::Simple::Length }
sub _n2p { return \%MIDI::notenum2percussion }
sub _p2n { return \%MIDI::percussion2notenum }

# Accessors:
sub channel { # The general MIDI drumkit is often channel 9.
    my $self = shift;
    $self->{-channel} = shift if @_;
    return $self->{-channel};
}
sub patch { # Drum kit
    my $self = shift;
    $self->{-patch} = shift if @_;
    $self->{-score}->patch_change($self->{-channel}, $self->{-patch});
    return $self->{-patch};
}
sub reverb { # [0 .. 127]
    my $self = shift;
    $self->{-reverb} = shift if @_;
    $self->{-score}->control_change($self->{-channel}, 91, $self->{-reverb});
    return $self->{-reverb};
}
sub chorus { # [0 .. 127]
    my $self = shift;
    $self->{-chorus} = shift if @_;
    $self->{-score}->control_change($self->{-channel}, 93, $self->{-chorus});
    return $self->{-chorus};
}
sub pan { # [0 Left-Middle-Right 127]
    my $self = shift;
    $self->{-pan} = shift if @_;
    $self->{-score}->control_change($self->{-channel}, 10, $self->{-pan});
    return $self->{-pan};
}
sub pan_width { # [0 .. 64] from center
    my $self = shift;
    $self->{-pan_width} = shift if @_;
    return $self->{-pan_width};
}
sub bpm { # Beats per minute
    my $self = shift;
    $self->{-bpm} = shift if @_;
    return $self->{-bpm};
}
sub volume { # TURN IT DOWN IN THERE!
    my $self = shift;
    $self->{-volume} = shift if @_;
    return $self->{-volume};
}
sub phrases { # o/` How many more times? Treat me the way you wanna do?
    my $self = shift;
    $self->{-phrases} = shift if @_;
    return $self->{-phrases};
}
sub bars { # Number of measures
    my $self = shift;
    $self->{-bars} = shift if @_;
    return $self->{-bars};
}
sub beats { # Beats per measure
    my $self = shift;
    $self->{-beats} = shift if @_;
    return $self->{-beats};
}
sub divisions { # The division of the measure that is "the pulse."
    my $self = shift;
    $self->{-divisions} = shift if @_;
    return $self->{-divisions};
}
sub signature { # The ratio of discipline
    my $self = shift;
    if (@_) {
        # Set the argument to the signature string.
        $self->{-signature} = shift;
        # Set the rhythm metrics.
        ($self->{-beats}, $self->{-divisions}) = split /\//, $self->{-signature}, 2;
    }
    return $self->{-signature};
}
sub div_name { # The name of the denominator of the time signature.
    my $self = shift;
    $self->{-div_name} = shift if @_;
    return $self->{-div_name};
}
sub file { # The name of the MIDI file output
    my $self = shift;
    $self->{-file} = shift if @_;
    return $self->{-file};
}

sub score { # The MIDI::Simple score with no-op-ability
    my $self = shift;

    # If we are presented with a M::S object, assign it as the score.
    $self->{-score} = shift if ref $_[0] eq 'MIDI::Simple';

    # Set any remaining arguments as score no-ops.
    $self->{-score}->noop($_) for @_;

    return $self->{-score};
}

sub accent_note { # Accent a single note.
    my $self = shift;
    my $note = shift;
    $self->score('V' . $self->accent); # Accent!
    $self->note($note, $self->strike);
    $self->score('V' . $self->volume); # Reset the note volume.
}

# API: Subclass and redefine to emit nuance.
sub accent { # Pump up the Volume!
    my $self = shift;
    $self->{-accent} = shift if @_;

    # Add a bit of volume.
    my $accent = $self->{-accent} + $self->volume;
    # But don't try to go above the top.
    $accent = $MIDI::Simple::Volume{fff}
        if $accent > $MIDI::Simple::Volume{fff};

    # Hand back the new volume.
    return $accent;
}
# API: Subclass and redefine to emit nuance.
sub duck { # Drop the volume.
    my $self = shift;
    $self->{-accent} = shift if @_;

    # Subtract a bit of volume.
    my $duck = $self->volume - $self->{-accent};
    # But don't try to go below the bottom.
    $duck = $MIDI::Simple::Volume{ppp}
        if $duck > $MIDI::Simple::Volume{ppp};

    # Hand back the new volume.
    return $duck;
}

sub kit { # Arrayrefs of patches
    my $self = shift;
    return $self->_type('-kit', @_);
}
sub patterns { # Coderefs of patterns
    my $self = shift;
    return $self->_type('-patterns', @_);
}

sub _type { # Both kit and pattern access
    my $self = shift;
    my $type = shift || return;

    if (!@_) { # If there are no arguments, return all known types.
        return $self->{$type};
    }
    elsif (@_ == 1) { # Return a single named type with either name=>value or just value.
        my $i = shift;
        return wantarray
            ? ($i => $self->{$type}{$i})
            : $self->{$type}{$i};
    }
    elsif (@_ > 1 && !(@_ % 2)) { # Add new types if given an even list.
        my %args = @_;
        my @t = ();

        while (my ($i, $v) = each %args) {
            $self->{$type}{$i} = $v;
            push @t, $i;
        }
        # Return the named types.
        return wantarray
            ? (map { $_ => $self->{$type}{$_} } @t) # Hash of named types.
            : @t > 1                                # More than one?
                ? [map { $self->{$type}{$_} } @t]   # Arrayref of types.
                : $self->{$type}{$t[0]};            # Else single type.
    }
    else { # Unlikely to ever be triggered.
        warn 'WARNING: Mystery arguments. Giving up.';
    }
}

sub name_of { # Return instrument name(s) given kit keys.
    my $self = shift;
    my $key  = shift || return;
    return wantarray
        ? @{$self->kit($key)} # List of names
        : join ',', @{$self->kit($key)}; # CSV of names
}

sub _set_get { # Internal kit access
    my $self = shift;
    my $key  = shift || return;

    # Set the kit event.
    $self->kit($key => [@_]) if @_;

    return $self->option_strike(@{$self->kit($key)});
}

# API: Add other keys to your kit & patterns, in a subclass.
sub backbeat { return shift->_set_get('backbeat', @_) }
sub snare    { return shift->_set_get('snare', @_) }
sub kick     { return shift->_set_get('kick', @_) }
sub tick     { return shift->_set_get('tick', @_) }
sub hhat     { return shift->_set_get('hhat', @_) }
sub crash    { return shift->_set_get('crash', @_) }
sub ride     { return shift->_set_get('ride', @_) }
sub tom      { return shift->_set_get('tom', @_) }

sub strike { # Return note values.
    my $self = shift;

    # Set the patches, default snare.
    my @patches = @_ ? @_ : @{$self->kit('snare')};

    # Build MIDI::Simple note names from the patch numbers.
    my @notes = map { 'n' . $MIDI::percussion2notenum{$_} } @patches;

    return wantarray ? @notes : join(',', @notes);
}
# API: Redefine this method to use a different decision than rand().
sub option_strike { # When in doubt, crash.
    my $self = shift;

    # Set the patches, default crashes.
    my @patches = @_ ? @_ : @{$self->kit('crash')};

    # Choose a random patch!
    return $self->strike($patches[int(rand @patches)]);
}

sub rotate { # Rotate through a list of patches.
    my $self    = shift;
    my $beat    = shift || 1; # Assume that we are on the first beat if none is given.
    my $patches = shift || $self->kit('backbeat'); # Default backbeat.

    # Strike a note from the patches, based on the beat.
    return $self->strike($patches->[$beat % @$patches]);
}
sub backbeat_rhythm { # AC/DC forever
    # Rotate the backbeat with tick & post-fill strike.
    my $self = shift;

    # Set the default parameters with an argument override.
    my %args = (
        -beat => 1,
        -fill => 0,
        -backbeat => scalar $self->kit('backbeat'),
        -tick => scalar $self->kit('tick'),
        -patches => scalar $self->kit('crash'),
        @_  # Capture any override or extra arguments.
    );

    # Strike a cymbal or use the provided patches.
    my $c = $args{-beat} == 1 && $args{-fill}
        ? $self->option_strike(@{$args{-patches}})
        : $self->strike(@{$args{-tick}});

    # Rotate the backbeat.
    my $n = $self->rotate($args{-beat}, $args{-backbeat});

    # Return the cymbal and backbeat note.
    return wantarray ? ($n, $c) : join(',', $n, $c);
}

# Readable, MIDI score pass-throughs.
sub note {
    my $self = shift;
#use Data::Dumper;warn Data::Dumper->new([@_])->Indent(1)->Terse(1)->Sortkeys(1)->Dump;
    return $self->{-score}->n(@_)
}
sub rest { return shift->{-score}->r(@_) }

sub count_in { # And-a one, and-a two...
    my $self = shift;
    my $bars = shift || 1; # Assume that we are on the first bar if none is given.
    my $div  = $self->div_name;

    # Define the note to strike with the given patch. Default 'tick' patch.
    my $strike = @_ ? $self->strike(@_) : $self->tick;

    # Play the number of bars with a single strike.
    for my $i (1 .. $self->beats * $bars) {
        # Accent if we are on the first beat.
        $self->score('V'.$self->accent) if $i % $self->beats == 1;

        # Add a note to the score.
        $self->note($self->$div, $strike);

        # Reset the note volume if we just played the first beat.
        $self->score('V'.$self->volume) if $i % $self->beats == 1;
    }

    # Hand back the note we just used.
    return $strike;
}
sub metronome { # Keep time with a single patch. Default: Pedal Hi-Hat
    my $self = shift;
    # A metronome is just a count-in over the number of phrases
    return $self->count_in($self->phrases, shift || 'Pedal Hi-Hat');
}

sub beat { # Pattern selector method
    my $self = shift;
    # Receive or default arguments.
    my %args = (
        -name => 0, # Provide a pattern name
        -fill => 0, # Provide a fill pattern name
        -last => 0, # Is this the last beat?
        -type => '', # Is this a fill if not named in -fill?
        -time => $self->QUARTER, # Default duration is a quarter note.
        @_
    );

    # Bail out unless we have a proper repertoire.
    return undef unless ref($self->patterns) eq 'HASH';

    # Get the names of the known patterns.
    my @k = keys %{$self->patterns};
    # Bail out if we know nothing.
    return undef unless @k;

    # Do we want a certain type that isn't already in the given name?
    my $n = $args{-name} && $args{-type} && $args{-name} !~ /^.+\s+$args{-type}$/
          ? "$args{-name} $args{-type}" : $args{-name};

    if (@k == 1) { # Return the pattern if there is only one.
        $n = $k[0];
    }
    else { # Otherwise choose a different pattern.
        while ($n eq 0 || $n eq $args{-last}) {
            # TODO API: Allow custom decision method.
            $n = $k[int(rand @k)];
            if ($args{-type}) {
                (my $t = $n) =~ s/^.+\s+($args{-type})$/$1/;
                # Skip if this is not a type for which we are looking.
                $n = 0 unless $t eq $args{-type};
            }
        }
    }

    # Beat it - i.e. add the pattern to the score.
    $self->{-patterns}{$n}->($self, %args);
    # Return the beat note.
    return $n;
}
sub fill {
    my $self = shift;
    # Add the beat pattern to the score.
    return $self->beat(@_, -type => 'fill');
}

sub sync_tracks {
    my $self = shift;
    $self->{-score}->synch(@_);
}

sub write { # You gotta get it out there, you know. Make some buzz, Man.
    my $self = shift;

    # Set the file if provided or use the default.
    my $file = shift || $self->{-file};

    # Write the score to the file!
    $self->{-score}->write_score($file);

    # Return the filename if it was created or zero if not.
    # XXX Check file-size not existance.
    return -e $file ? $file : 0;
}

# API: Redefine these methods in a subclass.
sub _default_kit {
    my $self = shift;
    # Hand back a set of instruments as lists of GM named patches.
    return {
      backbeat => ['Acoustic Snare', 'Acoustic Bass Drum'],
      snare => ['Acoustic Snare'],     # 38
      kick  => ['Acoustic Bass Drum'], # 35
      tick  => ['Closed Hi-Hat'],
      hhat  => ['Closed Hi-Hat',  # 42
                'Open Hi-Hat',    # 46
                'Pedal Hi-Hat',   # 44
      ],
      crash => ['Chinese Cymbal', # 52
                'Crash Cymbal 1', # 49
                'Crash Cymbal 2', # 57
                'Splash Cymbal',  # 55
      ],
      ride  => ['Ride Bell',      # 53
                'Ride Cymbal 1',  # 51
                'Ride Cymbal 2',  # 59
      ],
      tom   => ['High Tom',       # 50
                'Hi-Mid Tom',     # 48
                'Low-Mid Tom',    # 47
                'Low Tom',        # 45
                'High Floor Tom', # 43
                'Low Floor Tom',  # 41
      ],
  };
}
# There are no known patterns. We are a wannabe at this point.
sub _default_patterns {
    my $self = shift;
    return {};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MIDI::Simple::Drummer - An algorithmic MIDI drummer

=head1 VERSION

version 0.0811

=head1 SYNOPSIS

  use MIDI::Simple::Drummer;

  # A glorified metronome:
  my $d = MIDI::Simple::Drummer->new(-bpm => 100);
  $d->count_in;
  for(1 .. $d->phrases * $d->bars) {
    $d->note($d->EIGHTH, $d->backbeat_rhythm(-beat => $_));
    $d->note($d->EIGHTH, $d->tick);
  }

  # Shuffle:
  $d = MIDI::Simple::Drummer->new(-bpm => 100);
  $d->count_in;
  for(1 .. $d->phrases * $d->bars) {
    $d->note($d->TRIPLET_EIGHTH, $d->backbeat_rhythm(-beat => $_));
    $d->rest($d->TRIPLET_EIGHTH);
    $d->note($d->TRIPLET_EIGHTH, $d->tick);
  }

  # A rock drummer:
  use MIDI::Simple::Drummer::Rock;
  $d = MIDI::Simple::Drummer::Rock->new(
    -bpm     => 100,
    -volume  => 100,
    -phrases => 8,
    -file    => 'rock-drums.mid',
  );
  my ($beat, $fill) = (0, 0);
  my @rotate = qw( 2.1 2.2 2.4 );
  $d->count_in;
  for my $p (1 .. $d->phrases) {
    if($p % 2 > 0) {
        $beat = $d->beat(-name => 2.3, -fill => $fill);
        $beat = $d->beat(-name => 2.3);
    }
    else {
        $beat = $d->beat(-name => (@rotate)[int(rand @rotate)]);
        $fill = $d->fill(-last => $fill);
    }
  }
  $d->patterns('end fill' => \&fin);
  $d->fill(-name => 'end');
  $d->write;
  sub fin {
    my $d = shift;
    $d->accent;
    # Crash and kick, simultaneously.
    $d->note('qn', $d->strike('Crash Cymbal 1', $d->name_of('kick')));
  }

  # Multi-tracking:
  $d = MIDI::Simple::Drummer->new(-file => "$0.mid");
  $d->patterns(b1 => \&hihat);
  $d->patterns(b2 => \&backbeat);
  $d->sync_tracks(
    sub { $d->beat(-name => 'b1') },
    sub { $d->beat(-name => 'b2') },
  );
  $d->write;
  sub hihat { # tick
    my $self = shift;
    $self->note($self->EIGHTH, $self->tick) for 1 .. 2 * $self->beats;
  }
  sub backbeat { # kick/snare
    my $self = shift;
    $self->note($self->QUARTER, $self->rotate($_)) for 1 .. $self->beats;
  }

=head1 DESCRIPTION

This is a "robotic" drummer that provides algorithmic methods to make beats,
rhythms, noise, what have you.  It is also a glorified metronome.

This is not a traditional "drum machine" that is controlled in a mechanical
or "arithmetic" sense.  It is a drummer, with which you can practice, improvise,
compose, record and experiment.

The "beats" are entirely constructed with Perl, and as such, any algorithmic
procedure can be used to generate the phrases - Bayesian, stochastic,
evolutionary, game simulation, L-system, recursive descent grammar, Markov
chain...

Note that B<you>, the programmer (and de facto drummer), should know what the
kit elements are named and what the patterns do.  For these things, "Use The
Source, Luke."  Also, check out the included style sub-classes, the F<eg/*>
files (and the F<*.mid> files they produce).

The default drum kit is the B<exciting> General MIDI Kit.  Fortunately, you can
import the F<.mid> file into your DAW and reassign better patches.

=head1 METHODS

=head2 new

  my $d = MIDI::Simple::Drummer->new(%arguments);

Return a new C<MIDI::Simple::Drummer> instance with these default arguments:

  # MIDI parameters:
  -channel    = 9    # MIDI-perl drum channel
  -volume     = 100  # 120 max
  -pan        = 64   # 0L .. 64M .. 127R
  -pan_width  = 0    # 0 .. 64 from center
  -patch      = 0    # Drum kit patch number
  -reverb     = 20   # Effect 0-127
  -chorus     = 0    # "
  # Rhythm metrics:
  -accent     = 30   # Volume increment
  -bpm        = 120  # 1 qn = .5 seconds = 500,000 microseconds
  -phrases    = 4    # Number of groups of measures
  -bars       = 4    # Number of measures
  -beats      = 4    # Number of beats in a measure
  -divisions  = 4    # Note values that "get the beat"
  -signature  = ''   # beats / divisions
  # The Goods™
  -file      => Drummer.mid # Set this to $0.mid, for instance.
  -kit       => Standard kit set by the API
  -patterns  => {}  # To be filled at run-time
  -score     => MIDI::Simple->new_score

These arguments can all be overridden in the constuctor with accessors.

=head2 volume, pan, pan_width, bpm

  $x = $d->method;
  $d->method($x);

Return and set the volume, pan, pan_width and beats-per-minute methods.

MIDI pan (C<CC#10>) goes from F<1> left to F<127> right.  That puts the middle
at F<63>.

=head2 phrases, bars, beats, divisions

B<phrases> is the number of bars (or measures) you want to play.

B<bars> is the number of groups of B<beats> you want to play.  Each bar is one
group of B<beats>.

B<beats> is the number of beats in a bar!  This is the numerator of the time
signature.

Measures are divided into the number of "note values" that constitute one beat.
B<divisions> is this number.  It is also known as the denominator of the time
signature; the part of the measure that "gets the beat" or simply, "the pulse."

These are all variables that you can use as rhythm metrics to control the groove.
They are just numbers, not objects or lists.

=head2 signature

Get or set the string ratio of B<-beats> over B<-divisions>.

=head2 div_name

The name of the denominator of the time signature.

=head2 patch

The drum kit.

1: Standard. 33: Jazz. 41: Brushes. Etc.

=head2 channel

Get or set the MIDI channel.

=head2 chorus, reverb

Effects 0 (off) to 127 (full)

=head2 file

Get or set the name for the F<.mid> file to write.

=head2 sync_tracks

Combine beats in parallel with an argument list of anonymous subroutines.

=head2 patterns

Return or set known style patterns.

=head2 score

  $x = $d->score;
  $x = $d->score($score);
  $x = $d->score($score, 'V127');
  $x = $d->score('V127');

Return or set the L<MIDI::Simple/score> if provided as the first argument.  If
there are any other arguments, they are treated as MIDI score settings.

=head2 accent_note

  $x = $d->accent_note($d->EIGHTH);

Accent a single note.

=head2 accent

  $x = $d->accent;

Either return the current volume plus the accent increment or set the accent
increment.  This has an upper limit of MIDI fff.

=head2 duck

This is the mirror opposite of the C<accent> method.

=head2 strike

  $x = $d->strike;
  $x = $d->strike('Cowbell');
  $x = $d->strike('Cowbell','Tambourine');
  @x = $d->strike('Cowbell','Tambourine');

Return note values for percussion names from the standard MIDI percussion set
(with L<MIDI/notenum2percussion>) in either scalar or list context. (Default
predefined snare patch)

=head2 option_strike

  $x = $d->option_strike;
  $x = $d->option_strike('Short Guiro','Short Whistle','Vibraslap');

Return a note value from a list of patches (default predefined crash cymbals).
If another set of patches is given, one of those is chosen at random.

=head2 note

  $d->note($d->SIXTEENTH, $d->snare);
  $d->note('sn', 'n38'); # Same

Add a note to the score.  This is a pass-through to L<MIDI::Simple/n>.

=head2 rest

  $d->rest($d->SIXTEENTH);
  $d->rest('sn'); # Same

Add a rest to the score.  This is a pass-through to L<MIDI::Simple/r>.

=head2 metronome

  $d->metronome;
  $d->metronome('Mute Triangle');

Add (beats * phrases) of the C<Pedal Hi-Hat>, unless another patch is provided.

=head2 count_in

  $d->count_in;
  $d->count_in(2);
  $d->count_in(1, 'Side Stick');

And a-one and a-two!E<lt>E<sol>Lawrence WelkE<gt> ..11E<lt>E<sol>FZE<gt>

If No arguments are provided, the C<Closed Hi-Hat> patch is used.

=head2 rotate

  $x = $d->rotate;
  $x = $d->rotate(3);
  $x = $d->rotate(5, ['Mute Hi Conga','Open Hi Conga','Low Conga']);

Rotate through a list of patches according to the given beat number.  (Default
backbeat patches)

=head2 backbeat_rhythm

  $x = $d->backbeat_rhythm;
  $x = $d->backbeat_rhythm(-beat => $y);
  $x = $d->backbeat_rhythm(-backbeat => ['Bass Drum 1','Electric Snare']);
  $x = $d->backbeat_rhythm(-patches => ['Cowbell','Hand Clap']);
  $x = $d->backbeat_rhythm(-tick => ['Claves']);
  $x = $d->backbeat_rhythm(-fill => $z);

Add a rotating backbeat to the score.

Arguments:

B<beat> is the beat we are on.

B<backbeat> is the list of patches to use instead of the stock bass and snare.

B<patches> is a list of possible patches to use instead of the crash cymbals.

B<tick> is the patch to use instead of the closed hi-hat.

B<fill> is the fill pattern we last played.

=head2 beat

  $x = $d->beat;
  $x = $d->beat(-name => $n);
  $x = $d->beat(-last => $y);
  $x = $d->beat(-fill => $z);
  $x = $d->beat(-type => 'fill');

Play a beat type and return the id for the selected pattern.  Beats and fills
are both just patterns but drummers think of them as distinct animals.

This method adds an anecdotal "beat" to the MIDI score.  You can indicate that
we filled in the previous bar, and do something exciting like crash on the first
beat, by supplying the C<-fill =E<gt> $z> argument, where C<$z> is the fill we
just played.  Similarly, the C<-last =E<gt> $y> argument indicates that C<$y> is
the last beat we played, so that we can maintain "context sensitivity."

Unless specifically given a pattern to play with the C<-name> argument, we try
to play something different each time, so if the pattern is the same as the
C<-last>, or if there is no given pattern to play, another is chosen.

For C<-type =E<gt> 'fill'>, we append a named fill to the MIDI score.

=head2 fill

This is an alias to C<beat(-type =E<gt> 'fill')>.

=head2 patterns

  $x = $d->patterns;
  $x = $d->patterns('rock_1');
  @x = $d->patterns(
    paraflamaramadiddle => \&paraflamaramadiddle,
    'foo fill' => \&foo_fill,
  );

Return or set the code references to the named patterns.  If no argument is
given, all the known patterns are returned.

=head2 write

  $x = $d->write;
  $x = $d->write('Buddy-Rich.mid');

This is an alias for L<MIDI::Simple/write_score> but with unimaginably
intelligent bits.  It returns the name of the written file if
successful.  If no filename is given, we use the preset C<-file> attribute.

=head1 KIT ACCESS

=head2 kit

  $x = $d->kit;
  $x = $d->kit('snare');
  @x = $d->kit( clapsnare => ['Handclap','Electric Snare'],
                kickstick => ['Bass Drum 1','Side Stick']);
  @x = $d->kit('clapsnare');

Return or set part or all of the percussion set.

=head2 name_of

  $x = $d->name_of('kick'); # "Acoustic Bass Drum"
  @x = $d->name_of('crash'); # ('Chinese Cymbal', 'Crash Cymbal 1...)

Return the instrument names behind the kit nick-name lists.

=head2 hhat

    $x = $d->hhat;
    $x = $d->hhat('Cabasa','Maracas','Claves');

Strike or set the "hhat" patches.  By default, these are the C<Closed Hi-Hat>,
C<Open Hi-Hat> and the C<Pedal Hi-Hat.>

=head2 crash

    $x = $d->crash;
    $x = $d->crash(@crashes);

Strike or set the "crash" patches.  By default, these are the C<Chinese Cymbal>,
C<Crash Cymbal 1>, C<Crash Cymbal 2> and the C<Splash Cymbal.>

=head2 ride

    $x = $d->ride;
    $x = $d->ride(@rides);

Strike or set the "ride" patches.  By default, these are the C<Ride Bell>,
C<Ride Cymbal 1> and the C<Ride Cymbal 2.>

=head2 tom

    $x = $d->tom;
    $x = $d->tom('Low Conga','Mute Hi Conga','Open Hi Conga');

Strike or set the "tom" patches.  By default, these are the C<High Tom>,
C<Hi-Mid Tom>, etc.

=head2 kick

    $x = $d->kick;
    $x = $d->kick('Bass Drum 1');

Strike or set the "kick" patch.  By default, this is the C<Acoustic Bass Drum>.

=head2 tick

    $x = $d->tick;
    $x = $d->tick('Mute Triangle');

Strike or set the "tick" patch.  By default, this is the C<Closed Hi-Hat>.

=head2 snare

    $x = $d->snare;
    $x = $d->snare('Electric Snare');

Strike or set the "snare" patches.  By default, this is the C<Acoustic Snare.>

=head2 backbeat

    $x = $d->backbeat;
    $x = $d->backbeat('Bass Drum 1','Side Stick');

Strike or set the "backbeat" patches.  By default, these are the predefined
C<kick> and C<snare> patches.  But if the time signature is a multiple of three,
the backbeat is set to a "kick snare kick" pattern.

=head1 CONVENIENCE METHODS

These are meant to avoid literal strings and the need to remember and type the
relevant MIDI variables.

=head2 WHOLE or _1st

  $x = $d->WHOLE;
  $x = $d->_1st;

Return C<'wn'>.

=head2 HALF or or _2nd

Return C<'hn'>.

=head2 QUARTER or _4th

Return C<'qn'>.

=head2 EIGHTH or _8th

Return C<'en'>.

=head2 SIXTEENTH or _16th

Return C<'sn'>.

=head2 THIRTYSECOND or _32nd

Return C<'yn'>.

=head2 SIXTYFOURTH or _64th

Return C<'xn'>.

=head2 _p2n

Return C<%MIDI::percussion2notenum> a la L<MIDI/GOODIES>.

=head2 _n2p

Return the inverse: C<%MIDI::notenum2percussion>.

=head2 _default_patterns

Patterns provided by default. This is C<{}>, that is, nothing.  This is defined
in a I<MIDI::Simple::Drummer::*> style package.

=head2 _default_kit

Kit provided by default. This is a subset of the B<exciting> general MIDI kit.
This can also be defined in a I<MIDI::Simple::Drummer::*> style package, to use
better patches.

=head1 SEE ALSO

The F<eg/*> and F<t/*> files, that come with this distribution

The I<MIDI::Simple::Drummer::*> styles

L<MIDI::Simple> itself

L<Music::Duration>

L<MIDI::Drummer::Tiny> - A Moo-based simplified drum module

L<https://en.wikipedia.org/wiki/General_MIDI#Percussion>

=head1 TO DO

Be smart about swing timing (e.g. $d->TRIPLET_XXXX).

Handle double and half time (via DIVISION hashref).

Use "relative rhythm metrics" if given a time signature.

Use L<MIDI::Score/quantize>?

Keep a running clock/total to know where we are in time, at all times.

Intelligently modulate dynamics to add nuance and "humanize."

Make a C<MIDI::Simple::Drummer::AC\x{26A1}DC> (Phil Rudd) style.

Leverage L<MIDI::Tab/from_drum_tab> or L<MIDI::Simple/read_score>?

=head1 CREDITS

Paul Evans E<lt>leonerd@leonerd.org.uk<gt> for help understanding constant
importing.

Kevin Goroway E<lt>kgoroway@yahoo.com<gt> for asking where the time signature
was and if the rudiments package was going to happen.

Jeremy Mates for the clever Euclidian rhythm algorithm.

=head1 AUTHOR

Gene Boggs <gene@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Gene Boggs.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
