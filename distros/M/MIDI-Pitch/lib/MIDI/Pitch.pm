package MIDI::Pitch;

use 5.00503;
use strict;

require Exporter;
use vars qw($VERSION @ISA @EXPORT_OK
  %name2pitch_lut @pitch2name_table $base_freq);

@ISA       = qw(Exporter);
@EXPORT_OK =
  qw(name2pitch pitch2name freq2pitch pitch2freq basefreq name2freq freq2name findsemitone);
$VERSION = '0.7';

$base_freq = 440;

=head1 NAME

MIDI::Pitch - Converts MIDI pitches, note names and frequencies into each other

=head1 SYNOPSIS

  use MIDI::Pitch qw(name2pitch pitch2name freq2pitch pitch2freq basefreq);

  my $pitch = name2pitch($name);
  
  
=head1 DESCRIPTION

This module converts MIDI pitches between 0 and 127 (called 'note numbers'
in the MIDI standard) and note names into each other. The octave
numbers are based on the table found in the MIDI standard (see
L<http://www.harmony-central.com/MIDI/Doc/table2.html>):

    The MIDI specification only defines note number 60 as "Middle C", and
    all other notes are relative. The absolute octave number designations
    shown here are based on Middle C = C4, which is an arbitrary
    assignment.

The note names are C<C>, C<C#>/C<Db>, C<D>, ..., followed by an octave
number from -1 to 9. Thus, the valid notes range between C<C-1> and
C<G9>.

=head1 FUNCTIONS

=head2 name2pitch

  my $pitch = name2pitch($name);

Converts a note name into a pitch. 

=cut

%name2pitch_lut = (
    'b#' => 0,
    c    => 0,
    'c#' => 1,
    'db' => 1,
    d    => 2,
    'd#' => 3,
    'eb' => 3,
    e    => 4,
    'fb' => 4,
    'e#' => 5,
    f    => 5,
    'f#' => 6,
    'gb' => 6,
    g    => 7,
    'g#' => 8,
    'ab' => 8,
    a    => 9,
    'a#' => 10,
    'bb' => 10,
    b    => 11,
    'cb' => 11);

sub name2pitch {
    my $n = shift;

    return undef unless defined $n && lc($n) =~ /^([a-g][b#]?)(-?\d\d?)$/;

    my $p = $name2pitch_lut{$1} + ($2 + 1) * 12;
    return undef unless $p >= 0 && $p <= 127;
    return $p;
}

=head2 pitch2name

  my $name = pitch2name($pitch);

Converts a pitch between 0 and 127 into a note name. pitch2name returns
the lowercase version with a sharp, if necessary (e.g. it will return
'g#', not 'Ab').

=cut

@pitch2name_table =
  ('c', 'c#', 'd', 'd#', 'e', 'f', 'f#', 'g', 'g#', 'a', 'a#', 'b');

sub pitch2name {
    my $p = shift;

    return undef unless defined $p && $p =~ /^-?(\d+|\d*(\.\d+))$/;
    $p = int($p + .5 * ($p <=> 0));
    return undef unless $p >= 0 && $p <= 127;

    return $pitch2name_table[$p % 12] . (int($p / 12) - 1);
}

=head2 freq2pitch

  my $pitch = freq2pitch($440);

Converts a frequency >= 0 Hz to a pitch, using the base frequency set.

=cut

sub freq2pitch {
    my $f = shift;

    return undef unless defined $f && $f =~ /^(\d+|\d*(\.\d+))$/ && $f > 0;
    return 69 + 12 * log($f / $base_freq) / log(2);
}

=head2 pitch2freq

  my $freq = pitch2freq(69);

Converts a pitch to a frequency, using the base frequency set.

=cut

sub pitch2freq {
    my $p = shift;

    return undef unless defined $p && $p =~ /^-?(\d+|\d*(\.\d+))$/;
    return exp((($p - 69) / 12) * log(2)) * $base_freq;
}

=head2 name2freq

    my $freq = name2freq('c2');

This is just an alias for C<pitch2freq(name2pitch($x))>.

=cut

sub name2freq {
    return pitch2freq(name2pitch(@_));
}

=head2 freq2name

    my $name = freq2name('c2');

This is just an alias for C<pitch2name(freq2pitch($x))>.

=cut

sub freq2name {
    return pitch2name(freq2pitch(@_));
}

=head2 findsemitone {

    my $pitch = findsemitone('d#', 60);

Finds the nearest pitch that expresses the semitone given around the
pitch given. The example above would return 63, since the d# at pitch 63 is
nearer to 60 than the d# at pitch 51.

The semitone can be specified in the same format as a note name (without 
the octave) or as an integer between 0 and 11.

If there are two possibilities for the nearest pitch, findsemitone returns
the lower one.

=cut

sub findsemitone {
    my ($semitone, $pitch) = @_;

    return undef unless defined $semitone &&
      (($semitone =~ /^\d+$/
      && $semitone >= 0
      && $semitone <= 11) || exists $name2pitch_lut{$semitone});
    return undef
      unless defined $pitch
      && $pitch =~ /^\d+$/
      && $pitch >= 0
      && $pitch <= 127;

    $semitone = $name2pitch_lut{$semitone} if exists $name2pitch_lut{$semitone};

    my $m = $pitch % 12;
    my $result = $pitch - $m + $semitone;
    $result += 12 if ($pitch - $result > 6 && $result < 116);
    $result -= 12 if ($result - $pitch > 6 && $result > 11);

    return $result;
}

=head2 basefreq

  my $basefreq = basefreq;
  basefreq(432);

Sets/returns current base frequency for frequency/pitch conversion. The
standard base frequency set is 440 (Hz). Note that the base frequency
does not affect the pitch/name conversion.

=cut

sub basefreq {
    my $f = shift;

    $base_freq = $f if defined $f && $f > 0;
    return $base_freq;
}

=head1 HISTORY

=over 8

=item 0.7

Added Changes file.

=item 0.6

findsemitone now also understands semitones specified as integers between 0 and 11.
Fixed bug in findsemitone.

=item 0.5

Added findsemitone function

=item 0.2

Added pitch rounding (60.49 and 59.5 will both be considered 60/'C4').

Added frequency/pitch conversion.

Added POD tests.

=item 0.1

Original version; created by h2xs 1.22 with options

  -A -C -X -n MIDI::Pitch -v 0.1 -b 5.5.3

=back

=head1 SEE ALSO

L<MIDI>. L<MIDI::Tools>.

L<http://www.harmony-central.com/MIDI/Doc/table2.html>

=head1 AUTHOR

Christian Renz, E<lt>crenz @ web42.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004-2005 by Christian Renz E<lt>crenz @ web42.comE<gt>. All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

1;
