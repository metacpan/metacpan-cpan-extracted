package MIDI::Chord::Guitar;
our $AUTHORITY = 'cpan:GENE';

# ABSTRACT: MIDI pitches for guitar chord voicings

our $VERSION = '0.0603';

use strict;
use warnings;

use File::ShareDir qw(dist_dir);
use List::Util qw(any zip);
use Music::Note;
use Text::CSV_XS ();
use Moo;
use strictures 2;
use namespace::clean;


has voicing_file => (
  is => 'lazy',
);

sub _build_voicing_file {
    my ($self) = @_;
    my $file = eval { dist_dir('MIDI-Chord-Guitar') . '/midi-guitar-chord-voicings.csv' };
    return $file;
}


has chords => (
  is       => 'lazy',
  init_arg => undef,
);

sub _build_chords {
    my ($self) = @_;

    my $file = $self->voicing_file;

    my %data;

    my $csv = Text::CSV_XS->new({ binary => 1 });

    open my $fh, '<', $file
        or die "Can't read $file: $!";

    while (my $row = $csv->getline($fh)) {
        my $chord = shift @$row;
        my $fingering = shift @$row;
        push @{ $data{$chord}{fingering} }, $fingering;
        my @notes;
        for my $r (@$row) {
            push @notes, $r if $r ne '';
        }
        push @{ $data{$chord}{notes} }, \@notes;
    }

    close $fh;

    return \%data;
}


sub transform {
    my ($self, $target, $chord_name, $variation) = @_;

    $target = Music::Note->new($target, 'ISO')->format('midinum');

    $chord_name //= '';

    my @notes;

    if (defined $variation) {
      my $pitches = $self->chords->{ 'C' . $chord_name }{notes}[$variation];

      my $diff = $target - _lowest_c($pitches);

      @notes = map { $_ + $diff } @$pitches;
    }
    else {
        for my $pitches (@{ $self->chords->{ 'C' . $chord_name }{notes} }) {
            my $diff = $target - _lowest_c($pitches);
            push @notes, [ map { $_ + $diff } @$pitches ];
        }
    }

    return \@notes;
}

sub _lowest_c {
    my ($pitches) = @_;

    my $lowest = 0;

    for my $c (48, 60, 72) {
        if (any { $_ == $c } @$pitches) {
            $lowest = $c;
            last;
        }
    }

    return $lowest;
}


sub voicings {
    my ($self, $chord_name, $format) = @_;

    $chord_name //= '';
    $format ||= '';

    my $voicings = $self->chords->{ 'C' . $chord_name }{notes};

    if ($format) {
        my $temp;

        for my $chord (@$voicings) {
            my $span;

            for my $n (@$chord) {
                my $note = Music::Note->new($n, 'midinum')->format($format);
                push @$span, $note;
            }

            push @$temp, $span;
        }

        $voicings = $temp;
    }

    return $voicings;
}


sub fingering {
    my ($self, $target, $chord_name, $variation) = @_;

    $target = Music::Note->new($target, 'ISO')->format('midinum');

    $chord_name //= '';

    my @fingering;

    if (defined $variation) {
        my $fingering = $self->chords->{ 'C' . $chord_name }{fingering}[$variation];

        my $pitches = $self->chords->{ 'C' . $chord_name }{notes}[$variation];
        my $diff = $target - _lowest_c($pitches);

        my ($str, $pos) = split /-/, $fingering;
        my $p = $pos + $diff;
        if ($p == 0 && $str !~ /0/) {
            $str = _decrement_fingering($str);
            $p++;
        }
        elsif ($p != 0 && $str =~ /0/) {
            $str = _increment_fingering($str);
        }
        push @fingering, $str . '-' . $p;
    }
    else {
        for (zip $self->chords->{ 'C' . $chord_name }{notes}, $self->chords->{ 'C' . $chord_name }{fingering}) {
            my ($pitches, $fingering) = @$_;
            my $diff = $target - _lowest_c($pitches);
            my ($str, $pos) = split /-/, $fingering;
            my $p = $pos + $diff;
            if ($p == 0 && $str !~ /0/) {
                $str = _decrement_fingering($str);
                $p++;
            }
            elsif ($p != 0 && $str =~ /0/) {
                $str = _increment_fingering($str);
            }
            push @fingering, $str . '-' . $p;
        }
    }

    return \@fingering;
}

sub _increment_fingering {
    my ($fingering) = @_;
    my $incremented = '';
    for my $char (split //, $fingering) {
        $incremented .= $char =~ /\d/ ? $char + 1 : $char;
    }
    return $incremented;
}

sub _decrement_fingering {
    my ($fingering) = @_;
    my $decremented = '';
    for my $char (split //, $fingering) {
        $decremented .= $char =~ /\d/ ? $char - 1 : $char;
    }
    return $decremented;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MIDI::Chord::Guitar - MIDI pitches for guitar chord voicings

=head1 VERSION

version 0.0603

=head1 SYNOPSIS

  use MIDI::Chord::Guitar;

  my $mcg = MIDI::Chord::Guitar->new;

  my $chords = $mcg->transform('D3', 'dim7');
  my $chord = $mcg->transform('D3', 'dim7', 0);
  # MIDI:
  #$score->n('wn', @$chord);

  my $fingerings = $mcg->fingering('D3', 'dim7');
  my $fingering = $mcg->fingering('D3', 'dim7', 0);

  my $voicings = $mcg->voicings('dim7');

  $voicings = $mcg->voicings('dim7', 'ISO');

=head1 DESCRIPTION

C<MIDI::Chord::Guitar> provides MIDI pitches for common chord voicings
of an C<E A D G B E> tuned guitar.

=for html <p>Here is a handy diagram of ISO MIDI pitches laid out on a guitar neck:</p>
<img src="https://raw.githubusercontent.com/ology/MIDI-Chord-Guitar/main/guitar-position-midi-octaves.png">
<p>And here is a companion diagram of MIDI pitch numbers laid out on a guitar neck:</p>
<img src="https://raw.githubusercontent.com/ology/MIDI-Chord-Guitar/main/guitar-position-midi-numbers.png">

=head1 ATTRIBUTES

=head2 voicing_file

  $file = $mcg->voicing_file;

The CSV file with which to find the MIDI numbered chord voicings.

If not given, the installed L<File::ShareDir> CSV file is used.

=head2 chords

  $chords = $mcg->chords;

Computed attribute, containing the fingerings and voicings for all
known chords, available after construction.

=head1 METHODS

=head2 transform

  $chord = $mcg->transform($target, $chord_name, $variation);
  $chords = $mcg->transform($target, $chord_name);

Find the chord given the B<target>, B<chord_name> and an optional
B<variation>.

The B<target> must be in the format of an C<ISO> note (e.g. on the
guitar, a C note is represented by C<C3>, C<C4>, C<C5>, etc).

If no B<chord_name> is given, C<major> is used.

If no B<variation> is given, all transformed voicings are returned.

For example, here are the open major chord specs for each note in the
key of C:

  'C3', '', 0
  'D3', '', 4
  'E2', '', 3
  'F2', '', 3
  'G2', '', 2
  'A2', '', 1
  'B2', '', 1

=head2 voicings

  $mcg->voicings($chord_name);
  $mcg->voicings($chord_name, $format);

Return all the voicings of a given B<chord_name> in the key of C.

The default B<format> is C<midinum> but can be given as C<ISO> or
C<midi> to return named notes with octaves.

The order of the voicing variations of a chord is by fret position.
So, the first variations are at lower frets.

Here is an example of the voicing CSV file which can be found with the
B<voicing_file> attribute:

  C,x32010-1,48,52,55,60,,
  C,x13331-3,48,55,60,64,67,
  C,431114-5,48,52,55,60,64,72
  C,133211-8,48,55,60,64,67,72
  C,xx1343-10,60,67,72,76,,
  C7,x32310-1,48,52,58,60,64,
  C7,x13131-3,48,55,58,64,67,
  C7,431112-5,48,52,55,60,64,70
  C7,131211-8,48,55,58,64,70,72
  C7,xx1323-10,60,67,70,76,,
  ...

Check out the links in the L</"SEE ALSO"> section for the chord shapes
used to create this.

=head2 fingering

  $fingering = $mcg->fingering($target, $chord_name, $variation);
  $fingerings = $mcg->fingering($target, $chord_name);

As with the C<transform> method, but for neck position, finger
placement.

=head1 SEE ALSO

The F<t/01-methods.t> and F<eg/*> files in this distribution

The CSV of chords used by this module (with the C<voicing_file> attribute)

L<File::ShareDir>

L<List::Util>

L<Moo>

L<Music::Note>

L<Text::CSV_XS>

L<https://www.guitartricks.com/chords/C-chord> shapes

L<https://www.oolimo.com/guitarchords/C> shapes

=head1 AUTHOR

Gene Boggs <gene@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Gene Boggs.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
