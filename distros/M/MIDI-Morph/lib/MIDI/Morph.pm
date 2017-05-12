package MIDI::Morph;

use warnings;
use strict;

our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(event_distance);

=head1 NAME

MIDI::Morph - Musical transition tool

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

    use MIDI::Morph;

    my $m = MIDI::Morph->new(from => $from_score, to => $to_score);
    $new_score = $m->Morph(0.4);

=head1 DESCRIPTION

The aim of MIDI::Morph is to provide an easy-to-use composition tool that allows
transitions between two I<gestalten> (musical snippets). The data handled by
this module is in L<MIDI::Score> format (at this moment, only C<note> events
are considered).

This is an alpha release, features and API will be extended and changed
iteratively.

=head1 CONSTRUCTOR

=head2 new

    my $m = MIDI::Morph->new(from => $from, to => $to);

Creates a new morpher object.

=cut

sub new {
    my $class  = shift;
    my %params = @_;
    my $self   = {};

    return undef
      unless ref $params{from} eq 'ARRAY' && ref $params{to} eq 'ARRAY';

    foreach (qw(from to)) {
        $self->{$_} = $params{$_};
    }

    return bless $self, $class;
}

=head1 METHODS

=head2 AutoMap

AutoMap is called automatically by MIDI::Morph and provides a mapping from
the notes in the C<from> structure to the notes in the C<to> structure.
Currently, it is a simple mapping 1st<->1st, 2nd<->2nd, but this will
become more sophisticated in future.

=cut

sub AutoMap {
    my ($self) = @_;

    $self->{map} = [];

    foreach (0 .. $#{$self->{from}}) {
        $self->{map}->[$_] = [$_];
    }
}

=head2 Morph

    $m->Morph($position);

Morph creates a structure that reflects a transition point between C<from> (0)
and C<to> (1). Currently the transition is linear.

=cut

sub Morph {
    my ($self, $position) = @_;

    $self->AutoMap()
      unless (ref $self->{map});

    my @morph = ();
    foreach (0 .. $#{$self->{map}}) {
        push @morph,
          morph_single_event($self->{from}->[$_], $self->{to}->[$_], $position);
    }

    return [@morph];
}

=head1 FUNCTIONS

=head2 event_distance

    MIDI::Morph::event_distance($event1, $event2, $weights);

This function calculates the distance between two events. The events passed
should be note events as described in L<MIDI::Score>. The weights are passed
as a hash reference with the keys C<start>, C<end>, C<pitch> and C<velocity>.
This parameter is optional; the default weights are 1, 1, 1 and 0 respectively.

These weights can be used in case you want to measure the distance between
two events in different terms.

=cut

our %distance_default_weights = (
    start    => 1,
    end      => 1,
    pitch    => 1,
    velocity => 0);

our %distance_weights = %distance_default_weights;

sub event_distance {
    my ($a, $b, $weights) = @_;

    # 'note', position, duration, channel, pitch, velocity
    # 0       1         2         3        4      5
    return undef unless ref $a eq 'ARRAY' && ref $b eq 'ARRAY';
    return undef unless scalar @$a == 6 && scalar @$a == 6;
    return undef unless $a->[0] eq 'note' && $b->[0] eq 'note';

    my %weights = %distance_weights;

    if (ref $weights eq 'HASH') {
        foreach (keys %weights) {
            $weights{$_} = $weights->{$_} if defined $weights->{$_};
        }
    }

#    use Data::Dumper qw(Dumper);
#    print STDERR "\n\n" . Dumper({
#        weights => \%weights,
#        a => $a,
#        b => $b
#    }).  "\n\n";

    return
      abs($a->[1] - $b->[1]) * $weights{start} +
      abs(($a->[1] + $a->[2]) - ($b->[1] + $b->[2])) * $weights{end} +
      abs($a->[4] - $b->[4]) * $weights{pitch} +
      abs($a->[5] - $b->[5]) * $weights{velocity};
}

=head2 morph_single_event

    my $event = morph_single_event($from_event, $to_event, $position);

This helper function morphs two single events.

=cut

sub morph_single_event {
    my ($from, $to, $position) = @_;

    return undef unless ref $from  eq 'ARRAY' && ref $to  eq 'ARRAY';
    return undef unless $from->[0] eq 'note'  && $to->[0] eq 'note';

    my @event = @$from;

    # leave channel untouched, change start, duration, pitch, velocity
    foreach (1, 2, 4, 5) {
        my $diff = $to->[$_] - $from->[$_];
        $event[$_] = $from->[$_] + $position * $diff;
    }

    return [@event];
}

=head1 AUTHOR

Christian Renz, E<lt>crenz @ web42.comE<gt>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-midi-morph@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=MIDI-Morph>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SEE ALSO

L<MIDI>

=head1 COPYRIGHT & LICENSE

Copyright 2005 Christian Renz E<lt>crenz @ web42.comE<gt> , All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

42;
