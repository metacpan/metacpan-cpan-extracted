package MIDI::RtController::Filter::Math;
$MIDI::RtController::Filter::Math::VERSION = '0.0301';
our $AUTHORITY = 'cpan:GENE';

# ABSTRACT: Math based RtController filters

use v5.36;

use strictures 2;
use Moo;
use Types::MIDI qw(Channel);
use Types::Standard qw(Num Maybe);
use namespace::clean;



has rtc => (
    is  => 'ro',
    isa => sub { die 'Invalid rtc' unless ref($_[0]) eq 'MIDI::RtController' },
    required => 1,
);


has channel => (
    is  => 'rw',
    isa => Channel,
    default => sub { 0 },
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


has delay => (
    is  => 'rw',
    isa => Num,
    default => sub { 0.1 },
);


has feedback => (
    is  => 'rw',
    isa => Num,
    default => sub { 1 },
);


has up => (
    is  => 'rw',
    isa => Num,
    default => sub { 2 },
);


has down => (
    is  => 'rw',
    isa => Num,
    default => sub { -1 },
);


sub _stair_step_notes ($self, $note) {
    my @notes;
    my $factor;
    my $current = $note;
    for my $i (1 .. $self->feedback) {
        if ($i % 2 == 0) {
            $factor = ($i - 1) * $self->down;
        }
        else {
            $factor = $i * $self->up;
        }
        $current += $factor;
        push @notes, $current;
    }
    return @notes;
}

sub stair_step ($self, $device, $dt, $event) {
    my ($ev, $chan, $note, $val) = $event->@*;
    return 0 if defined $self->trigger && $note != $self->trigger;
    return 0 if defined $self->value && $val != $self->value;

    my @notes = $self->_stair_step_notes($note);
    my $delay_time = 0;
    for my $n (@notes) {
        $delay_time += $self->delay;
        $self->rtc->delay_send($delay_time, [ $ev, $self->channel, $n, $val ]);
    }
    return 0;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MIDI::RtController::Filter::Math - Math based RtController filters

=head1 VERSION

version 0.0301

=head1 SYNOPSIS

  use curry;
  use MIDI::RtController ();
  use MIDI::RtController::Filter::Math ();

  my $rtc = MIDI::RtController->new(
    input  => 'keyboard',
    output => 'usb',
  );

  my $filter = MIDI::RtController::Filter::Math->new(rtc => $rtc);

  $filter->control(1); # CC#01 = mod-wheel
  $filter->channel(0);

  $rtc->add_filter('stair_step', note_on => $filter->curry::stair_step);

  $rtc->run;

=head1 DESCRIPTION

C<MIDI::RtController::Filter::Math> is the collection of Math based
L<MIDI::RtController> filters.

=head1 ATTRIBUTES

=head2 rtc

  $rtc = $filter->rtc;

The required L<MIDI::RtController> instance provided in the
constructor.

=head2 channel

  $channel = $filter->channel;
  $filter->channel($number);

The current MIDI channel (0-15, drums=9).

Default: C<0>

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

=head2 delay

  $delay = $filter->delay;
  $filter->delay($number);

The current delay time.

Default: C<0.1> seconds

=head2 feedback

  $feedback = $filter->feedback;
  $filter->feedback($number);

The amount of feedback.

Default: C<3>

=head2 up

  $up = $filter->up;
  $filter->up($number);

The upward movement steps.

Default: C<2>

=head2 down

  $down = $filter->down;
  $filter->down($number);

The downward movement steps.

Default: C<-1>

=head1 METHODS

All filter methods must accept the object, a MIDI device name, a
delta-time, and a MIDI event ARRAY reference, like:

  sub stair_step ($self, $device, $delta, $event) {
    my ($event_type, $chan, $note, $value) = $event->@*;
    ...
    return $boolean;
  }

A filter also must return a boolean value. This tells
L<MIDI::RtController> to continue processing other known filters or
not.

=head2 stair_step

Notes are played from the event note, in up-down, stair-step fashion.

If B<trigger> or B<value> is set, the filter checks those against the
MIDI event C<note> or C<value>, respectively, to see if the filter
should be applied.

=head1 SEE ALSO

The eg/*.pl program(s) in this distribution

L<MIDI::RtController::Filter::Tonal>

L<MIDI::RtController::Filter::Drums>

L<MIDI::RtController::Filter::CC>

L<Moo>

L<Types::MIDI>

L<Types::Standard>

=head1 AUTHOR

Gene Boggs <gene.boggs@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Gene Boggs.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
