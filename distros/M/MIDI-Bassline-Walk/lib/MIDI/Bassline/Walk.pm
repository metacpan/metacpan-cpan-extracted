package MIDI::Bassline::Walk;
our $AUTHORITY = 'cpan:GENE';

# ABSTRACT: Generate walking basslines

our $VERSION = '0.0207';

use Data::Dumper::Compact qw(ddc);
use Carp qw(croak);
use List::Util qw(any);
use Music::Chord::Note;
use Music::Note;
use Music::Scales qw(get_scale_notes get_scale_MIDI);
use Music::VoiceGen;
use Moo;
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


has verbose => (
    is  => 'ro',
    isa => sub { croak 'not a boolean' unless $_[0] =~ /^[01]$/ },
    default => sub { 0 },
);


sub generate {
    my ($self, $chord, $num) = @_;

    $chord ||= 'C';
    $num ||= 4;

    print "CHORD: $chord\n" if $self->verbose;

    my $scale = $self->scale->($chord);

    # Parse the chord
    my $chord_note;
    my $flavor;
    if ($chord =~ /^([A-G][#b]?)(.*)$/) {
        $chord_note = $1;
        $flavor = $2;
    }

    my $cn = Music::Chord::Note->new;

    my @notes = map { Music::Note->new($_, 'ISO')->format('midinum') }
        $cn->chord_with_octave($chord, $self->octave);

    my @pitches = $scale ? get_scale_MIDI($chord_note, $self->octave, $scale) : ();

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
    print "\tSCALE: ",ddc(\@tones) if $self->verbose;
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

    # DEBUGGING:
    my @named;
    if ($self->verbose) {
        @named = map { Music::Note->new($_, 'midinum')->format('ISO') } @fixed;
        print "\tNOTES: ",ddc(\@named);
    }

    my $voice = Music::VoiceGen->new(
        pitches   => \@fixed,
        intervals => $self->intervals,
    );

    # Try to start in the middle of the range
    $voice->context($fixed[int @fixed / 2]);

    # Choose Or Die!!
    my @chosen = map { $voice->rand } 1 .. $num;

    # Show them what they've won, Bob!
    if ($self->verbose) {
        @named = map { Music::Note->new($_, 'midinum')->format('ISO') } @chosen;
        print "\tCHOSEN: ",ddc(\@named);
    }

    return \@chosen;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MIDI::Bassline::Walk - Generate walking basslines

=head1 VERSION

version 0.0207

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

Generate B<n> MIDI pitch numbers given the B<chord>.

Defaults:

  chord: C
  n: 4

=head1 SEE ALSO

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

This software is Copyright (c) 2021 by Gene Boggs.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
