package MIDI::Bassline::Walk;
our $AUTHORITY = 'cpan:GENE';

# ABSTRACT: Generate walking basslines

our $VERSION = '0.0101';

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


has intervals => (
    is  => 'ro',
    isa => sub { die 'not an array reference' unless ref $_[0] eq 'ARRAY' },
    default => sub { [qw(-3 -2 -1 1 2 3)] },
);


has octave => (
    is  => 'ro',
    isa => sub { die 'not a positive integer' unless $_[0] =~ /^\d+$/ },
    default => sub { 2 },
);


has verbose => (
    is  => 'ro',
    isa => sub { die 'not a boolean' unless $_[0] =~ /^[01]$/ },
    default => sub { 0 },
);


sub generate {
    my ($self, $chord, $num) = @_;

    $chord ||= 'C';
    $num ||= 4;

    my $scale = $chord =~ /^[A-G][#b]?m/ ? 'minor' : 'major';

    # Parse the chord
    my $chord_note;
    my $flavor;
    if ($chord =~ /^([A-G][#b]?)(.*)$/) {
        $chord_note = $1;
        $flavor = $2;
    }

    my $cn = Music::Chord::Note->new;

    my @notes = $cn->chord_with_octave($chord, $self->octave);

    my @pitches = get_scale_MIDI($chord_note, $self->octave, $scale);

    # Add unique chord notes to the pitches
    my @named = map { Music::Note->new($_, 'midinum')->format('ISO') } @pitches;
    for my $n (@notes) {
        if (not any { $_ eq $n } @named) {
            my $x = Music::Note->new($n, 'ISO')->format('midinum');
            push @pitches, $x;
            print "$chord ADDS: $n\n" if $self->verbose;
        }
    }
    @pitches = sort { $a <=> $b } @pitches; # Pitches are midi numbers

    # Determine if we should skip certain notes given the chord flavor
    my @tones = get_scale_notes($chord_note, $scale);
    print "SCALE: ",ddc(\@tones) if $self->verbose;
    my @fixed;
    for my $p (@pitches) {
        my $x = Music::Note->new($p, 'midinum')->format('isobase');
        if (
            ($flavor =~ /5/ && $x eq $tones[4])
            ||
            ($flavor =~ /7/ && $x eq $tones[6])
            ||
            ($flavor =~ /[#b]9/ && $x eq $tones[1])
        ) {
            print "DROP: $x\n" if $self->verbose;
            next;
        }
        push @fixed, $p;
    }

    # Debugging:
    @named = map { Music::Note->new($_, 'midinum')->format('ISO') } @fixed;
    print "NOTES: ",ddc(\@named) if $self->verbose;

    my $voice = Music::VoiceGen->new(
        pitches   => \@fixed,
        intervals => $self->intervals,
    );

    # Try to start in the middle of the range
    $voice->context($fixed[int @fixed / 2]);

    # Choose Or Die!!
    my @chosen = map { $voice->rand } 1 .. $num;;

    # Show them what they've won, Bob!
    @named = map { Music::Note->new($_, 'midinum')->format('ISO') } @chosen;
    print "CHOSEN: $chord: ",ddc(\@named) if $self->verbose;

    return \@chosen;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MIDI::Bassline::Walk - Generate walking basslines

=head1 VERSION

version 0.0101

=head1 SYNOPSIS

  use MIDI::Bassline::Walk;

  my $bassline = MIDI::Bassline::Walk->new(verbose => 1);

  my $notes = $bassline->generate('C7b5', 4);

  # MIDI:
  # $score->n('qn', $_) for @$notes;

=head1 DESCRIPTION

C<MIDI::Bassline::Walk> generates randomized, walking basslines.

=head1 ATTRIBUTES

=head2 intervals

  $verbose = $bassline->intervals;

Allowed intervals passed to L<Music::VoiceGen>.

Default: C<-3 -2 -1 1 2 3>

=head2 octave

  $octave = $bassline->octave;

Lowest MIDI octave.

Default: C<2>

=head2 verbose

  $verbose = $bassline->verbose;

Show progress.

Default: C<0>

=head1 METHODS

=head2 new

  $bassline = MIDI::Bassline::Walk->new(
      intervals => $intervals,
      octave    => $octave,
      verbose   => $verbose,
  );

Create a new C<MIDI::Bassline::Walk> object.

=head2 generate

  $notes = $bassline->generate;
  $notes = $bassline->generate($chord, $n);

Generate B<n> MIDI pitch numbers given the given B<chord>.

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
