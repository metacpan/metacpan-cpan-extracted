package MIDI::Bassline::Walk;
our $AUTHORITY = 'cpan:GENE';

# ABSTRACT: Generate walking basslines

our $VERSION = '0.0309';

use Data::Dumper::Compact qw(ddc);
use Carp qw(croak);
use List::Util qw(any min uniq);
use Music::Chord::Note;
use Music::Note;
use Music::Scales qw(get_scale_notes get_scale_MIDI);
use Music::VoiceGen;
use Moo;
use Set::Array;
use strictures 2;
use namespace::clean;


has guitar => (
    is  => 'ro',
    isa => sub { croak 'not a boolean' unless $_[0] =~ /^[01]$/ },
    default => sub { 0 },
);


has intervals => (
    is  => 'ro',
    isa => sub { croak 'not an array reference' unless ref $_[0] eq 'ARRAY' },
    default => sub { [qw(-3 -2 -1 1 2 3)] },
);


has octave => (
    is  => 'ro',
    isa => sub { croak 'not a positive integer' unless $_[0] =~ /^\d+$/ },
    default => sub { 2 },
);


has scale => (
    is  => 'ro',
    isa => sub { croak 'not a code reference' unless ref $_[0] eq 'CODE' },
    default => sub { sub { $_[0] =~ /^[A-G][#b]?m/ ? 'minor' : 'major' } },
);


has tonic => (
    is      => 'ro',
    isa     => sub { croak 'not a boolean' unless $_[0] =~ /^[01]$/ },
    default => sub { 0 },
);


has verbose => (
    is  => 'ro',
    isa => sub { croak 'not a boolean' unless $_[0] =~ /^[01]$/ },
    default => sub { 0 },
);


sub generate {
    my ($self, $chord, $num, $next_chord) = @_;

    $chord ||= 'C';
    $num ||= 4;

    print "CHORD: $chord\n" if $self->verbose;
    print "NEXT: $next_chord\n" if $self->verbose && $next_chord;

    my $scale = $self->scale->($chord);
    my $next_scale = defined $next_chord ? $self->scale->($next_chord) : '';

    # Parse the chord
    my $chord_note;
    my $flavor;
    if ($chord =~ /^([A-G][#b]?)(.*)$/) {
        $chord_note = $1;
        $flavor = $2;
    }

    # Parse the next chord
    my $next_chord_note;
    if ($next_chord && $next_chord =~ /^([A-G][#b]?).*$/) {
        $next_chord_note = $1;
    }

    my $cn = Music::Chord::Note->new;

    my @notes = map { Music::Note->new($_, 'ISO')->format('midinum') }
        $cn->chord_with_octave($chord, $self->octave);

    my @pitches = $scale ? get_scale_MIDI($chord_note, $self->octave, $scale) : ();
    my @next_pitches = $next_scale ? get_scale_MIDI($next_chord_note, $self->octave, $next_scale) : ();

    # Add unique chord notes to the pitches
    for my $n (@notes) {
        if (not any { $_ == $n } @pitches) {
            push @pitches, $n;
            if ($self->verbose) {
                my $x = Music::Note->new($n, 'midinum')->format('ISO');
                print "\tADD: $x\n";
            }
        }
    }
    @pitches = sort { $a <=> $b } @pitches; # Pitches are midi numbers

    # Determine if we should skip certain notes given the chord flavor
    my @tones = get_scale_notes($chord_note, $scale);
    print "\tSCALE: ", ddc(\@tones) if $self->verbose;
    my @fixed;
    for my $p (@pitches) {
        my $n = Music::Note->new($p, 'midinum');
        my $x = $n->format('isobase');
        if ($x =~ /#/) {
            $n->en_eq('flat');
        }
        elsif ($x =~ /b/) {
            $n->en_eq('sharp');
        }
        my $y = $n->format('isobase');
        if (($scale eq 'major' || $scale eq 'minor')
            && (
            ($flavor =~ /[#b]5/ && ($x eq $tones[4] || $y eq $tones[4]))
            ||
            ($flavor =~ /7/ && $flavor !~ /[Mm]7/ && ($x eq $tones[6] || $y eq $tones[6]))
            ||
            ($flavor =~ /[#b]9/ && ($x eq $tones[1] || $y eq $tones[1]))
            ||
            ($flavor =~ /dim/ && ($x eq $tones[2] || $y eq $tones[2]))
            ||
            ($flavor =~ /dim/ && ($x eq $tones[6] || $y eq $tones[6]))
            ||
            ($flavor =~ /aug/ && ($x eq $tones[6] || $y eq $tones[6]))
            )
        ) {
            print "\tDROP: $x\n" if $self->verbose;
            next;
        }
        push @fixed, $p;
    }

    if ($self->guitar) {
        @fixed = sort { $a <=> $b } map { $_ < 40 ? $_ + 12 : $_ } @fixed;
    }

    # Make sure there are no duplicate pitches
    @fixed = uniq @fixed;

    _verbose_notes('NOTES', @fixed) if $self->verbose;

    my $voice = Music::VoiceGen->new(
        pitches   => \@fixed,
        intervals => $self->intervals,
    );

    # Try to start the phrase at the beginning of the scale
    $voice->context([$fixed[0]]) if $self->tonic;

    # Get a passage of quasi-random pitches
    my @chosen = map { $voice->rand } 1 .. $num;

    if ($self->tonic) {
        if ($scale eq 'major' || $scale eq 'minor') {
            $chosen[0] = _closest($chosen[1], [ @fixed[0,2,4] ])
        }
        elsif ($scale eq 'pentatonic' || $scale eq 'pminor') {
            $chosen[0] = _closest($chosen[1], [ @fixed[0,1,2] ])
        }
    }

    # Intersect with the next-chord pitches
    if ($next_chord) {
        my $A1 = Set::Array->new(@fixed);
        my $A2 = Set::Array->new(@next_pitches);
        my @intersect = @{ $A1->intersection($A2) };
        _verbose_notes('INTERSECT', @intersect) if $self->verbose;
        # Anticipate the next chord
        if (@intersect) {
            $chosen[-1] = _closest($chosen[-2], \@intersect);
        }
    }

    # Show them what they've won, Bob!
    _verbose_notes('CHOSEN', @chosen) if $self->verbose;

    return \@chosen;
}

# Show a phrase of midinums as ISO notes
sub _verbose_notes {
    my ($title, @notes) = @_;
    @notes = map { Music::Note->new($_, 'midinum')->format('ISO') } @notes;
    print "\t$title: ", ddc(\@notes);
}

# Find the closest absolute difference to the key, in the list
sub _closest {
    my ($key, $list) = @_;
    $list = [ grep { $_ != $key } @$list ];
    my @diff = map { abs($key - $_) } @$list;
    my $min = min @diff;
    my @closest;
    for my $n (0 .. $#diff) {
        next if $diff[$n] != $min;
        push @closest, $list->[$n];
    }
    return $closest[int rand @closest];
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MIDI::Bassline::Walk - Generate walking basslines

=head1 VERSION

version 0.0309

=head1 SYNOPSIS

  use MIDI::Bassline::Walk;

  my $bassline = MIDI::Bassline::Walk->new(verbose => 1);

  my $notes = $bassline->generate('C7b5', 8);

  # MIDI:
  # $score->n('qn', $_) for @$notes;

=head1 DESCRIPTION

C<MIDI::Bassline::Walk> generates randomized, walking basslines.

The "formula" implemented by this module is basically, "play any notes
of the chord-root scale, plus the notes of the chord that may differ,
minus the notes those replaced."

The logic (and music theory) implemented here, can generate some sour
notes.  This is an approximate composition tool, and not a drop-in
bass player.  Import rendered MIDI into a DAW and alter notes until
they sound suitable.

The chords recognized by this module, are those known to
L<Music::Chord::Note>.  Please see the source of that module for the
list.

=head1 ATTRIBUTES

=head2 guitar

  $guitar = $bassline->guitar;

Transpose notes below C<E2> (C<40>) up an octave.

Default: C<0>

=head2 intervals

  $verbose = $bassline->intervals;

Allowed intervals passed to L<Music::VoiceGen>.

Default: C<-3 -2 -1 1 2 3>

=head2 octave

  $octave = $bassline->octave;

Lowest MIDI octave.

Default: C<2>

=head2 scale

  $scale = $bassline->scale;

The musical scale to use, based on a given chord (i.e. C<$_[0]> here).

Default: C<sub { $_[0] =~ /^[A-G][#b]?m/ ? 'minor' : 'major' }>

Alternatives:

  sub { 'chromatic' }

  sub { $_[0] =~ /^[A-G][#b]?m/ ? 'pminor' : 'pentatonic' }

  sub { '' }

The first walks the chromatic scale no matter what the chord.  The
second walks either the major or minor pentatonic scale, plus the
notes of the chord.  The last walks only the notes of the chord (no
scale).

=head2 tonic

  $tonic = $bassline->tonic;

Play one of the first, third or fifth (I, III, V) notes of the scale
on the first note of the generated phrase.

Default: C<0>

=head2 verbose

  $verbose = $bassline->verbose;

Show progress.

Default: C<0>

=head1 METHODS

=head2 new

  $bassline = MIDI::Bassline::Walk->new;
  $bassline = MIDI::Bassline::Walk->new(
      guitar    => $guitar,
      intervals => $intervals,
      octave    => $octave,
      scale     => $scale,
      verbose   => $verbose,
  );

Create a new C<MIDI::Bassline::Walk> object.

=head2 generate

  $notes = $bassline->generate;
  $notes = $bassline->generate($chord, $n);
  $notes = $bassline->generate($chord, $n, $next_chord);

Generate B<n> MIDI pitch numbers given the B<chord>.

If given a B<next_chord>, perform an intersection of the two scales,
and replace the final note of the generated phrase with a note of the
intersection, if there are notes in common.

Defaults:

  chord: C
  n: 4
  next_chord: undef

=head1 SEE ALSO

The F<t/> and F<eg/> programs

L<Data::Dumper::Compact>

L<Carp>

L<List::Util>

L<Music::Chord::Note>

L<Music::Note>

L<Music::Scales>

L<Music::VoiceGen>

L<Moo>

L<strictures>

L<namespace::clean>

=head1 AUTHOR

Gene Boggs <gene@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2022 by Gene Boggs.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
