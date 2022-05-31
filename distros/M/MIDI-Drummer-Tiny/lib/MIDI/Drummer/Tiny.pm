package MIDI::Drummer::Tiny;
our $AUTHORITY = 'cpan:GENE';

# ABSTRACT: Glorified metronome

our $VERSION = '0.4001';

use Data::Dumper::Compact qw(ddc);
use List::Util qw(sum0);
use Math::Bezier ();
use MIDI::Util qw(dura_size reverse_dump set_chan_patch set_time_signature);
use Music::Duration;
use Music::RhythmSet::Util qw(upsize);

use Moo;
use strictures 2;
use namespace::clean;

use constant TICKS => 96; # Per quarter note


sub BUILD {
    my ( $self, $args ) = @_;

    $self->score->noop( 'c' . $self->channel, 'V' . $self->volume );

    if ($self->kit) {
      $self->score->control_change($self->channel, 0, 120);
      $self->score->patch_change($self->channel, $self->kit)
    }

    $self->score->set_tempo( int( 60_000_000 / $self->bpm ) );

    $self->score->control_change($self->channel, 91, $self->reverb);

    # Add a TS to the score but don't reset the beats if given
    $self->set_time_sig( $self->signature, !$args->{beats} );
}


has verbose   => ( is => 'ro', default => sub { 0 } );
has kit       => ( is => 'ro', default => sub { 0 } );
has reverb    => ( is => 'ro', default => sub { 15 } );
has channel   => ( is => 'ro', default => sub { 9 } );
has volume    => ( is => 'ro', default => sub { 100 } );
has bpm       => ( is => 'ro', default => sub { 120 } );
has file      => ( is => 'ro', default => sub { 'MIDI-Drummer.mid' } );
has bars      => ( is => 'ro', default => sub { 4 } );
has score     => ( is => 'ro', default => sub { MIDI::Simple->new_score } );
has signature => ( is => 'rw', default => sub { '4/4' });
has beats     => ( is => 'rw', default => sub { 4 }  );
has divisions => ( is => 'rw', default => sub { 4 } );
has counter   => ( is => 'rw', default => sub { 0 } );


has click          => ( is => 'ro', default => sub { 33 } );
has bell           => ( is => 'ro', default => sub { 34 } );
has kick           => ( is => 'ro', default => sub { 35 } ); # Alt: 36
has acoustic_bass  => ( is => 'ro', default => sub { 35 } );
has electric_bass  => ( is => 'ro', default => sub { 36 } );
has side_stick     => ( is => 'ro', default => sub { 37 } );
has snare          => ( is => 'ro', default => sub { 38 } ); # Alt: 40
has acoustic_snare => ( is => 'ro', default => sub { 38 } );
has electric_snare => ( is => 'ro', default => sub { 40 } );
has clap           => ( is => 'ro', default => sub { 39 } );
has open_hh        => ( is => 'ro', default => sub { 46 } );
has closed_hh      => ( is => 'ro', default => sub { 42 } );
has pedal_hh       => ( is => 'ro', default => sub { 44 } );
has crash1         => ( is => 'ro', default => sub { 49 } );
has crash2         => ( is => 'ro', default => sub { 57 } );
has splash         => ( is => 'ro', default => sub { 55 } );
has china          => ( is => 'ro', default => sub { 52 } );
has ride1          => ( is => 'ro', default => sub { 51 } );
has ride2          => ( is => 'ro', default => sub { 59 } );
has ride_bell      => ( is => 'ro', default => sub { 53 } );
has hi_tom         => ( is => 'ro', default => sub { 50 } );
has hi_mid_tom     => ( is => 'ro', default => sub { 48 } );
has low_mid_tom    => ( is => 'ro', default => sub { 47 } );
has low_tom        => ( is => 'ro', default => sub { 45 } );
has hi_floor_tom   => ( is => 'ro', default => sub { 43 } );
has low_floor_tom  => ( is => 'ro', default => sub { 41 } );
has tambourine     => ( is => 'ro', default => sub { 54 } );
has cowbell        => ( is => 'ro', default => sub { 56 } );
has vibraslap      => ( is => 'ro', default => sub { 58 } );
has hi_bongo       => ( is => 'ro', default => sub { 60 } );
has low_bongo      => ( is => 'ro', default => sub { 61 } );
has mute_hi_conga  => ( is => 'ro', default => sub { 62 } );
has open_hi_conga  => ( is => 'ro', default => sub { 63 } );
has low_conga      => ( is => 'ro', default => sub { 64 } );
has high_timbale   => ( is => 'ro', default => sub { 65 } );
has low_timbale    => ( is => 'ro', default => sub { 66 } );
has high_agogo     => ( is => 'ro', default => sub { 67 } );
has low_agogo      => ( is => 'ro', default => sub { 68 } );
has cabasa         => ( is => 'ro', default => sub { 69 } );
has maracas        => ( is => 'ro', default => sub { 70 } );
has short_whistle  => ( is => 'ro', default => sub { 71 } );
has long_whistle   => ( is => 'ro', default => sub { 72 } );
has short_guiro    => ( is => 'ro', default => sub { 73 } );
has long_guiro     => ( is => 'ro', default => sub { 74 } );
has claves         => ( is => 'ro', default => sub { 75 } );
has hi_wood_block  => ( is => 'ro', default => sub { 76 } );
has low_wood_block => ( is => 'ro', default => sub { 77 } );
has mute_cuica     => ( is => 'ro', default => sub { 78 } );
has open_cuica     => ( is => 'ro', default => sub { 79 } );
has mute_triangle  => ( is => 'ro', default => sub { 80 } );
has open_triangle  => ( is => 'ro', default => sub { 81 } );


has whole                         => (is => 'ro', default => sub { 'wn' });
has triplet_whole                 => (is => 'ro', default => sub { 'twn' });
has dotted_whole                  => (is => 'ro', default => sub { 'dwn' });
has double_dotted_whole           => (is => 'ro', default => sub { 'ddwn' });
has half                          => (is => 'ro', default => sub { 'hn' });
has triplet_half                  => (is => 'ro', default => sub { 'thn' });
has dotted_half                   => (is => 'ro', default => sub { 'dhn' });
has double_dotted_half            => (is => 'ro', default => sub { 'ddhn' });
has quarter                       => (is => 'ro', default => sub { 'qn' });
has triplet_quarter               => (is => 'ro', default => sub { 'tqn' });
has dotted_quarter                => (is => 'ro', default => sub { 'dqn' });
has double_dotted_quarter         => (is => 'ro', default => sub { 'ddqn' });
has eighth                        => (is => 'ro', default => sub { 'en' });
has triplet_eighth                => (is => 'ro', default => sub { 'ten' });
has dotted_eighth                 => (is => 'ro', default => sub { 'den' });
has double_dotted_eighth          => (is => 'ro', default => sub { 'dden' });
has sixteenth                     => (is => 'ro', default => sub { 'sn' });
has triplet_sixteenth             => (is => 'ro', default => sub { 'tsn' });
has dotted_sixteenth              => (is => 'ro', default => sub { 'dsn' });
has double_dotted_sixteenth       => (is => 'ro', default => sub { 'ddsn' });
has thirtysecond                  => (is => 'ro', default => sub { 'xn' });
has triplet_thirtysecond          => (is => 'ro', default => sub { 'txn' });
has dotted_thirtysecond           => (is => 'ro', default => sub { 'dxn' });
has double_dotted_thirtysecond    => (is => 'ro', default => sub { 'ddxn' });
has sixtyfourth                   => (is => 'ro', default => sub { 'yn' });
has triplet_sixtyfourth           => (is => 'ro', default => sub { 'tyn' });
has dotted_sixtyfourth            => (is => 'ro', default => sub { 'dyn' });
has double_dotted_sixtyfourth     => (is => 'ro', default => sub { 'ddyn' });
has onetwentyeighth               => (is => 'ro', default => sub { 'zn' });
has triplet_onetwentyeighth       => (is => 'ro', default => sub { 'tzn' });
has dotted_onetwentyeighth        => (is => 'ro', default => sub { 'dzn' });
has double_dotted_onetwentyeighth => (is => 'ro', default => sub { 'ddzn' });


sub note { return shift->score->n(@_) }


sub accent_note {
    my $self = shift;
    my $accent = shift;
    my $resume = $self->score->Volume;
    $self->score->Volume($accent);
    $self->note(@_);
    $self->score->Volume($resume);
}


sub rest { return shift->score->r(@_) }


sub count_in {
    my $self = shift;
    my $bars = shift || $self->bars;
    for my $i ( 1 .. $self->beats * $bars ) {
        $self->note( $self->quarter, $self->closed_hh );
    }
}


sub metronome38 {
    my $self = shift;
    my $bars = shift || $self->bars;

    for ( 1 .. $bars ) {
        $self->note( $self->eighth, $self->closed_hh, $self->kick );
        $self->note( $self->eighth, $self->closed_hh);
        $self->note( $self->eighth, $self->closed_hh, $self->snare );
    }
}


sub metronome34 {
    my $self = shift;
    my $bars = shift || $self->bars;

    for ( 1 .. $bars ) {
        $self->note( $self->quarter, $self->ride1, $self->kick );
        $self->note( $self->quarter, $self->ride1 );
        $self->note( $self->quarter, $self->ride1, $self->snare );
    }
}


sub metronome44 {
    my $self = shift;
    my $bars = shift || $self->bars;
    my $flag = shift // 0;

    my $i = 0;

    for my $n ( 1 .. $self->beats * $bars ) {
        if ( $n % 2 == 0 )
        {
            $self->note( $self->quarter, $self->closed_hh, $self->snare );
        }
        else {
            if ( $flag == 0 )
            {
                $self->note( $self->quarter, $self->closed_hh, $self->kick );
            }
            else
            {
                if ( $i % 2 == 0 )
                {
                    $self->note( $self->quarter, $self->closed_hh, $self->kick );
                }
                else
                {
                    $self->note( $self->eighth, $self->closed_hh, $self->kick );
                    $self->note( $self->eighth, $self->kick );
                }
            }

            $i++;
        }
    }
}


sub metronome44swing {
    my $self = shift;
    my $bars = shift || $self->bars;

    for my $n ( 1 .. $bars ) {
        $self->note( $self->quarter,          $self->ride1, $self->kick );
        $self->note( $self->triplet_eighth,   $self->ride1 );
        $self->rest( $self->triplet_eighth );
        $self->note( $self->triplet_eighth,   $self->ride1, $self->kick );
        $self->note( $self->quarter,          $self->ride1, $self->snare );
        $self->note( $self->triplet_eighth,   $self->ride1, $self->kick );
        $self->rest( $self->triplet_eighth );
        $self->note( $self->triplet_eighth,   $self->ride1 );
    }
}


sub metronome54 {
    my $self = shift;
    my $bars = shift || $self->bars;
    for my $n (1 .. $bars) {
        $self->note($self->quarter, $self->closed_hh, $self->kick);
        $self->note($self->quarter, $self->closed_hh);
        $self->note($self->quarter, $self->closed_hh, $self->snare);
        $self->note($self->quarter, $self->closed_hh);
        if ($n % 2) {
            $self->note($self->quarter, $self->closed_hh);
        }
        else {
            $self->note($self->eighth, $self->closed_hh);
            $self->note($self->eighth, $self->kick);
        }
    }
}


sub metronome58 {
    my $self = shift;
    my $bars = shift || $self->bars;
    for my $n (1 .. $bars) {
        $self->note($self->eighth, $self->closed_hh, $self->kick);
        $self->note($self->eighth, $self->closed_hh);
        $self->note($self->eighth, $self->closed_hh, $self->snare);
        $self->note($self->eighth, $self->closed_hh);
        $self->note($self->eighth, $self->closed_hh);
    }
}


sub metronome68 {
    my $self = shift;
    my $bars = shift || $self->bars;
    for my $n (1 .. $bars) {
        $self->note($self->eighth, $self->closed_hh, $self->kick);
        $self->note($self->eighth, $self->closed_hh);
        $self->note($self->eighth, $self->closed_hh);
        $self->note($self->eighth, $self->closed_hh, $self->snare);
        $self->note($self->eighth, $self->closed_hh);
        $self->note($self->eighth, $self->closed_hh);
    }
}


sub metronome74 {
    my $self = shift;
    my $bars = shift || $self->bars;
    for my $n (1 .. $bars) {
        $self->note($self->quarter, $self->closed_hh, $self->kick);
        $self->note($self->quarter, $self->closed_hh);
        $self->note($self->quarter, $self->closed_hh, $self->snare);
        $self->note($self->eighth, $self->closed_hh);
        $self->note($self->eighth, $self->kick);
        $self->note($self->quarter, $self->closed_hh, $self->kick);
        $self->note($self->quarter, $self->closed_hh, $self->snare);
        $self->note($self->quarter, $self->closed_hh);
    }
}


sub metronome78 {
    my $self = shift;
    my $bars = shift || $self->bars;
    for my $n (1 .. $bars) {
        $self->note($self->eighth, $self->closed_hh, $self->kick);
        $self->note($self->eighth, $self->closed_hh);
        $self->note($self->eighth, $self->closed_hh);
        $self->note($self->eighth, $self->closed_hh, $self->kick);
        $self->note($self->eighth, $self->closed_hh, $self->snare);
        $self->note($self->eighth, $self->closed_hh);
        $self->note($self->eighth, $self->closed_hh);
    }
}


sub flam {
    my ($self, $spec, $patch) = @_;
    $patch ||= $self->snare;
    my $x = $MIDI::Simple::Length{$spec};
    my $y = $MIDI::Simple::Length{ $self->sixtyfourth };
    my $z = sprintf '%0.f', ($x - $y) * TICKS;
    my $accent = sprintf '%0.f', $self->score->Volume / 2;
    $self->accent_note($accent, $self->sixtyfourth, $patch);
    $self->note('d' . $z, $patch);
}


sub roll {
    my ($self, $length, $spec, $patch) = @_;
    $patch ||= $self->snare;
    my $x = $MIDI::Simple::Length{$length};
    my $y = $MIDI::Simple::Length{$spec};
    my $z = sprintf '%0.f', $x / $y;
    $self->note($spec, $patch) for 1 .. $z;
}


sub crescendo_roll {
    my ($self, $span, $length, $spec, $patch) = @_;
    $patch ||= $self->snare;
    my ($i, $j, $k) = @$span;
    my $x = $MIDI::Simple::Length{$length};
    my $y = $MIDI::Simple::Length{$spec};
    my $z = sprintf '%0.f', $x / $y;
    if ($k) {
        my $bezier = Math::Bezier->new(
            1, $i,
            $z, $i,
            $z, $j,
        );
        for (my $n = 0; $n <= 1; $n += (1 / ($z - 1))) {
            my (undef, $v) = $bezier->point($n);
            $v = sprintf '%0.f', $v;
#            warn(__PACKAGE__,' ',__LINE__," $n INC: $v\n");
            $self->accent_note($v, $spec, $patch);
        }
    }
    else {
        my $v = sprintf '%0.f', ($j - $i) / ($z - 1);
#        warn(__PACKAGE__,' ',__LINE__," VALUE: $v\n");
        for my $n (1 .. $z) {
            if ($n == $z) {
                if ($i < $j) {
                    $i += $j - $i;
                }
                elsif ($i > $j) {
                    $i -= $i - $j;
                }
            }
#            warn(__PACKAGE__,' ',__LINE__," $n INC: $i\n");
            $self->accent_note($i, $spec, $patch);
            $i += $v;
        }
    }
}


sub pattern {
    my ( $self, %args ) = @_;

    $args{instrument} ||= $self->snare;
    $args{patterns}   ||= [];
    $args{beats}      ||= $self->beats;
    $args{negate}     ||= 0;
    $args{count}      ||= 0;
    $args{repeat}     ||= 1;

    return unless @{ $args{patterns} };

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
        1 => sub { $self->note( $args{duration}, $args{instrument} ) },
    };

    set_chan_patch( $self->score, $self->channel, $args{instrument} );

    for my $pattern (@{ $args{patterns} }) {
        next if $pattern =~ /^0+$/;

        $pattern =~ tr/01/10/ if $args{negate};

        for ( 1 .. $args{repeat} ) {
            for my $bit ( split //, $pattern ) {
                $args{vary}{$bit}->($self);
                $self->counter( $self->counter + $size ) if $args{count};
            }
        }
    }
}


sub sync_patterns {
    my ($self, %patterns) = @_;

    my @subs;
    for my $instrument (keys %patterns) {
        push @subs, sub {
            $self->pattern(
                instrument => $instrument,
                patterns   => $patterns{$instrument},
            );
        },
    }

    $self->sync(@subs);
}


sub add_fill {
    my ($self, $fill, %patterns) = @_;

    $fill ||= sub {
        return {
            duration       => 8,
            $self->open_hh => '000',
            $self->snare   => '111',
            $self->kick    => '000',
        };
    };
    my $fill_patterns = $fill->($self);
    print 'Fill: ', ddc($fill_patterns) if $self->verbose;
    my $fill_duration = delete $fill_patterns->{duration} || 8;
    my $fill_length   = length((values %$fill_patterns)[0]);

    my %lengths;
    for my $instrument (keys %patterns) {
        $lengths{$instrument} = sum0 map { length $_ } @{ $patterns{$instrument} };
    }

    my $lcm = _multilcm($fill_duration, values %lengths);
    print "LCM: $lcm\n" if $self->verbose;

    my $fill_chop = $fill_duration == $lcm
        ? $fill_length
        : int $lcm / $fill_length + 1;
    print "FC: $fill_chop\n" if $self->verbose;

    my %fresh_patterns;
    for my $instrument (keys %patterns) {
        # get a single "flattened" pattern as an arrayref
        my $pattern = [ map { split //, $_ } @{ $patterns{$instrument} } ];
        # the fresh pattern is possibly upsized with the LCM
        $fresh_patterns{$instrument} = @$pattern < $lcm
            ? [ join '', @{ upsize($pattern, $lcm) } ]
            : [ join '', @$pattern ];
    }
    print 'Patterns: ', ddc(\%fresh_patterns) if $self->verbose;

    my %replacement;
    for my $instrument (keys %$fill_patterns) {
        # get a single "flattened" pattern as a zero-pre-padded arrayref
        my $pattern = [ split //, sprintf '%0*s', $fill_duration, $fill_patterns->{$instrument} ];
        # the fresh pattern string is possibly upsized with the LCM
        my $fresh = @$pattern < $lcm
            ? join '', @{ upsize($pattern, $lcm) }
            : join '', @$pattern;
        # the replacement string is the tail of the fresh pattern string
        $replacement{$instrument} = substr $fresh, -$fill_chop;
    }
    print 'Replacements: ', ddc(\%replacement) if $self->verbose;

    my %replaced;
    for my $instrument (keys %fresh_patterns) {
        # get the string to replace
        my $string = join '', @{ $fresh_patterns{$instrument} };
        # replace the tail of the string
        my $pos = length $replacement{$instrument};
        substr $string, -$pos, $pos, $replacement{$instrument};
        print "$instrument: $string\n" if $self->verbose;
        # prepare the replaced pattern for syncing
        $replaced{$instrument} = [ $string ];
    }

    $self->sync_patterns(%replaced);
}


sub set_time_sig {
    my ($self, $signature, $set) = @_;
    $self->signature($signature) if $signature;
    $set //= 1;
    if ($set) {
        my ($beats, $divisions) = split /\//, $self->signature;
        $self->beats($beats);
        $self->divisions($divisions);
    }
    set_time_signature($self->score, $self->signature);
}


sub sync {
    my $self = shift;
    $self->score->synch(@_);
}


sub write {
    my $self = shift;
    $self->score->write_score( $self->file );
}

# lifted from https://www.perlmonks.org/?node_id=56906
sub _gcf {
    my ($x, $y) = @_;
    ($x, $y) = ($y, $x % $y) while $y;
    return $x;
}
sub _lcm {
    return($_[0] * $_[1] / _gcf($_[0], $_[1]));
}
sub _multilcm {
    my $x = shift;
    $x = _lcm($x, shift) while @_;
    return $x;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MIDI::Drummer::Tiny - Glorified metronome

=head1 VERSION

version 0.4001

=head1 SYNOPSIS

 use MIDI::Drummer::Tiny;

 my $d = MIDI::Drummer::Tiny->new(
    file      => 'drums.mid',
    bpm       => 100,
    volume    => 100,
    signature => '5/4',
    bars      => 8,
    reverb    => 0,
    kit       => 25, # TR-808 if using GM Level 2
    #kick  => 36, # Override default patch
    #snare => 40, # "
 );

 $d->count_in(1);  # Closed hi-hat for 1 bar

 $d->metronome54;  # 5/4 time for the number of bars

 $d->rest($d->whole);

 $d->set_time_sig('4/4');

 $d->metronome44(3);  # 4/4 time for 3 bars

 $d->flam($d->quarter, $d->snare);
 $d->crescendo_roll([50, 127, 1], $d->eighth, $d->thirtysecond);
 $d->note($d->sixteenth, $d->crash1);
 $d->accent_note(127, $d->sixteenth, $d->crash2);

 # Alternate kick and snare
 $d->note($d->quarter, $d->open_hh, $_ % 2 ? $d->kick : $d->snare)
    for 1 .. $d->beats * $d->bars;

 # Same but with beat-strings:
 $d->sync_patterns(
    $d->open_hh => [ ('1111') x $d->bars ],
    $d->snare   => [ ('0101') x $d->bars ],
    $d->kick    => [ ('1010') x $d->bars ],
 );

 $d->write;

=head1 DESCRIPTION

This module provides handy defaults and tools to produce a MIDI score
with drum parts.

Below, the term "spec" refers to a note length duration, like an
eighth or quarter note, for instance.

=for Pod::Coverage BUILD

=head1 ATTRIBUTES

=head2 verbose

Default: C<0>

=head2 file

Default: C<MIDI-Drummer.mid>

=head2 score

Default: C<MIDI::Simple-E<gt>new_score>

=head2 kit

Default: C<1> (Standard)

If you are going to play the MIDI file with a "General MIDI Level 2"
soundfont, you can change kits.

   8: Room
  16: Power
  24: Electronic
  25: TR-808
  26: ?
  32: Jazz
  40: Brush
  48: Orchestra

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

=head2 counter

  $d->counter( $d->counter + $duration );
  $count = $d->counter;

Beat counter of durations, where a quarter-note is equal to 1. An
eighth-note is 0.5, etc.

=head1 KIT

=over 4

=item click, bell (metronome)

=item open_hh, closed_hh, pedal_hh

=item crash1, crash2, splash, china

=item ride1, ride2, ride_bell

=item snare, acoustic_snare, electric_snare, side_stick, clap

Where the B<snare> is by default the same as the B<acoustic_snare> but
can be overridden with the B<electric_snare> (C<'n40'>).

=item hi_tom, hi_mid_tom, low_mid_tom, low_tom, hi_floor_tom, low_floor_tom

=item kick, acoustic_bass, electric_bass

Where the B<kick> is by default the same as the B<acoustic_bass> but
can be overridden with the B<electric_bass> (C<'n36'>).

=item tambourine, cowbell, vibraslap

=item hi_bongo, low_bongo, mute_hi_conga, open_hi_conga, low_conga, high_timbale, low_timbale

=item high_agogo, low_agogo, cabasa, maracas, short_whistle, long_whistle, short_guiro, long_guiro, claves, hi_wood_block, low_wood_block, mute_cuica, open_cuica

=item mute_triangle, open_triangle

=back

=head1 DURATIONS

=over 4

=item whole, triplet_whole, dotted_whole, double_dotted_whole

=item half, triplet_half, dotted_half, double_dotted_half

=item quarter, triplet_quarter, dotted_quarter, double_dotted_quarter

=item eighth, triplet_eighth, dotted_eighth, double_dotted_eighth

=item sixteenth, triplet_sixteenth, dotted_sixteenth, double_dotted_sixteenth

=item thirtysecond, triplet_thirtysecond, dotted_thirtysecond, double_dotted_thirtysecond

=item sixtyfourth, triplet_sixtyfourth, dotted_sixtyfourth, double_dotted_sixtyfourth

=item onetwentyeighth, triplet_onetwentyeighth, dotted_onetwentyeighth, double_dotted_onetwentyeighth

=back

=head1 METHODS

=head2 new

  $d = MIDI::Drummer::Tiny->new(%arguments);

Return a new C<MIDI::Drummer::Tiny> object and add a time signature
event to the score.

=head2 note

 $d->note( $d->quarter, $d->closed_hh, $d->kick );
 $d->note( 'qn', 42, 35 ); # Same thing

Add notes to the score.

This method takes the same arguments as L<MIDI::Simple/"Parameters for n/r/noop">.

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

=head2 count_in

 $d->count_in;
 $d->count_in($bars);

Play the closed hihat for the number of beats times the given bars.
If no bars are given, the default times the number of beats is used.

=head2 metronome38

  $d->metronome38;
  $d->metronome38($bars);

Add a steady 3/8 beat to the score.

=head2 metronome34

  $d->metronome34;
  $d->metronome34($bars);

Add a steady 3/4 beat to the score.

=head2 metronome44

  $d->metronome44;
  $d->metronome44($bars);
  $d->metronome44($bars, $flag);

Add a steady 4/4 beat to the score.

If a B<flag> is provided the beat is modified to include alternating
eighth-note kicks.

=head2 metronome44swing

  $d->metronome44swing;
  $d->metronome44swing($bars);

Add a steady 4/4 swing beat to the score.

=head2 metronome54

  $d->metronome54;
  $d->metronome54($bars);

Add a 5/4 beat to the score.

=head2 metronome58

  $d->metronome58;
  $d->metronome58($bars);

Add a 5/8 beat to the score.

=head2 metronome68

  $d->metronome68;
  $d->metronome68($bars);

Add a 6/8 beat to the score.

=head2 metronome74

  $d->metronome74;
  $d->metronome74($bars);

Add a 7/4 beat to the score.

=head2 metronome78

  $d->metronome78;
  $d->metronome78($bars);

Add a 7/8 beat to the score.

=head2 flam

  $d->flam($spec);
  $d->flam( $spec, $patch );

Add a "flam" to the score, where a ghosted 64th gracenote is played
before the primary note.

If not provided the B<snare> is used for the B<patch>.

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
attribute, if the B<count> option is set.

The B<vary> option is a hashref of coderefs, keyed by single character
tokens, like the digits 0-9.  Each coderef duration should add up to
the given B<duration> option.  The single argument to the coderefs is
the object itself and may be used as: C<my $self = shift;> in yours.

Defaults:

  instrument: snare
  patterns: [] (i.e. empty!)
  Options:
    duration: quarter-note
    beats: given by constructor
    repeat: 1
    count: 0 ( keep track of the beat count)
    negate: 0 (flip the bit values)
    vary:
        0 => sub { $self->rest( $args{duration} ) },
        1 => sub { $self->note( $args{duration}, $args{instrument} ) },

=head2 sync_patterns

  $d->sync_patterns( $instrument1 => $patterns1, $inst2 => $pats2, ... );
  $d->sync_patterns(
      $d->open_hh => [ ('11111111') x $d->bars ],
      $d->snare   => [ ('0101') x $d->bars ],
      $d->kick    => [ ('1010') x $d->bars ],
      ...
  );

Execute the C<pattern> method for multiple voices.

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
      $d->open_hh => [ ('11111111') x $d->bars ],  # example phrase
      $d->snare   => [ ('0101') x $d->bars ],      # "
      $d->kick    => [ ('1010') x $d->bars ],      # "
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

=head2 sync

  $d->sync(@code_refs);

This is a simple pass-through to the B<score> C<synch> method.

This allows simultaneous playing of multiple "tracks" defined by code
references.

=head2 write

Output the score as a MIDI file with the module L</file> attribute as
the file name.

=head1 SEE ALSO

The F<t/*> test file and the F<eg/*> programs in this distribution.
Also F<eg/drum-fills-advanced> in the L<Music::Duration::Partition>
distribution.

L<Math::Bezier>

L<MIDI::Util>

L<Moo>

L<Music::Duration>

L<Music::RhythmSet::Util>

L<https://en.wikipedia.org/wiki/General_MIDI#Percussion>

L<https://en.wikipedia.org/wiki/General_MIDI_Level_2#Drum_sounds>

=head1 AUTHOR

Gene Boggs <gene@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Gene Boggs.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
