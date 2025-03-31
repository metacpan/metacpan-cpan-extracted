package MIDI::Drummer::Tiny;
our $AUTHORITY = 'cpan:GENE';

# ABSTRACT: Glorified metronome

our $VERSION = '0.6006';

use 5.024;
use strictures 2;
use Carp;
use List::Util 1.26 qw(sum0);
use Moo;
use experimental qw(signatures);
use Math::Bezier ();
use MIDI::Util   qw(
    dura_size
    reverse_dump
    set_time_signature
    timidity_conf
    play_timidity
    play_fluidsynth
    ticks
);
use Music::Duration        ();
use Music::RhythmSet::Util qw(upsize);

use MIDI::Drummer::Tiny::Types qw(:all);
use Types::Standard            qw(InstanceOf FileHandle);
use Types::Path::Tiny          qw(File Path assert_Path);

use Data::Dumper::Compact qw(ddc);
use namespace::clean;

use constant STRAIGHT => 50;    # Swing percent

#pod =head1 SYNOPSIS
#pod
#pod   use MIDI::Drummer::Tiny;
#pod
#pod   my $d = MIDI::Drummer::Tiny->new(
#pod     file      => 'drums.mid',
#pod     bpm       => 100,
#pod     volume    => 100,
#pod     signature => '5/4',
#pod     bars      => 8,
#pod     reverb    => 0,
#pod     soundfont => '/you/soundfonts/TR808.sf2', # option
#pod     #kick      => 36, # Override default patch
#pod     #snare     => 40, # "
#pod   );
#pod
#pod   $d->metronome5;
#pod
#pod   $d->set_time_sig('4/4');
#pod   $d->count_in(1);  # Closed hi-hat for 1 bar
#pod   $d->metronome4($d->bars, $d->closed_hh, $d->eighth, 60); # swing!
#pod
#pod   $d->rest($d->whole);
#pod
#pod   $d->flam($d->quarter, $d->snare);
#pod   $d->crescendo_roll([50, 127, 1], $d->eighth, $d->thirtysecond);
#pod   $d->note($d->sixteenth, $d->crash1);
#pod   $d->accent_note(127, $d->sixteenth, $d->crash2);
#pod
#pod   # Alternate kick and snare
#pod   $d->note($d->quarter, $d->open_hh, $_ % 2 ? $d->kick : $d->snare)
#pod     for 1 .. $d->beats * $d->bars;
#pod
#pod   # Same but with beat-strings:
#pod   $d->sync_patterns(
#pod     $d->open_hh => [ '1111' ],
#pod     $d->snare   => [ '0101' ],
#pod     $d->kick    => [ '1010' ],
#pod   ) for 1 .. $d->bars;
#pod
#pod   my $patterns = [
#pod     your_function(5, 16), # e.g. a euclidean function
#pod     your_function(7, 16), # ...
#pod   ];
#pod   $d->pattern( instrument => $d->kick, patterns => $patterns ); # see doc...
#pod
#pod   $d->add_fill('...'); # see doc...
#pod
#pod   print 'Count: ', $d->counter, "\n";
#pod
#pod   # As a convenience, and sometimes necessity:
#pod   $d->set_bpm(200); # handy for tempo changes
#pod   $d->set_channel;  # reset back to 9 if ever changed
#pod
#pod   $d->timidity_cfg('timidity-drummer.cfg');
#pod
#pod   $d->write;
#pod   # OR:
#pod   $d->play_with_timidity;
#pod   # OR:
#pod   $d->play_with_fluidsynth;
#pod
#pod =head1 DESCRIPTION
#pod
#pod This module provides handy defaults and tools to produce a MIDI score
#pod with drum parts. It is full of tools to construct a score with drum
#pod parts. It is not a traditional "drum machine." Rather, it contains
#pod methods to construct a drum machine, or play "as a drummer might."
#pod
#pod Below, the term "spec" refers to a note length duration, like an
#pod eighth or quarter note, for instance.
#pod
#pod =for Pod::Coverage BUILD
#pod
#pod =cut

sub BUILD ( $self, $args_ref ) {
    return unless $self->setup;

    $self->score->noop( 'c' . $self->channel, 'V' . $self->volume );

    $self->score->set_tempo( int( 60_000_000 / $self->bpm ) );

    $self->score->control_change( $self->channel, 91, $self->reverb );

    # Add a TS to the score but don't reset the beats if given
    $self->set_time_sig( $self->signature, !$args_ref->{beats} );
    return;
}

#pod =attr verbose
#pod
#pod Default: C<0>
#pod
#pod =attr file
#pod
#pod This the MIDI file name to write. It can be a string, a
#pod L<Types::Path::Tiny/Path>, or a L<Types::Standard/FileHandle>.
#pod
#pod Default: C<MIDI-Drummer.mid>
#pod
#pod =cut

has file => (
    is      => 'ro',
    isa     => Path | FileHandle,
    coerce  => 1,
    default => 'MIDI-Drummer.mid',
);

#pod =attr soundfont
#pod
#pod   $soundfont = $d->soundfont;
#pod
#pod This is the location of the soundfont file. It can be a string or a
#pod L<Types::Path::Tiny/File>.
#pod
#pod =cut

has soundfont => (
    is     => 'rw',
    isa    => File,
    coerce => 1,
);

#pod =attr score
#pod
#pod Default: C<MIDI::Simple-E<gt>new_score>
#pod
#pod =method sync
#pod
#pod   $d->sync(@code_refs);
#pod
#pod This is a simple pass-through to the B<score> C<synch> method.
#pod
#pod This allows simultaneous playing of multiple "tracks" defined by code
#pod references.
#pod
#pod =cut

has score => (
    is      => 'ro',
    isa     => InstanceOf ['MIDI::Simple'],
    default => sub { MIDI::Simple->new_score },
    handles => { sync => 'synch' },
);

#pod =attr reverb
#pod
#pod Default: C<15>
#pod
#pod =attr channel
#pod
#pod Default: C<9>
#pod
#pod =method set_channel
#pod
#pod   $d->set_channel;
#pod   $d->set_channel($channel);
#pod
#pod Reset the channel to C<9> by default, or the given argument if
#pod different.
#pod
#pod =cut

has channel => (
    is      => 'rwp',
    isa     => Channel,
    default => 9,
);

sub set_channel ( $self, $channel = 9 ) {
    $self->score->noop("c$channel");
    $self->_set_channel($channel);
    return;
}

#pod =attr volume
#pod
#pod Default: C<100>
#pod
#pod =method set_volume
#pod
#pod   $d->set_volume;
#pod   $d->set_volume($volume);
#pod
#pod Set the volume (L<MIDI::Drummer::Tiny::Types::MIDI/Velocity>) to the given argument.
#pod
#pod If not given a B<volume> argument, this method mutes (sets to C<0>).
#pod
#pod =cut

has volume => (
    is      => 'rwp',
    isa     => Velocity,
    default => 100,

);

sub set_volume ( $self, $volume = 0 ) {
    $self->score->noop("V$volume");
    $self->_set_volume($volume);
    return;
}

#pod =attr bpm
#pod
#pod Default: C<120>
#pod
#pod =method set_bpm
#pod
#pod   $d->set_bpm($bpm);
#pod
#pod Reset the L<beats per minute|MIDI::Drummer::Tiny::Types/BPM>.
#pod
#pod =cut

has bpm => (
    is      => 'rw',
    isa     => BPM,
    default => 120,
    writer  => 'set_bpm',
    trigger => 1,
);

sub _trigger_bpm ( $self, $bpm = 120 ) {    ## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
    $self->score->set_tempo( int( 60_000_000 / $bpm ) );
    return;
}

#pod =attr bars
#pod
#pod Default: C<4>
#pod
#pod =attr signature
#pod
#pod Default: C<4/4>
#pod
#pod B<beats> / B<divisions>
#pod
#pod =attr beats
#pod
#pod Computed from the B<signature>, if not given in the constructor.
#pod
#pod Default: C<4>
#pod
#pod =attr divisions
#pod
#pod Computed from the B<signature>.
#pod
#pod Default: C<4>
#pod
#pod =attr setup
#pod
#pod Run the commands in the C<BUILD> method that set-up new midi score
#pod events like tempo, time signature, etc.
#pod
#pod Default: C<1>
#pod
#pod =attr counter
#pod
#pod   $d->counter( $d->counter + $duration );
#pod   $count = $d->counter;
#pod
#pod Beat counter of durations, where a quarter-note is equal to 1. An
#pod eighth-note is 0.5, etc.
#pod
#pod This is automatically accumulated each time a C<rest> or C<note> is
#pod added to the score.
#pod
#pod =cut

my %attr_defaults = (
    ro => {
        verbose => 0,
        reverb  => 15,
        bars    => 4,
    },
    rw => {
        signature => '4/4',
        beats     => 4,
        divisions => 4,
        setup     => 1,
        counter   => 0,
    },
);
for my $is ( keys %attr_defaults ) {
    for my $attr ( keys %{ $attr_defaults{$is} } ) {
        has $attr => (
            is      => $is,
            default => $attr_defaults{$is}{$attr},
        );
    }
}

#pod =kit metronome
#pod
#pod =over
#pod
#pod =item click, bell
#pod
#pod =back
#pod
#pod =kit hi-hats
#pod
#pod =over
#pod
#pod =item open_hh, closed_hh, pedal_hh
#pod
#pod =back
#pod
#pod =kit crash and splash cymbals
#pod
#pod =over
#pod
#pod =item crash1, crash2, splash, china
#pod
#pod =back
#pod
#pod =kit ride cymbals
#pod
#pod =over
#pod
#pod =item ride1, ride2, ride_bell
#pod
#pod =back
#pod
#pod =kit snare drums and handclaps
#pod
#pod =over
#pod
#pod =item snare, acoustic_snare, electric_snare, side_stick, clap
#pod
#pod Where the B<snare> is by default the same as the B<acoustic_snare> but
#pod can be overridden with the B<electric_snare> (C<40>).
#pod
#pod =back
#pod
#pod =kit tom-toms
#pod
#pod =over
#pod
#pod =item hi_tom, hi_mid_tom, low_mid_tom, low_tom, hi_floor_tom, low_floor_tom
#pod
#pod =back
#pod
#pod =kit bass drums
#pod
#pod =over
#pod
#pod =item kick, acoustic_bass, electric_bass
#pod
#pod Where the B<kick> is by default the same as the B<acoustic_bass> but
#pod can be overridden with the B<electric_bass> (C<36>).
#pod
#pod =back
#pod
#pod =kit auxiliary percussion
#pod
#pod =over
#pod
#pod =item tambourine, cowbell, vibraslap
#pod
#pod =back
#pod
#pod =kit Latin and African drums
#pod
#pod =over
#pod
#pod =item hi_bongo, low_bongo, mute_hi_conga, open_hi_conga, low_conga, high_timbale, low_timbale
#pod
#pod =back
#pod
#pod =kit Latin and African auxiliary percussion
#pod
#pod =over
#pod
#pod =item high_agogo, low_agogo, cabasa, maracas, short_whistle, long_whistle, short_guiro, long_guiro, claves, hi_wood_block, low_wood_block, mute_cuica, open_cuica
#pod
#pod =back
#pod
#pod =kit triangles
#pod
#pod =over
#pod
#pod =item mute_triangle, open_triangle
#pod
#pod =back
#pod
#pod =cut

use constant PERCUSSION_START => 33;
for my $sound ( qw(
    click
    bell
    acoustic_bass
    electric_bass
    side_stick
    acoustic_snare
    clap
    electric_snare
    low_floor_tom
    closed_hh
    hi_floor_tom
    pedal_hh
    low_tom
    open_hh
    low_mid_tom
    hi_mid_tom
    crash1
    hi_tom
    ride1
    china
    ride_bell
    tambourine
    splash
    cowbell
    crash2
    vibraslap
    ride2
    hi_bongo
    low_bongo
    mute_hi_conga
    open_hi_conga
    low_conga
    high_timbale
    low_timbale
    high_agogo
    low_agogo
    cabasa
    maracas
    short_whistle
    long_whistle
    short_guiro
    long_guiro
    claves
    hi_wood_block
    low_wood_block
    mute_cuica
    open_cuica
    mute_triangle
    open_triangle
) )
{
    state $percussion_note;
    has $sound => (
        is      => 'ro',
        isa     => PercussionNote,
        default => PERCUSSION_START + $percussion_note++,
    );
}
has kick => (
    is      => 'ro',
    isa     => PercussionNote,
    default => 35,               # Alt: 36
);
has snare => (
    is      => 'ro',
    isa     => PercussionNote,
    default => 38,               # Alt: 40
);

#pod =duration whole notes
#pod
#pod =over
#pod
#pod =item whole, triplet_whole, dotted_whole, double_dotted_whole
#pod
#pod =back
#pod
#pod =duration half notes
#pod
#pod =over
#pod
#pod =item half, triplet_half, dotted_half, double_dotted_half
#pod
#pod =back
#pod
#pod =duration quarter notes
#pod
#pod =over
#pod
#pod =item quarter, triplet_quarter, dotted_quarter, double_dotted_quarter
#pod
#pod =back
#pod
#pod =duration eighth notes
#pod
#pod =over
#pod
#pod =item eighth, triplet_eighth, dotted_eighth, double_dotted_eighth
#pod
#pod =back
#pod
#pod =duration sixteenth notes
#pod
#pod =over
#pod
#pod =item sixteenth, triplet_sixteenth, dotted_sixteenth, double_dotted_sixteenth
#pod
#pod =back
#pod
#pod =duration thirty-secondth notes
#pod
#pod =over
#pod
#pod =item thirtysecond, triplet_thirtysecond, dotted_thirtysecond, double_dotted_thirtysecond
#pod
#pod =back
#pod
#pod =duration sixty-fourth notes
#pod
#pod =over
#pod
#pod =item sixtyfourth, triplet_sixtyfourth, dotted_sixtyfourth, double_dotted_sixtyfourth
#pod
#pod =back
#pod
#pod =duration one-twenty-eighth notes
#pod
#pod =over
#pod
#pod =item onetwentyeighth, triplet_onetwentyeighth, dotted_onetwentyeighth, double_dotted_onetwentyeighth
#pod
#pod =back
#pod
#pod =cut

my %basic_note_durations = (
    whole           => 'w',
    half            => 'h',
    quarter         => 'q',
    eighth          => 'e',
    sixteenth       => 's',
    thirtysecond    => 'x',
    sixtyfourth     => 'y',
    onetwentyeighth => 'z',
);

my %duration_prefixes = (
    triplet       => 't',
    dotted        => 'd',
    double_dotted => 'dd',
);

for my $basic_duration ( keys %basic_note_durations ) {
    my $duration = $basic_note_durations{$basic_duration};

    has $basic_duration => (
        is      => 'ro',
        isa     => Duration,
        default => "${duration}n",
    );

    for my $prefix ( keys %duration_prefixes ) {
        has "${prefix}_${basic_duration}" => (
            is      => 'ro',
            isa     => Duration,
            default => "$duration_prefixes{$prefix}${duration}n",
        );
    }
}

#pod =method new
#pod
#pod   $d = MIDI::Drummer::Tiny->new(%arguments);
#pod
#pod Return a new C<MIDI::Drummer::Tiny> object and add a time signature
#pod event to the score.
#pod
#pod =method note
#pod
#pod   $d->note( $d->quarter, $d->closed_hh, $d->kick );
#pod   $d->note( 'qn', 42, 35 ); # Same thing
#pod
#pod Add notes to the score.
#pod
#pod This method takes the same arguments as L<MIDI::Simple/"Parameters for n/r/noop">.
#pod
#pod It also keeps track of the beat count with the C<counter> attribute.
#pod
#pod =cut

sub note ( $self, @spec ) {
    my $size
        = $spec[0] =~ /^d(\d+)$/
        ? $1 / ticks( $self->score )
        : dura_size( $spec[0] );

    # carp __PACKAGE__,' L',__LINE__,' ',,"$spec[0]\n";
    # carp __PACKAGE__,' L',__LINE__,' ',,"$size\n";
    $self->counter( $self->counter + $size );
    return $self->score->n(@spec);
}

#pod =method accent_note
#pod
#pod   $d->accent_note($accent_value, $d->sixteenth, $d->snare);
#pod
#pod Play an accented note.
#pod
#pod For instance, this can be a "ghosted note", where the B<accent> is a
#pod smaller number (< 50).  Or a note that is greater than the normal
#pod score volume.
#pod
#pod =cut

sub accent_note ( $self, $accent, @spec ) {
    my $resume = $self->score->Volume;
    $self->score->Volume($accent);
    $self->note(@spec);
    return $self->score->Volume($resume);
}

#pod =method rest
#pod
#pod   $d->rest( $d->quarter );
#pod
#pod Add a rest to the score.
#pod
#pod This method takes the same arguments as L<MIDI::Simple/"Parameters for n/r/noop">.
#pod
#pod It also keeps track of the beat count with the C<counter> attribute.
#pod
#pod =cut

sub rest ( $self, @spec ) {
    my $size
        = $spec[0] =~ /^d(\d+)$/
        ? $1 / ticks( $self->score )
        : dura_size( $spec[0] );

    # carp __PACKAGE__,' L',__LINE__,' ',,"$spec[0] => $size\n";
    $self->counter( $self->counter + $size );
    return $self->score->r(@spec);
}

#pod =method count_in
#pod
#pod   $d->count_in;
#pod   $d->count_in($bars);
#pod   $d->count_in({ bars => $bars, patch => $patch });
#pod
#pod Play a patch for the number of beats times the number of bars.
#pod
#pod If no bars are given, the object setting is used.  If no patch is
#pod given, the closed hihat is used.
#pod
#pod =cut

sub count_in ( $self, $args_ref ) {

    my $bars   = $self->bars;
    my $patch  = $self->pedal_hh;
    my $accent = $self->closed_hh;

    if ( $args_ref && ref $args_ref ) {
        $bars   = $args_ref->{bars}   if defined $args_ref->{bars};
        $patch  = $args_ref->{patch}  if defined $args_ref->{patch};
        $accent = $args_ref->{accent} if defined $args_ref->{accent};
    }
    elsif ($args_ref) {
        $bars = $args_ref;    # given a simple integer
    }

    my $j = 1;
    for my $i ( 1 .. $self->beats * $bars ) {
        if ( $i == $self->beats * $j - $self->beats + 1 ) {
            $self->accent_note( 127, $self->quarter, $accent );
            $j++;
        }
        else {
            $self->note( $self->quarter, $patch );
        }
    }
    return;
}

#pod =method metronome3
#pod
#pod   $d->metronome3;
#pod   $d->metronome3($bars);
#pod   $d->metronome3($bars, $cymbal);
#pod   $d->metronome3($bars, $cymbal, $tempo);
#pod   $d->metronome3($bars, $cymbal, $tempo, $swing);
#pod
#pod Add a steady 3/x beat to the score.
#pod
#pod Defaults for all metronome methods:
#pod
#pod   bars: The object B<bars>
#pod   cymbal: B<closed_hh>
#pod   tempo: B<quarter-note>
#pod   swing: 50 percent = straight-time
#pod
#pod =cut

sub metronome3 (
    $self,
    $bars   = $self->bars,
    $cymbal = $self->closed_hh,
    $tempo  = $self->quarter,
    $swing  = 50                  # percent
    )
{
    my $x = dura_size($tempo) * ticks( $self->score );
    my $y = sprintf '%0.f', ( $swing / 100 ) * $x;
    my $z = $x - $y;
    for ( 1 .. $bars ) {
        $self->note( "d$x", $cymbal, $self->kick );
        if ( $swing > STRAIGHT ) {
            $self->note( "d$y", $cymbal );
            $self->note( "d$z", $cymbal );
        }
        else {
            $self->note( "d$x", $cymbal );
        }
        $self->note( "d$x", $cymbal, $self->snare );
    }
    return;
}

#pod =method metronome4
#pod
#pod   $d->metronome4;
#pod   $d->metronome4($bars);
#pod   $d->metronome4($bars, $cymbal);
#pod   $d->metronome4($bars, $cymbal, $tempo);
#pod   $d->metronome4($bars, $cymbal, $tempo, $swing);
#pod
#pod Add a steady 4/x beat to the score.
#pod
#pod =cut

sub metronome4 (
    $self,
    $bars   = $self->bars,
    $cymbal = $self->closed_hh,
    $tempo  = $self->quarter,
    $swing  = 50                  # percent
    )
{
    my $x = dura_size($tempo) * ticks( $self->score );
    my $y = sprintf '%0.f', ( $swing / 100 ) * $x;
    my $z = $x - $y;
    for my $n ( 1 .. $bars ) {
        $self->note( "d$x", $cymbal, $self->kick );
        if ( $swing > STRAIGHT ) {
            $self->note( "d$y", $cymbal );
            $self->note( "d$z", $cymbal );
        }
        else {
            $self->note( "d$x", $cymbal );
        }
        $self->note( "d$x", $cymbal, $self->snare );
        if ( $swing > STRAIGHT ) {
            $self->note( "d$y", $cymbal );
            $self->note( "d$z", $cymbal );
        }
        else {
            $self->note( "d$x", $cymbal );
        }
    }
    return;
}

#pod =method metronome5
#pod
#pod   $d->metronome5;
#pod   $d->metronome5($bars);
#pod   $d->metronome5($bars, $cymbal);
#pod   $d->metronome5($bars, $cymbal, $tempo);
#pod   $d->metronome5($bars, $cymbal, $tempo, $swing);
#pod
#pod Add a 5/x beat to the score.
#pod
#pod =cut

sub metronome5 (
    $self,
    $bars   = $self->bars,
    $cymbal = $self->closed_hh,
    $tempo  = $self->quarter,
    $swing  = 50                  # percent
    )
{
    my $x    = dura_size($tempo) * ticks( $self->score );
    my $half = $x / 2;
    my $y    = sprintf '%0.f', ( $swing / 100 ) * $x;
    my $z    = $x - $y;

    for my $n ( 1 .. $bars ) {
        $self->note( "d$x", $cymbal, $self->kick );
        if ( $swing > STRAIGHT ) {
            $self->note( "d$y", $cymbal );
            $self->note( "d$z", $cymbal );
        }
        else {
            $self->note( "d$x", $cymbal );
        }
        $self->note( "d$x", $cymbal, $self->snare );
        if ( $swing > STRAIGHT ) {
            $self->note( "d$y", $cymbal );
            $self->note( "d$z", $cymbal );
        }
        else {
            $self->note( "d$x", $cymbal );
        }
        if ( $n % 2 ) {
            $self->note( "d$x", $cymbal );
        }
        else {
            $self->note( "d$half", $cymbal );
            $self->note( "d$half", $self->kick );
        }
    }
    return;
}

#pod =method metronome6
#pod
#pod   $d->metronome6;
#pod   $d->metronome6($bars);
#pod   $d->metronome6($bars, $cymbal);
#pod   $d->metronome6($bars, $cymbal, $tempo);
#pod   $d->metronome6($bars, $cymbal, $tempo, $swing);
#pod
#pod Add a 6/x beat to the score.
#pod
#pod =cut

sub metronome6 (
    $self,
    $bars   = $self->bars,
    $cymbal = $self->closed_hh,
    $tempo  = $self->quarter,
    $swing  = 50                  # percent
    )
{
    my $x = dura_size($tempo) * ticks( $self->score );
    my $y = sprintf '%0.f', ( $swing / 100 ) * $x;
    my $z = $x - $y;

    for my $n ( 1 .. $bars ) {
        $self->note( "d$x", $cymbal, $self->kick );
        if ( $swing > STRAIGHT ) {
            $self->note( "d$y", $cymbal );
            $self->note( "d$z", $cymbal );
        }
        else {
            $self->note( "d$x", $cymbal );
        }
        $self->note( "d$x", $cymbal );
        $self->note( "d$x", $cymbal, $self->snare );
        if ( $swing > STRAIGHT ) {
            $self->note( "d$y", $cymbal );
            $self->note( "d$z", $cymbal );
        }
        else {
            $self->note( "d$x", $cymbal );
        }
        $self->note( "d$x", $cymbal );
    }
    return;
}

#pod =method metronome7
#pod
#pod   $d->metronome7;
#pod   $d->metronome7($bars);
#pod   $d->metronome7($bars, $cymbal);
#pod   $d->metronome7($bars, $cymbal, $tempo);
#pod   $d->metronome7($bars, $cymbal, $tempo, $swing);
#pod
#pod Add a 7/x beat to the score.
#pod
#pod =cut

sub metronome7 (
    $self,
    $bars   = $self->bars,
    $cymbal = $self->closed_hh,
    $tempo  = $self->quarter,
    $swing  = 50                  # percent
    )
{
    my $x = dura_size($tempo) * ticks( $self->score );
    my $y = sprintf '%0.f', ( $swing / 100 ) * $x;
    my $z = $x - $y;

    for my $n ( 1 .. $bars ) {
        $self->note( "d$x", $cymbal, $self->kick );
        if ( $swing > STRAIGHT ) {
            $self->note( "d$y", $cymbal );
            $self->note( "d$z", $cymbal );
        }
        else {
            $self->note( "d$x", $cymbal );
        }
        $self->note( "d$x", $cymbal );
        if ( $swing > STRAIGHT ) {
            $self->note( "d$y", $cymbal, $self->kick );
            $self->note( "d$z", $cymbal );
        }
        else {
            $self->note( "d$x", $cymbal, $self->kick );
        }
        $self->note( "d$x", $cymbal, $self->snare );
        if ( $swing > STRAIGHT ) {
            $self->note( "d$y", $cymbal );
            $self->note( "d$z", $cymbal );
        }
        else {
            $self->note( "d$x", $cymbal );
        }
        $self->note( "d$x", $cymbal );
    }
    return;
}

#pod =method metronome44
#pod
#pod   $d->metronome44;
#pod   $d->metronome44($bars);
#pod   $d->metronome44($bars, $flag);
#pod   $d->metronome44($bars, $flag, $cymbal);
#pod
#pod Add a steady quarter-note based 4/4 beat to the score.
#pod
#pod If a B<flag> is provided the beat is modified to include alternating
#pod eighth-note kicks.
#pod
#pod =cut

sub metronome44 (
    $self, $bars = $self->bars,
    $flag = 0, $cymbal = $self->closed_hh,
    )
{
    my $i = 0;
    for my $n ( 1 .. $self->beats * $bars ) {
        if ( $n % 2 == 0 ) {
            $self->note( $self->quarter, $cymbal, $self->snare );
        }
        else {
            if ( $flag == 0 ) {
                $self->note( $self->quarter, $cymbal, $self->kick );
            }
            else {
                if ( $i % 2 == 0 ) {
                    $self->note( $self->quarter, $cymbal, $self->kick );
                }
                else {
                    $self->note( $self->eighth, $cymbal, $self->kick );
                    $self->note( $self->eighth, $self->kick );
                }
            }
            $i++;
        }
    }
    return;
}

#pod =method flam
#pod
#pod   $d->flam($spec);
#pod   $d->flam( $spec, $grace_note );
#pod   $d->flam( $spec, $grace_note, $patch );
#pod   $d->flam( $spec, $grace_note, $patch, $accent );
#pod
#pod Add a "flam" to the score, where a ghosted 64th gracenote is played
#pod before the primary note.
#pod
#pod If not provided the B<snare> is used for the B<grace> and B<patch>
#pod patches.  Also, 1/2 of the score volume is used for the B<accent>
#pod if that is not given.
#pod
#pod If the B<grace> note is given as a literal C<'r'>, rest instead of
#pod adding a note to the score.
#pod
#pod =cut

sub flam (
    $self, $spec,
    $grace  = $self->snare,
    $patch  = $self->snare,
    $accent = sprintf '%0.f',
    $self->score->Volume / 2
    )
{
    my ( $x, $y )
        = @MIDI::Simple::Length{ $spec, $self->sixtyfourth };    ## no critic (Variables::ProhibitPackageVars)
    my $z = sprintf '%0.f', ( $x - $y ) * ticks( $self->score );
    if ( $grace eq 'r' ) {
        $self->rest( $self->sixtyfourth );
    }
    else {
        $self->accent_note( $accent, $self->sixtyfourth, $grace );
    }
    return $self->note( 'd' . $z, $patch );
}

#pod =method roll
#pod
#pod   $d->roll( $length, $spec );
#pod   $d->roll( $length, $spec, $patch );
#pod
#pod Add a drum roll to the score, where the B<patch> is played for
#pod duration B<length> in B<spec> increments.
#pod
#pod If not provided the B<snare> is used for the B<patch>.
#pod
#pod =cut

sub roll ( $self, $length, $spec, $patch = $self->snare ) {
    my ( $x, $y ) = @MIDI::Simple::Length{ $length, $spec };    ## no critic (Variables::ProhibitPackageVars)
    my $z = sprintf '%0.f', $x / $y;
    $self->note( $spec, $patch ) for 1 .. $z;
    return;
}

#pod =method crescendo_roll
#pod
#pod   $d->crescendo_roll( [$start, $end, $bezier], $length, $spec );
#pod   $d->crescendo_roll( [$start, $end, $bezier], $length, $spec, $patch );
#pod
#pod Add a drum roll to the score, where the B<patch> is played for
#pod duration B<length> in B<spec> notes, at increasing or decreasing
#pod volumes from B<start> to B<end>.
#pod
#pod If not provided the B<snare> is used for the B<patch>.
#pod
#pod If true, the B<bezier> flag will render the crescendo with a curve,
#pod rather than as a straight line.
#pod
#pod       |            *
#pod       |           *
#pod   vol |         *
#pod       |      *
#pod       |*
#pod       ---------------
#pod             time
#pod
#pod =cut

sub crescendo_roll ( $self, $span_ref, $length, $spec,
    $patch = $self->snare )
{
    my ( $i, $j, $k ) = $span_ref->@*;
    my ( $x, $y ) = @MIDI::Simple::Length{ $length, $spec };    ## no critic (Variables::ProhibitPackageVars)
    my $z = sprintf '%0.f', $x / $y;
    if ($k) {
        my $bezier = Math::Bezier->new( 1, $i, $z, $i, $z, $j, );
        for ( my $n = 0 ; $n <= 1 ; $n += ( 1 / ( $z - 1 ) ) ) {
            my ( undef, $v ) = $bezier->point($n);
            $v = sprintf '%0.f', $v;

            # carp (__PACKAGE__,' ',__LINE__," $n INC: $v\n");
            $self->accent_note( $v, $spec, $patch );
        }
    }
    else {
        my $v = sprintf '%0.f', ( $j - $i ) / ( $z - 1 );

        # carp (__PACKAGE__,' ',__LINE__," VALUE: $v\n");
        for my $n ( 1 .. $z ) {
            if ( $n == $z ) {
                if ( $i < $j ) {
                    $i += $j - $i;
                }
                elsif ( $i > $j ) {
                    $i -= $i - $j;
                }
            }

            # carp (__PACKAGE__,' ',__LINE__," $n INC: $i\n");
            $self->accent_note( $i, $spec, $patch );
            $i += $v;
        }
    }
    return;
}

#pod =method pattern
#pod
#pod   $d->pattern( patterns => \@patterns );
#pod   $d->pattern( patterns => \@patterns, instrument => $d->kick );
#pod   $d->pattern( patterns => \@patterns, instrument => $d->kick, %options );
#pod
#pod Play a given set of beat B<patterns> with the given B<instrument>.
#pod
#pod The B<patterns> are an arrayref of "beat-strings".  By default these
#pod are made of contiguous ones and zeros, meaning "strike" or "rest".
#pod For example:
#pod
#pod   patterns => [qw( 0101 0101 0110 0110 )],
#pod
#pod This method accumulates the number of beats in the object's B<counter>
#pod attribute.
#pod
#pod The B<vary> option is a hashref of coderefs, keyed by single character
#pod tokens, like the digits 0-9.  Each coderef duration should add up to
#pod the given B<duration> option.  The single argument to the coderefs is
#pod the object itself and may be used as: C<my $self = shift;> in yours.
#pod
#pod These patterns can be generated with any custom function, as in the
#pod L</SYNOPSIS>. For instance, you could use the L<Creating::Rhythms>
#pod module to generate Euclidean patterns.
#pod
#pod Defaults:
#pod
#pod   instrument: snare
#pod   patterns: [] (i.e. empty!)
#pod   Options:
#pod     duration: quarter-note
#pod     beats: given by constructor
#pod     repeat: 1
#pod     negate: 0 (flip the bit values)
#pod     vary:
#pod         0 => sub { $self->rest( $args{duration} ) },
#pod         1 => sub { $self->note( $args{duration}, $args{instrument} ) },
#pod
#pod =cut

sub pattern ( $self, %args ) {
    $args{instrument} ||= $self->snare;
    $args{patterns}   ||= [];
    $args{beats}      ||= $self->beats;
    $args{negate}     ||= 0;
    $args{repeat}     ||= 1;

    return unless $args{patterns}->@*;

    # set size and duration
    my $size;
    if ( $args{duration} ) {
        $size = dura_size( $args{duration} ) || 1;
    }
    else {
        $size = 4 / length( $args{patterns}->[0] );
        my $dump = reverse_dump('length');
        $args{duration} = $dump->{$size} || $self->quarter;
    }

    # set the default beat-string variations
    $args{vary} ||= {
        0 => sub { $self->rest( $args{duration} ) },
        1 =>
            sub { $self->note( $args{duration}, $args{instrument} ) },
    };

    for my $pattern ( $args{patterns}->@* ) {
        $pattern =~ tr/01/10/ if $args{negate};

        next if $pattern =~ /^0+$/;

        for ( 1 .. $args{repeat} ) {
            for my $bit ( split //, $pattern ) {
                $args{vary}{$bit}->( $self, %args );
            }
        }
    }
    return;
}

#pod =method sync_patterns
#pod
#pod   $d->sync_patterns( $instrument1 => $patterns1, $inst2 => $pats2, ... );
#pod   $d->sync_patterns(
#pod       $d->open_hh => [ '11111111') ],
#pod       $d->snare   => [ '0101' ],
#pod       $d->kick    => [ '1010' ],
#pod       duration    => $d->eighth, # render all notes at this level of granularity
#pod   ) for 1 .. $d->bars;
#pod
#pod Execute the C<pattern> method for multiple voices.
#pod
#pod If a C<duration> is provided, this will be used for each pattern
#pod (primarily for the B<add_fill> method).
#pod
#pod =cut

sub sync_patterns ( $self, %patterns ) {
    my $master_duration = delete $patterns{duration};

    my @subs;
    for my $instrument ( keys %patterns ) {
        push @subs, sub {
            $self->pattern(
                instrument => $instrument,
                patterns   => $patterns{$instrument},
                $master_duration
                ? ( duration => $master_duration )
                : (),
            );
        },;
    }

    return $self->sync(@subs);
}

#pod =method add_fill
#pod
#pod   $d->add_fill( $fill, $instrument1 => $patterns1, $inst2 => $pats2, ... );
#pod   $d->add_fill(
#pod       sub {
#pod           my $self = shift;
#pod           return {
#pod             duration       => 16, # sixteenth note fill
#pod             $self->open_hh => '00000000',
#pod             $self->snare   => '11111111',
#pod             $self->kick    => '00000000',
#pod           };
#pod       },
#pod       $d->open_hh => [ '11111111' ],  # example phrase
#pod       $d->snare   => [ '0101' ],      # "
#pod       $d->kick    => [ '1010' ],      # "
#pod   );
#pod
#pod Add a fill to the beat pattern.  That is, replace the end of the given
#pod beat-string phrase with a fill.  The fill is given as the first
#pod argument and should be a coderef that returns a hashref.  The default
#pod is a three-note, eighth-note snare fill.
#pod
#pod =cut

sub add_fill ( $self, $fill = undef, %patterns ) {
    $fill //= sub { {
        duration       => 8,
        $self->open_hh => '000',
        $self->snare   => '111',
        $self->kick    => '000',
    } };
    my $fill_patterns = $fill->($self);
    carp 'Fill: ', ddc($fill_patterns) if $self->verbose;
    my $fill_duration = delete $fill_patterns->{duration} || 8;
    my $fill_length   = length( ( values %$fill_patterns )[0] );

    my %lengths;
    for my $instrument ( keys %patterns ) {
        $lengths{$instrument}
            = sum0 map { length $_ } $patterns{$instrument}->@*;
    }

    my $lcm = _multilcm( $fill_duration, values %lengths );
    carp "LCM: $lcm\n" if $self->verbose;

    my $size = 4 / $lcm;
    my $dump = reverse_dump('length');
    my $master_duration
        = $dump->{$size} || $self->eighth;    # XXX this || is not right
    carp "Size: $size, Duration: $master_duration\n" if $self->verbose;

    my $fill_chop
        = $fill_duration == $lcm
        ? $fill_length
        : int( $lcm / $fill_length ) + 1;
    carp "Chop: $fill_chop\n" if $self->verbose;

    my %fresh_patterns;
    for my $instrument ( keys %patterns ) {

        # get a single "flattened" pattern as an arrayref
        my $pattern
            = [ map { split //, $_ } $patterns{$instrument}->@* ];

        # the fresh pattern is possibly upsized with the LCM
        $fresh_patterns{$instrument}
            = $pattern->@* < $lcm
            ? [ join '', upsize( $pattern, $lcm )->@* ]
            : [ join '', $pattern->@* ];
    }
    carp 'Patterns: ', ddc( \%fresh_patterns ) if $self->verbose;

    my %replacement;
    for my $instrument ( keys $fill_patterns->%* ) {

        # get a single "flattened" pattern as a zero-pre-padded arrayref
        my $pattern = [
            split //,       sprintf '%0*s',
            $fill_duration, $fill_patterns->{$instrument} ];

        # the fresh pattern string is possibly upsized with the LCM
        my $fresh
            = $pattern->@* < $lcm
            ? join '', upsize( $pattern, $lcm )->@*
            : join '', $pattern->@*;

        # the replacement string is the tail of the fresh pattern string
        $replacement{$instrument} = substr $fresh, -$fill_chop;
    }
    carp 'Replacements: ', ddc( \%replacement ) if $self->verbose;

    my %replaced;
    for my $instrument ( keys %fresh_patterns ) {

        # get the string to replace
        my $string = join '', $fresh_patterns{$instrument}->@*;

        # replace the tail of the string
        my $pos = length $replacement{$instrument};
        substr $string, -$pos, $pos, $replacement{$instrument};
        carp "$instrument: $string\n" if $self->verbose;

        # prepare the replaced pattern for syncing
        $replaced{$instrument} = [$string];
    }

    $self->sync_patterns( %replaced, duration => $master_duration, );

    return \%replaced;
}

#pod =method set_time_sig
#pod
#pod   $d->set_time_sig;
#pod   $d->set_time_sig('5/4');
#pod   $d->set_time_sig( '5/4', 0 );
#pod
#pod Add a time signature event to the score, and reset the B<beats> and
#pod B<divisions> object attributes.
#pod
#pod If a ratio argument is given, set the B<signature> object attribute to
#pod it.  If the 2nd argument flag is C<0>, the B<beats> and B<divisions>
#pod are B<not> reset.
#pod
#pod =cut

sub set_time_sig ( $self, $time_signature, $set = 1 ) {
    $self->signature($time_signature) if $time_signature;
    if ($set) {
        my ( $beats, $divisions ) = split /\//, $self->signature;
        $self->beats($beats);
        $self->divisions($divisions);
    }
    return set_time_signature( $self->score, $self->signature );
}

#pod =method write
#pod
#pod Output the score as a MIDI file with the module L</file> attribute as
#pod the file name.
#pod
#pod =cut

sub write ($self) {    ## no critic (Subroutines::ProhibitBuiltinHomonyms)
    return $self->score->write_score( $self->file );
}

#pod =method timidity_cfg
#pod
#pod   $timidity_conf = $d->timidity_cfg;
#pod   $d->timidity_cfg($config_file);
#pod
#pod Return a timidity.cfg paragraph to use a defined B<soundfont>
#pod attribute. If a B<config_file> is given, the timidity configuration is
#pod written to that file.
#pod
#pod =cut

sub timidity_cfg {
    my ($self, $config) = @_;
    croak 'No soundfont defined' unless $self->soundfont;
    my $cfg = timidity_conf( $self->soundfont, $config );
    return $cfg;
}

#pod =method play_with_timidity
#pod
#pod   $d->play_with_timidity;
#pod   $d->play_with_timidity($config_file);
#pod
#pod Play the score with C<timidity>.
#pod
#pod If there is a B<soundfont> attribute, either the given B<config_file>
#pod or C<timidity-midi-util.cfg> is used for the timidity configuration.
#pod If a soundfont is not defined, a timidity configuration file is not
#pod rendered.
#pod
#pod See L<MIDI::Util/play_timidity> for more details.
#pod
#pod =cut

sub play_with_timidity {
    my ($self, $config) = @_;
    return play_timidity( $self->score, assert_Path( $self->file ),
        $self->soundfont, $config );
}

#pod =method play_with_fluidsynth
#pod
#pod   $d->play_with_fluidsynth;
#pod   $d->play_with_fluidsynth(\@config);
#pod
#pod Play the score with C<fluidsynth>.
#pod
#pod See L<MIDI::Util/play_fluidsynth> for more details.
#pod
#pod =cut

sub play_with_fluidsynth {
    my ($self, $config) = @_;
    return play_fluidsynth( $self->score, assert_Path( $self->file ),
        $self->soundfont, $config );
}

# lifted from https://www.perlmonks.org/?node_id=56906
sub _gcf ( $x, $y ) {
    ( $x, $y ) = ( $y, $x % $y ) while $y;
    return $x;
}

sub _lcm ( $x, $y ) { return $x * $y / _gcf( $x, $y ) }

sub _multilcm {    ## no critic (Subroutines::RequireArgUnpacking)
    my $x = shift;
    $x = _lcm( $x, shift ) while @_;
    return $x;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MIDI::Drummer::Tiny - Glorified metronome

=head1 VERSION

version 0.6006

=head1 SYNOPSIS

  use MIDI::Drummer::Tiny;

  my $d = MIDI::Drummer::Tiny->new(
    file      => 'drums.mid',
    bpm       => 100,
    volume    => 100,
    signature => '5/4',
    bars      => 8,
    reverb    => 0,
    soundfont => '/you/soundfonts/TR808.sf2', # option
    #kick      => 36, # Override default patch
    #snare     => 40, # "
  );

  $d->metronome5;

  $d->set_time_sig('4/4');
  $d->count_in(1);  # Closed hi-hat for 1 bar
  $d->metronome4($d->bars, $d->closed_hh, $d->eighth, 60); # swing!

  $d->rest($d->whole);

  $d->flam($d->quarter, $d->snare);
  $d->crescendo_roll([50, 127, 1], $d->eighth, $d->thirtysecond);
  $d->note($d->sixteenth, $d->crash1);
  $d->accent_note(127, $d->sixteenth, $d->crash2);

  # Alternate kick and snare
  $d->note($d->quarter, $d->open_hh, $_ % 2 ? $d->kick : $d->snare)
    for 1 .. $d->beats * $d->bars;

  # Same but with beat-strings:
  $d->sync_patterns(
    $d->open_hh => [ '1111' ],
    $d->snare   => [ '0101' ],
    $d->kick    => [ '1010' ],
  ) for 1 .. $d->bars;

  my $patterns = [
    your_function(5, 16), # e.g. a euclidean function
    your_function(7, 16), # ...
  ];
  $d->pattern( instrument => $d->kick, patterns => $patterns ); # see doc...

  $d->add_fill('...'); # see doc...

  print 'Count: ', $d->counter, "\n";

  # As a convenience, and sometimes necessity:
  $d->set_bpm(200); # handy for tempo changes
  $d->set_channel;  # reset back to 9 if ever changed

  $d->timidity_cfg('timidity-drummer.cfg');

  $d->write;
  # OR:
  $d->play_with_timidity;
  # OR:
  $d->play_with_fluidsynth;

=head1 DESCRIPTION

This module provides handy defaults and tools to produce a MIDI score
with drum parts. It is full of tools to construct a score with drum
parts. It is not a traditional "drum machine." Rather, it contains
methods to construct a drum machine, or play "as a drummer might."

Below, the term "spec" refers to a note length duration, like an
eighth or quarter note, for instance.

=head1 ATTRIBUTES

=head2 verbose

Default: C<0>

=head2 file

This the MIDI file name to write. It can be a string, a
L<Types::Path::Tiny/Path>, or a L<Types::Standard/FileHandle>.

Default: C<MIDI-Drummer.mid>

=head2 soundfont

  $soundfont = $d->soundfont;

This is the location of the soundfont file. It can be a string or a
L<Types::Path::Tiny/File>.

=head2 score

Default: C<MIDI::Simple-E<gt>new_score>

=head2 reverb

Default: C<15>

=head2 channel

Default: C<9>

=head2 volume

Default: C<100>

=head2 bpm

Default: C<120>

=head2 bars

Default: C<4>

=head2 signature

Default: C<4/4>

B<beats> / B<divisions>

=head2 beats

Computed from the B<signature>, if not given in the constructor.

Default: C<4>

=head2 divisions

Computed from the B<signature>.

Default: C<4>

=head2 setup

Run the commands in the C<BUILD> method that set-up new midi score
events like tempo, time signature, etc.

Default: C<1>

=head2 counter

  $d->counter( $d->counter + $duration );
  $count = $d->counter;

Beat counter of durations, where a quarter-note is equal to 1. An
eighth-note is 0.5, etc.

This is automatically accumulated each time a C<rest> or C<note> is
added to the score.

=head1 METHODS

=head2 sync

  $d->sync(@code_refs);

This is a simple pass-through to the B<score> C<synch> method.

This allows simultaneous playing of multiple "tracks" defined by code
references.

=head2 set_channel

  $d->set_channel;
  $d->set_channel($channel);

Reset the channel to C<9> by default, or the given argument if
different.

=head2 set_volume

  $d->set_volume;
  $d->set_volume($volume);

Set the volume (L<MIDI::Drummer::Tiny::Types::MIDI/Velocity>) to the given argument.

If not given a B<volume> argument, this method mutes (sets to C<0>).

=head2 set_bpm

  $d->set_bpm($bpm);

Reset the L<beats per minute|MIDI::Drummer::Tiny::Types/BPM>.

=head2 new

  $d = MIDI::Drummer::Tiny->new(%arguments);

Return a new C<MIDI::Drummer::Tiny> object and add a time signature
event to the score.

=head2 note

  $d->note( $d->quarter, $d->closed_hh, $d->kick );
  $d->note( 'qn', 42, 35 ); # Same thing

Add notes to the score.

This method takes the same arguments as L<MIDI::Simple/"Parameters for n/r/noop">.

It also keeps track of the beat count with the C<counter> attribute.

=head2 accent_note

  $d->accent_note($accent_value, $d->sixteenth, $d->snare);

Play an accented note.

For instance, this can be a "ghosted note", where the B<accent> is a
smaller number (< 50).  Or a note that is greater than the normal
score volume.

=head2 rest

  $d->rest( $d->quarter );

Add a rest to the score.

This method takes the same arguments as L<MIDI::Simple/"Parameters for n/r/noop">.

It also keeps track of the beat count with the C<counter> attribute.

=head2 count_in

  $d->count_in;
  $d->count_in($bars);
  $d->count_in({ bars => $bars, patch => $patch });

Play a patch for the number of beats times the number of bars.

If no bars are given, the object setting is used.  If no patch is
given, the closed hihat is used.

=head2 metronome3

  $d->metronome3;
  $d->metronome3($bars);
  $d->metronome3($bars, $cymbal);
  $d->metronome3($bars, $cymbal, $tempo);
  $d->metronome3($bars, $cymbal, $tempo, $swing);

Add a steady 3/x beat to the score.

Defaults for all metronome methods:

  bars: The object B<bars>
  cymbal: B<closed_hh>
  tempo: B<quarter-note>
  swing: 50 percent = straight-time

=head2 metronome4

  $d->metronome4;
  $d->metronome4($bars);
  $d->metronome4($bars, $cymbal);
  $d->metronome4($bars, $cymbal, $tempo);
  $d->metronome4($bars, $cymbal, $tempo, $swing);

Add a steady 4/x beat to the score.

=head2 metronome5

  $d->metronome5;
  $d->metronome5($bars);
  $d->metronome5($bars, $cymbal);
  $d->metronome5($bars, $cymbal, $tempo);
  $d->metronome5($bars, $cymbal, $tempo, $swing);

Add a 5/x beat to the score.

=head2 metronome6

  $d->metronome6;
  $d->metronome6($bars);
  $d->metronome6($bars, $cymbal);
  $d->metronome6($bars, $cymbal, $tempo);
  $d->metronome6($bars, $cymbal, $tempo, $swing);

Add a 6/x beat to the score.

=head2 metronome7

  $d->metronome7;
  $d->metronome7($bars);
  $d->metronome7($bars, $cymbal);
  $d->metronome7($bars, $cymbal, $tempo);
  $d->metronome7($bars, $cymbal, $tempo, $swing);

Add a 7/x beat to the score.

=head2 metronome44

  $d->metronome44;
  $d->metronome44($bars);
  $d->metronome44($bars, $flag);
  $d->metronome44($bars, $flag, $cymbal);

Add a steady quarter-note based 4/4 beat to the score.

If a B<flag> is provided the beat is modified to include alternating
eighth-note kicks.

=head2 flam

  $d->flam($spec);
  $d->flam( $spec, $grace_note );
  $d->flam( $spec, $grace_note, $patch );
  $d->flam( $spec, $grace_note, $patch, $accent );

Add a "flam" to the score, where a ghosted 64th gracenote is played
before the primary note.

If not provided the B<snare> is used for the B<grace> and B<patch>
patches.  Also, 1/2 of the score volume is used for the B<accent>
if that is not given.

If the B<grace> note is given as a literal C<'r'>, rest instead of
adding a note to the score.

=head2 roll

  $d->roll( $length, $spec );
  $d->roll( $length, $spec, $patch );

Add a drum roll to the score, where the B<patch> is played for
duration B<length> in B<spec> increments.

If not provided the B<snare> is used for the B<patch>.

=head2 crescendo_roll

  $d->crescendo_roll( [$start, $end, $bezier], $length, $spec );
  $d->crescendo_roll( [$start, $end, $bezier], $length, $spec, $patch );

Add a drum roll to the score, where the B<patch> is played for
duration B<length> in B<spec> notes, at increasing or decreasing
volumes from B<start> to B<end>.

If not provided the B<snare> is used for the B<patch>.

If true, the B<bezier> flag will render the crescendo with a curve,
rather than as a straight line.

      |            *
      |           *
  vol |         *
      |      *
      |*
      ---------------
            time

=head2 pattern

  $d->pattern( patterns => \@patterns );
  $d->pattern( patterns => \@patterns, instrument => $d->kick );
  $d->pattern( patterns => \@patterns, instrument => $d->kick, %options );

Play a given set of beat B<patterns> with the given B<instrument>.

The B<patterns> are an arrayref of "beat-strings".  By default these
are made of contiguous ones and zeros, meaning "strike" or "rest".
For example:

  patterns => [qw( 0101 0101 0110 0110 )],

This method accumulates the number of beats in the object's B<counter>
attribute.

The B<vary> option is a hashref of coderefs, keyed by single character
tokens, like the digits 0-9.  Each coderef duration should add up to
the given B<duration> option.  The single argument to the coderefs is
the object itself and may be used as: C<my $self = shift;> in yours.

These patterns can be generated with any custom function, as in the
L</SYNOPSIS>. For instance, you could use the L<Creating::Rhythms>
module to generate Euclidean patterns.

Defaults:

  instrument: snare
  patterns: [] (i.e. empty!)
  Options:
    duration: quarter-note
    beats: given by constructor
    repeat: 1
    negate: 0 (flip the bit values)
    vary:
        0 => sub { $self->rest( $args{duration} ) },
        1 => sub { $self->note( $args{duration}, $args{instrument} ) },

=head2 sync_patterns

  $d->sync_patterns( $instrument1 => $patterns1, $inst2 => $pats2, ... );
  $d->sync_patterns(
      $d->open_hh => [ '11111111') ],
      $d->snare   => [ '0101' ],
      $d->kick    => [ '1010' ],
      duration    => $d->eighth, # render all notes at this level of granularity
  ) for 1 .. $d->bars;

Execute the C<pattern> method for multiple voices.

If a C<duration> is provided, this will be used for each pattern
(primarily for the B<add_fill> method).

=head2 add_fill

  $d->add_fill( $fill, $instrument1 => $patterns1, $inst2 => $pats2, ... );
  $d->add_fill(
      sub {
          my $self = shift;
          return {
            duration       => 16, # sixteenth note fill
            $self->open_hh => '00000000',
            $self->snare   => '11111111',
            $self->kick    => '00000000',
          };
      },
      $d->open_hh => [ '11111111' ],  # example phrase
      $d->snare   => [ '0101' ],      # "
      $d->kick    => [ '1010' ],      # "
  );

Add a fill to the beat pattern.  That is, replace the end of the given
beat-string phrase with a fill.  The fill is given as the first
argument and should be a coderef that returns a hashref.  The default
is a three-note, eighth-note snare fill.

=head2 set_time_sig

  $d->set_time_sig;
  $d->set_time_sig('5/4');
  $d->set_time_sig( '5/4', 0 );

Add a time signature event to the score, and reset the B<beats> and
B<divisions> object attributes.

If a ratio argument is given, set the B<signature> object attribute to
it.  If the 2nd argument flag is C<0>, the B<beats> and B<divisions>
are B<not> reset.

=head2 write

Output the score as a MIDI file with the module L</file> attribute as
the file name.

=head2 timidity_cfg

  $timidity_conf = $d->timidity_cfg;
  $d->timidity_cfg($config_file);

Return a timidity.cfg paragraph to use a defined B<soundfont>
attribute. If a B<config_file> is given, the timidity configuration is
written to that file.

=head2 play_with_timidity

  $d->play_with_timidity;
  $d->play_with_timidity($config_file);

Play the score with C<timidity>.

If there is a B<soundfont> attribute, either the given B<config_file>
or C<timidity-midi-util.cfg> is used for the timidity configuration.
If a soundfont is not defined, a timidity configuration file is not
rendered.

See L<MIDI::Util/play_timidity> for more details.

=head2 play_with_fluidsynth

  $d->play_with_fluidsynth;
  $d->play_with_fluidsynth(\@config);

Play the score with C<fluidsynth>.

See L<MIDI::Util/play_fluidsynth> for more details.

=head1 NOTE ATTRIBUTES

Any of these attributes may be changed when calling L</new>.
Drumkit values must be a valid
L<Types::MIDI/PercussionNote>,
while note duration values must be a valid
L<MIDI::Drummer::Tiny/Duration>.

=head2 DRUMKIT

=head3 metronome

=over

=item click, bell

=back

=head3 hi-hats

=over

=item open_hh, closed_hh, pedal_hh

=back

=head3 crash and splash cymbals

=over

=item crash1, crash2, splash, china

=back

=head3 ride cymbals

=over

=item ride1, ride2, ride_bell

=back

=head3 snare drums and handclaps

=over

=item snare, acoustic_snare, electric_snare, side_stick, clap

Where the B<snare> is by default the same as the B<acoustic_snare> but
can be overridden with the B<electric_snare> (C<40>).

=back

=head3 tom-toms

=over

=item hi_tom, hi_mid_tom, low_mid_tom, low_tom, hi_floor_tom, low_floor_tom

=back

=head3 bass drums

=over

=item kick, acoustic_bass, electric_bass

Where the B<kick> is by default the same as the B<acoustic_bass> but
can be overridden with the B<electric_bass> (C<36>).

=back

=head3 auxiliary percussion

=over

=item tambourine, cowbell, vibraslap

=back

=head3 Latin and African drums

=over

=item hi_bongo, low_bongo, mute_hi_conga, open_hi_conga, low_conga, high_timbale, low_timbale

=back

=head3 Latin and African auxiliary percussion

=over

=item high_agogo, low_agogo, cabasa, maracas, short_whistle, long_whistle, short_guiro, long_guiro, claves, hi_wood_block, low_wood_block, mute_cuica, open_cuica

=back

=head3 triangles

=over

=item mute_triangle, open_triangle

=back

=head2 DURATIONS

=head3 whole notes

=over

=item whole, triplet_whole, dotted_whole, double_dotted_whole

=back

=head3 half notes

=over

=item half, triplet_half, dotted_half, double_dotted_half

=back

=head3 quarter notes

=over

=item quarter, triplet_quarter, dotted_quarter, double_dotted_quarter

=back

=head3 eighth notes

=over

=item eighth, triplet_eighth, dotted_eighth, double_dotted_eighth

=back

=head3 sixteenth notes

=over

=item sixteenth, triplet_sixteenth, dotted_sixteenth, double_dotted_sixteenth

=back

=head3 thirty-secondth notes

=over

=item thirtysecond, triplet_thirtysecond, dotted_thirtysecond, double_dotted_thirtysecond

=back

=head3 sixty-fourth notes

=over

=item sixtyfourth, triplet_sixtyfourth, dotted_sixtyfourth, double_dotted_sixtyfourth

=back

=head3 one-twenty-eighth notes

=over

=item onetwentyeighth, triplet_onetwentyeighth, dotted_onetwentyeighth, double_dotted_onetwentyeighth

=back

=for Pod::Coverage BUILD

=head1 SEE ALSO

The F<t/*> test file and the F<eg/*> programs in this distribution.

Also F<eg/drum-fills-advanced> in the L<Music::Duration::Partition>
distribution.

L<https://ology.github.io/midi-drummer-tiny-tutorial/>

L<Data::Dumper::Compact>

L<List::Util>

L<Math::Bezier>

L<MIDI::Util>

L<Moo>

L<Music::Duration>

L<Music::RhythmSet::Util>

L<https://en.wikipedia.org/wiki/General_MIDI#Percussion>

L<https://en.wikipedia.org/wiki/General_MIDI_Level_2#Drum_sounds>

=head1 THANK YOU

L<Mark Gardner|https://metacpan.org/author/MJGARDNER> -
refactoring-master - modernized everything under the hood, post-0.5013.

Woo!

=head1 AUTHOR

Gene Boggs <gene.boggs@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014-2025 by Gene Boggs.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
