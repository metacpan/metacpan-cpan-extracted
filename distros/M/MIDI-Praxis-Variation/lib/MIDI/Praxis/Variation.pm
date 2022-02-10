package MIDI::Praxis::Variation;
our $AUTHORITY = 'cpan:GENE';

# ABSTRACT: Variation techniques used in music composition

use strict;
use warnings;

our $VERSION = '0.0607';

use MIDI::Simple ();

use Exporter 'import';

our @EXPORT = qw(
    augmentation
    diminution
    dur
    inversion
    note_name_to_number
    note2num
    ntup
    original
    notes2nums
    raugmentation
    rdiminution
    retrograde
    retrograde_inversion
    transposition
    tye
    tie_durations
);
our %EXPORT_TAGS = (all => [qw(
    augmentation
    diminution
    dur
    inversion
    note_name_to_number
    note2num
    ntup
    original
    notes2nums
    raugmentation
    rdiminution
    retrograde
    retrograde_inversion
    transposition
    tye
    tie_durations
)] );


sub note2num { note_name_to_number(@_) }

sub note_name_to_number {
    my ($in) = @_;

    return () unless $in;

    my $note_number = -1;

    if ($in =~ /^([A-Za-z]+)(\d+)/s) {
        $note_number = $MIDI::Simple::Note{$1} + $2 * 12
          if exists $MIDI::Simple::Note{$1};
    }

    return $note_number;
}



sub notes2nums { original(@_) }

sub original {
    my @notes = @_;

    return () unless @notes;

    my @ret = map { note_name_to_number($_) } @notes;

    return @ret;
}



sub retrograde {
    my @notes =  @_;

    my @ret = ();

    return () unless @notes;

    @ret = reverse original(@notes);

    return @ret;
}



sub transposition {
    my ($delta, @notes) = @_;

    return () unless defined $delta && @notes;

    my @ret = ();

    if ($notes[0] =~ /[A-G]/) {
        @ret = original(@notes);
    }
    else {
        @ret = @notes;
    }

    for (@ret) {
        $_ += $delta;
    }

    return @ret;
}



sub inversion {
    my ($axis, @notes) = @_;

    return () unless $axis && @notes;

    my $center = note_name_to_number($axis);
    my $first  = note_name_to_number($notes[0]);
    my $delta  = $center - $first;

    my @transposed = transposition($delta, @notes);

    # XXX WTF?
    my @ret = map { 2 * $center - $_ } @transposed;

    return @ret;
}



sub retrograde_inversion {
    my ($axis, @notes) = @_;

    return () unless $axis && @notes;

    my @rev_notes = ();
    my @ret = ();

    @rev_notes = reverse @notes;

    @ret = inversion($axis, @rev_notes);

    return @ret;
}



sub dur {
    my ($tempo, $arg) = (MIDI::Simple::Tempo, @_);

    return () unless $arg;

    my $dur = 0;

    if ($arg =~ /^d(\d+)$/) {
        $dur = 0 + $1;
    }
    elsif (exists $MIDI::Simple::Length{$arg}) {   # length spec
        $dur = 0 + ($tempo * $MIDI::Simple::Length{$arg});
    }

    return $dur;
}



sub tie_durations { tye(@_) }

sub tye {
    my @dur_or_len = @_;

    return () unless @dur_or_len;

    my $sum = 0;

    for my $dura (@dur_or_len) {
        $sum += dur($dura);
    }

    return $sum;
}



sub raugmentation {
    my ($ratio, @dur_or_len) = @_;

    return () unless $ratio && 1 < $ratio && @dur_or_len;

    my $sum = 0;

    for my $dura (@dur_or_len) {
        $sum += dur($dura) * $ratio;
    }

    return $sum;
}



sub rdiminution {
    my ($ratio, @dur_or_len) = @_;

    return () unless $ratio && 1 < $ratio && @dur_or_len;

    my $sum = 0;

    for my $dura (@dur_or_len) {
        $sum += dur($dura) / $ratio;
    }

    return sprintf '%.0f', $sum;
}



sub augmentation {
    my @dur_or_len = @_;

    return () unless @dur_or_len;

    my @ret = ();

    for my $dura (@dur_or_len) {
        my $elem = 'd';
        $elem .= raugmentation(2, $dura);
        push @ret, $elem;
    }

    return @ret;
}



sub diminution {
    my @dur_or_len = @_;

    return () unless @dur_or_len;

    my @ret = ();

    for my $dura (@dur_or_len) {
        my $elem = 'd';
        $elem .= rdiminution(2, $dura);
        push @ret, $elem;
    }

    return @ret;
}



sub ntup {
    my ($n, @notes) = @_;

    return () unless defined $n && @notes;

    my @ret = ();

    if (@notes >= $n) {
        for my $index (0 .. @notes - $n) {
            push @ret, @notes[$index .. $index + $n - 1];
        }
    }

    return @ret;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MIDI::Praxis::Variation - Variation techniques used in music composition

=head1 VERSION

version 0.0607

=head1 SYNOPSIS

  use MIDI::Praxis::Variation ':all';

  # Or import individually by function name:
  # use MIDI::Praxis::Variation qw(augmentation diminution etc);

  my @notes = qw(C5 E5 G5);
  my @dura = qw(qn qn);

  my @x = augmentation(@dura);
  @x = diminution(@dura);
  my $y = dur('qn');
  @x = inversion('B4', @notes);
  $y = note2num('C5');
  @x = ntup(2, @notes);
  @x = notes2nums(@notes);
  $y = raugmentation(1.5, @dura);
  $y = rdiminution(1.5, @dura);
  @x = retrograde(@notes);
  @x = retrograde_inversion('B4', @notes);
  @x = transposition(-12, @notes); # Transpose an octave down
  $y = tie_durations(@dura);

=head1 DESCRIPTION

Melodic variation techniques, as implemented here, expect MIDI::Simple
style note names or durations as input. They return MIDI note numbers
or duration values in ticks (where one quarter note = 96 ticks).

=head1 FUNCTIONS

=head2 note_name_to_number, note2num

  $x = note_name_to_number($note_name);
  $x = note2num($note_name);

Map a single note name to an equivalent MIDI note number (or -1 if not
known).

=head2 original, notes2nums

  @x = original(@array);
  @x = notes2nums(@array);

Map a list of note names to MIDI note numbers.

=head2 retrograde

  @x = retrograde(@array);

Form the retrograde of an array of note names as MIDI note numbers.

=head2 transposition

  @x = transposition($distance, @array);

Form the transposition of an array of notes or MIDI note numbers.

Arguments:

  $distance - An integer giving distance and direction.

  @array    - An array of note names OR MIDI note numbers.

For example, 8 indicates 8 semitones up while -7 asks for 7 semitones
down.

=head2 inversion

  @x = inversion($axis, @array);

Form the inversion of an array of notes.

Arguments:

  $axis  - A note to use as the axis of this inversion.

  @array - An array of note names.

Expects to see a MIDI note name followed by an array of
such names. These give the axis of inversion and the notes to be
inverted.

=head2 retrograde_inversion

  @x = retrograde_inversion($axis, @array);

Form the retrograde inversion of an array of notes.

Arguments:

  $axis  - A note to use as the axis of this inversion.

  @array - An array of note names.

Inverts about the supplied axis.

=head2 dur

  $x = dur($dur_or_len);

Compute duration of a note in MIDI ticks.

Arguments:

  $dur_or_len - A string consisting of a MIDI tick numeric
  duration spec (e.g. d48, or d60) or length spec (e.g. qn or dhn)

=head2 tye, tie_durations

  $x = tye(@dur_or_len);
  $x = tie_durations(@dur_or_len);

Compute the sum of the durations of notes, as with a tie in
music notation. (The odd spelling is used to avoid conflict with the
perl reserved word tie.)

Arguments:

  @dur_or_len - A list of strings consisting of MIDI tick
  numeric duration specs (e.g. d48, or d60) or length specs (e.g. qn
  or dhn)

=head2 raugmentation

  $x = raugmentation($ratio, @dur_or_len);

Augment duration of notes, multiplying them by B<$ratio>.

Arguments:

  $ratio - Multiplier

  @dur_or_len - A list of MIDI tick numeric duration specs
  (e.g. d48, or d60) or length specs (e.g. qn or dhn)

=head2 rdiminution

  $x = rdiminution($ratio, @dur_or_len);

Diminish duration of notes, dividing them by B<$ratio>.

Arguments:

  $ratio - Divisor

  @dur_or_len - A list of MIDI tick numeric duration specs
  (e.g. d48, or d60) or length specs (e.g. qn or dhn)

=head2 augmentation

  @x = augmentation(@dur_or_len);

Augment duration of notes multiplying them by 2, (i.e. double) and
return each in an array reference.

Arguments:

  @dur_or_len - A list of strings consisting of MIDI tick
  numeric duration specs (e.g. d48, or d60) or length specs (e.g. qn
  or dhn)

=head2 diminution

  @x = diminution(@dur_or_len);

Diminish durations of notes dividing them by 2, (i.e. halve) and
return each in an array reference.

Arguments:

  @dur_or_len - A list of strings consisting of MIDI tick
  numeric duration specs (e.g. d48, or d60) or length specs (e.g. qn
  or dhn)

=head2 ntup

  @x = ntup($nelem, @subject);

Catalog and return tuples of length B<$nelem> in B<@subject>.

Arguments:

  $nelem   - Number of elements in each tuple

  @subject - Subject array to be scanned for tuples

Scan begins with the 0th element of B<@subject> looking for a tuple of
length B<$nelem>. Scan advances by one until it has found all tuples
of length B<$nelem>. For example: given the array C<@ar = qw(1 2 3 4)>
and C<$nelem = 2>, then C<ntup(2, @ar)> would return
C<qw(1 2 2 3 3 4)>.

Note that if B<$nelem> equals C<-1>, C<0>, or a value
greater than the size of B<@subject>, this function will return C<()>;

=head1 SEE ALSO

The F<eg/*> and F<t/01-functions.t> files in this distribution

L<Exporter>

L<MIDI::Simple>

=head1 MAINTAINER

Gene Boggs <gene@cpan.org>

=head1 AUTHOR

Craig Bourne <cbourne@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2004 by Craig Bourne.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
