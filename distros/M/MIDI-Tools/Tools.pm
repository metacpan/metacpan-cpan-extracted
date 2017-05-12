package MIDI::Tools;

use 5.005;
use strict;
use warnings;

require Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
@ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use MIDI::Tools ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
%EXPORT_TAGS = ( 'all' => [ qw(note_count note_range note_mean note_limit
                               note_transpose) ] );

@EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

@EXPORT = qw( );

$VERSION = '0.02';

=head1 NAME

MIDI::Tools - Various functions dealing with MIDI Events

=head1 SYNOPSIS

  use MIDI::Tools qw(...);

  # too much stuff, see below

=head1 ABSTRACT

MIDI::Tools - Various functions dealing with MIDI events

=head1 DESCRIPTION

This is a collection of functions evaluating or transforming lists of MIDI
events, probably most useful for algorithmic composition. It is designed to
be compatible with Sean M. Burke MIDI-Perl suite of modules.

=head1 CAVEAT

This module is in an early alpha stage of development. Interfaces are not
written in stone yet, and stuff needs to be added. Near-future plans include:
Dealing with intervals. Dealing with scales (transpose in scale,
measure outsideness). Swingifying. Dealing with Chords.

=cut

=head1 EVALUATING MIDI EVENTS

All functions take a reference to a list of MIDI events as parameter and
return a scalar or list of results.

=head2 $count = note_count($events);

Returns number of note_on events (excluding those with a velocity of 0).

=cut

sub note_count {
    my ($e) = @_;
    
    return 0 if (!defined $e || !ref $e);

    my $count = 0;
    foreach (@{$e}) {
        $count++
            if (ref $_ && $#{$_} >= 4 && $_->[0] eq 'note_on' && $_->[4] > 0);
    }

    return $count;
}

=head2 ($lowest, $highest) = note_range($events);

Returns lowest and highest pitch ocurring in note_on events, or
undef if no note_on events occur in $events.

=cut

sub note_range {
    my ($e) = @_;

    return undef if (!defined $e || !ref $e);

    my ($lo, $hi);
    foreach (@{$e}) {
        if (ref $_ && $#{$_} >= 4 && $_->[0] eq 'note_on' && $_->[4] > 0) {
            $lo = $_->[3] if (!defined $lo || $_->[3] < $lo);
            $hi = $_->[3] if (!defined $hi || $_->[3] > $hi);
        }
    }

    return undef if (!defined $lo);
    return ($lo, $hi);
}

=head2 ($mean, $stddev) = note_mean($events);

Returns mean and standard deviation of pitches in MIDI note_on
events.

=cut

sub note_mean {
    my ($e) = @_;

    return undef if (!defined $e || !ref $e);

    my ($count, $sum) = (0, 0);
    foreach (@{$e}) {
        if (ref $_ && $#{$_} >= 4 && $_->[0] eq 'note_on' && $_->[4] > 0) {
            $count++;
            $sum += $_->[3];
        }
    }

    return undef if ($count == 0);

    my $avg = $sum / $count;
    my $variance = 0;
    foreach (@{$e}) {
        if (ref $_ && $#{$_} >= 4 && $_->[0] eq 'note_on' && $_->[4] > 0) {
            $variance += ($_->[3] - $avg) * ($_->[3] - $avg);
        }
    }
    $variance /= $count;

    return ($avg, sqrt($variance));
}

=head1 TRANSFORMING MIDI EVENTS

All functions take a reference to a list of MIDI events as parameter and
modify the events directly.

=head2 note_limit($events, $lowest, $highest);

Remove all note_on and note_off events whose pitches lie outside
($lowest .. $highest).

=cut

sub note_limit {
    my ($e, $lowest, $highest) = @_;
    
    return undef if (!defined $e || !ref $e);
    my $i = 0;
    while ($i <= $#{$e}) {
        for ($e->[$i]) {
            if (ref $_ && $#{$_} >= 4 && $_->[0] =~ '^note_o(n|ff)$' &&
                ($_->[3] < $lowest || $_->[3] > $highest)) {
                splice(@{$e}, $i, 1);
            } else {
                $i++;
            }
        }
    }

}

=head2 note_transpose($events, $semitones);

Transpose events by a (positive or negative) number of semitones. Notes will
not be transposed below 0 or above 127.

=cut

sub note_transpose {
    my ($e, $semitones) = @_;

    return undef if (!defined $e || !ref $e);

    my ($count, $sum) = (0, 0);
    foreach (@{$e}) {
        if (ref $_ && $#{$_} >= 4 && $_->[0] =~ '^note_o(n|ff)$') {
            $_->[3] += $semitones;
            $_->[3] = 0 if ($_->[3] < 0);
            $_->[3] = 127 if ($_->[3] > 127);
        }
    }
}

=head1 SEE ALSO

L<MIDI>. L<MIDI::Event>.

=head1 AUTHOR

Christian Renz, E<lt>crenz@web42.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Christian Renz

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

1;
