package MIDI::RtController::Filter::Drums;
our $AUTHORITY = 'cpan:GENE';

# ABSTRACT: Generic RtController drum filter

use v5.36;

our $VERSION = '0.0402';

use strictures 2;
use MIDI::Drummer::Tiny ();
use MIDI::RtMidi::ScorePlayer ();
use Moo;
use Types::Common::Numeric qw(PositiveInt);
use Types::Standard qw(CodeRef HashRef);
use namespace::clean;

extends 'MIDI::RtController::Filter';



has bars => (
    is  => 'rw',
    isa => PositiveInt,
    default => sub { 1 },
);


has bpm => (
    is  => 'rw',
    isa => PositiveInt,
    default => sub { 120 },
);


has phrase => (
    is      => 'rw',
    isa     => CodeRef,
    builder => 1,
);

sub _build_phrase {
    return sub {
        my (%args) = @_;
        $args{drummer}->metronome4;
    };
}


has common => (
    is  => 'rw',
    isa => HashRef,
    default => sub { {} },
);


sub _drum_part ($self) {
    return $self->phrase;
}
sub drums ($self, $device, $dt, $event) {
    my ($ev, $chan, $note, $val) = $event->@*;

    return 0 unless $ev eq 'note_on'
        || ($ev eq 'control_change' && defined $self->value && defined $val && $val == $self->value);

    return 0 if $ev eq 'note_on' && defined $self->trigger && $note != $self->trigger;

    my $part = $self->_drum_part;

    my $d = MIDI::Drummer::Tiny->new(
        bpm  => $self->bpm,
        bars => $self->bars,
    );

    my $common = $self->common;
    $common = { %$common, drummer => $d };

    MIDI::RtMidi::ScorePlayer->new(
      device   => $self->rtc->midi_out,
      score    => $d->score,
      common   => $common,
      parts    => [ $part ],
      sleep    => 0,
      infinite => 0,
    )->play_async->retain;

    return $self->continue;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MIDI::RtController::Filter::Drums - Generic RtController drum filter

=head1 VERSION

version 0.0402

=head1 SYNOPSIS

  use curry;
  use Future::IO::Impl::IOAsync; # because ScorePlayer is async
  use MIDI::RtController ();
  use MIDI::RtController::Filter::Drums ();

  my $controller = MIDI::RtController->new(
    input   => 'keyboard',
    output  => 'usb',
    verbose => 1,
  );

  my $filter = MIDI::RtController::Filter::Drums->new(rtc => $controller);

  $filter->bars(8);
  $filter->phrase(\&my_phrase);
  $filter->common({ foo => 42 });

  # for triggering with a note_on message:
  $filter->trigger(99); # note 99 (D#7/Eb7)

  # or for triggering with a control_change:
  # $filter->trigger(25); # CC 25
  # $filter->value(127);

  $controller->add_filter('drums', note_on => $filter->curry::drums);

  $controller->run;

  sub my_phrase {
    my (%args) = @_;
    if ($args{foo} == 42) {
      $args{drummer}->metronome4;
    }
    else {
      $args{drummer}->metronome5;
    }
  }

=head1 DESCRIPTION

C<MIDI::RtController::Filter::Drums> is a generic
L<MIDI::RtController> drum filter.

=head1 ATTRIBUTES

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

=head2 phrase

  $filter->phrase(\&your_phrase);
  $part = $filter->phrase();

The subroutine given to this attribute takes a collection of named
parameters to do its thing. Primarily, this is a
L<MIDI::Drummer::Tiny> instance named "drummer."

=head2 common

  $common = $filter->common;
  $filter->common($common);

These are custom arguments given to the phrase.

A L<MIDI::Tiny::Drummer> instance, named "drummer" is added to this
list when executing the B<phrase>.

Default: C<{}> (no arguments)

=head1 METHODS

=head2 drums

Play the drums.

If B<trigger> is set, a C<note_on> event only fires this filter when
its note matches B<trigger>. If B<value> is set, a C<control_change>
event only fires this filter when its value matches B<value>. When
the filter fires, the full B<phrase> is played.

=head1 SEE ALSO

The F<eg/*.pl> program(s) in this distribution

L<MIDI::RtController::Filter>

L<List::SomeUtils>

L<MIDI::Drummer::Tiny>

L<MIDI::RtController>

L<MIDI::RtMidi::ScorePlayer>

L<Moo>

L<Types::Common::Numeric>

L<Types::Standard>

=head1 AUTHOR

Gene Boggs <gene.boggs@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025-2026 by Gene Boggs.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
