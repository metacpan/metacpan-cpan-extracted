package MIDI::RtController::Filter::Drums;
our $AUTHORITY = 'cpan:GENE';

# ABSTRACT: RtController drum filters

use v5.36;

our $VERSION = '0.0201';

use strictures 2;
use List::SomeUtils qw(first_index);
use MIDI::Drummer::Tiny ();
use MIDI::RtMidi::ScorePlayer ();
use Moo;
use Types::Standard qw(ArrayRef Num Maybe);
use namespace::clean;



has rtc => (
    is  => 'ro',
    isa => sub { die 'Invalid rtc' unless ref($_[0]) eq 'MIDI::RtController' },
    required => 1,
);


has value => (
    is      => 'rw',
    isa     => Maybe[Num],
    default => undef,
);


has trigger => (
    is      => 'rw',
    isa     => Maybe[Num],
    default => undef,
);


has bars => (
    is  => 'rw',
    isa => Num,
    default => sub { 1 },
);


has bpm => (
    is  => 'rw',
    isa => Num,
    default => sub { 120 },
);


sub _drum_parts ($self, $note) {
    my $part;
    if ($note == 99) {
        $part = sub {
            my (%args) = @_;
            $args{drummer}->metronome4;
        };
    }
    else {
        $part = sub {
            my (%args) = @_;
            $args{drummer}->note($args{drummer}->sixtyfourth, $note);
        };
    }
    return $part;
}
sub drums ($self, $device, $dt, $event) {
    my ($ev, $chan, $note, $val) = $event->@*;
    return 0 if defined $self->trigger && $note != $self->trigger;
    return 0 if defined $self->value && $val != $self->value;

    return 1 unless $ev eq 'note_on';
    my $part = $self->_drum_parts($note);
    my $d = MIDI::Drummer::Tiny->new(
        bpm  => $self->bpm,
        bars => $self->bars,
    );
    MIDI::RtMidi::ScorePlayer->new(
      device   => $self->rtc->midi_out,
      score    => $d->score,
      common   => { drummer => $d },
      parts    => [ $part ],
      sleep    => 0,
      infinite => 0,
    )->play_async->retain;
    return 1;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MIDI::RtController::Filter::Drums - RtController drum filters

=head1 VERSION

version 0.0201

=head1 SYNOPSIS

  use curry;
  use MIDI::RtController ();
  use MIDI::RtController::Filter::Drums ();

  my $rtc = MIDI::RtController->new(
    input  => 'keyboard',
    output => 'usb',
  );

  my $filter = MIDI::RtController::Filter::Drums->new(rtc => $rtc);

  $rtc->add_filter('drums', note_on => $filter->curry::drums);

  $rtc->run;

=head1 DESCRIPTION

C<MIDI::RtController::Filter::Drums> is the L<MIDI::RtController>
filter for the drums.

=head1 ATTRIBUTES

=head2 rtc

  $rtc = $filter->rtc;

The required L<MIDI::RtController> instance provided in the
constructor.

=head2 value

  $value = $filter->value;
  $filter->value($number);

Return or set the MIDI event value. This is a generic setting that can
be used by filters to set or retrieve state. This often a whole number
between C<0> and C<127>, but can take any number.

Default: C<undef>

=head2 trigger

  $trigger = $filter->trigger;
  $filter->trigger($number);

Return or set the trigger. This is a generic setting that
can be used by filters to set or retrieve state. This often a whole
number between C<0> and C<127>, but can take any number.

Default: C<undef>

=head2 bars

  $bars = $filter->bars;
  $filter->bars($number);

The number of measures to set for the drummer bars.

Default: C<1>

=head2 bpm

  $bpm = $filter->bpm;
  $filter->bpm($number);

The beats per minute.

Default: C<120>

=head1 METHODS

All filter methods must accept the object, a MIDI device name, a
delta-time, and a MIDI event ARRAY reference, like:

  sub drums ($self, $device, $delta, $event) {
    my ($event_type, $chan, $note, $value) = $event->@*;
    ...
    return $boolean;
  }

A filter also must return a boolean value. This tells
L<MIDI::RtController> to continue processing other known filters or
not.

=head2 drums

Play the drums.

If B<trigger> or B<value> is set, the filter checks those against the
MIDI event C<note> or C<value>, respectively, to see if the filter
should be applied.

=head1 SEE ALSO

The F<eg/*.pl> program(s) in this distribution

L<MIDI::RtController::Filter::Tonal>

L<MIDI::RtController::Filter::Math>

L<MIDI::RtController::Filter::CC>

L<List::SomeUtils>

L<MIDI::Drummer::Tiny>

L<MIDI::RtMidi::ScorePlayer>

L<Moo>

L<Types::Standard>

=head1 AUTHOR

Gene Boggs <gene.boggs@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Gene Boggs.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
