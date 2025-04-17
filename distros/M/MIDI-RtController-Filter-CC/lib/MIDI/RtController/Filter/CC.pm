package MIDI::RtController::Filter::CC;
our $AUTHORITY = 'cpan:GENE';

# ABSTRACT: Control-change based RtController filters

our $VERSION = '0.0904';

use v5.36;

use strictures 2;
use curry;
use IO::Async::Timer::Countdown ();
use IO::Async::Timer::Periodic ();
use Iterator::Breathe ();
use Moo;
use Types::MIDI qw(Channel Velocity);
use Types::Common::Numeric qw(NegativeNum PositiveNum);
use Types::Standard qw(Bool Num Maybe);
use namespace::clean;


has rtc => (
    is  => 'ro',
    isa => sub { die 'Invalid rtc' unless ref($_[0]) eq 'MIDI::RtController' },
    required => 1,
);


has channel => (
    is      => 'rw',
    isa     => Channel,
    default => 0,
);


has control => (
    is      => 'rw',
    isa     => Velocity, # no CC# in Types::MIDI yet
    default => 1,
);


has value => (
    is      => 'rw',
    isa     => Velocity, # no CC# in Types::MIDI yet
    default => undef,
);


has trigger => (
    is      => 'rw',
    isa     => Velocity, # no CC# in Types::MIDI yet
    default => undef,
);


has initial_point => (
    is      => 'rw',
    isa     => Velocity, # no CC# msg value in Types::MIDI yet
    default => 0,
);


has range_bottom => (
    is      => 'rw',
    isa     => Velocity, # no CC# msg value in Types::MIDI yet
    default => 0,
);


has range_top => (
    is      => 'rw',
    isa     => Velocity, # no CC# msg value in Types::MIDI yet
    default => 127,
);


has range_step => (
    is      => 'rw',
    isa     => NegativeNum | PositiveNum,
    default => 1,
);


has time_step => (
    is      => 'rw',
    isa     => PositiveNum,
    default => 0.25,
);


has step_up => (
    is      => 'rw',
    isa     => Num,
    default => 2,
);


has step_down => (
    is      => 'rw',
    isa     => Num,
    default => 1,
);


has running => (
    is      => 'rw',
    isa     => Bool,
    default => 0,
);


sub add_filters ($filters, $controllers) {
    for my $params (@$filters) {
        my $port = delete $params->{port};
        next unless $port; # skip unnamed entries
        my $type = delete $params->{type} || 'single';
        my $event = delete $params->{event} || 'all';
        my $filter = __PACKAGE__->new(
            rtc => $controllers->{$port}
        );
        for my $param (keys %$params) {
            $filter->$param($params->{$param});
        }
        my $method = "curry::$type";
        $controllers->{$port}->add_filter($type, $event => $filter->$method);
    }
}


sub single ($self, $device, $dt, $event) {
    my ($ev, $chan, $note, $val) = $event->@*;
    return 0 if defined $self->trigger && $note != $self->trigger;

    my $value = $self->value || $val;
    my $cc = [ 'control_change', $self->channel, $self->control, $value ];
    $self->rtc->send_it($cc);
    return 1;
}


sub breathe ($self, $device, $dt, $event) {
    return 0 if $self->running;

    my ($ev, $chan, $note, $val) = $event->@*;
    return 0 if defined $self->trigger && $note != $self->trigger;
    return 0 if defined $self->value && $val != $self->value;

    $self->running(1);

    my $it = Iterator::Breathe->new(
        bottom => $self->range_bottom,
        top    => $self->range_top,
        step   => $self->range_step,
    );

    $self->rtc->loop->add(
        IO::Async::Timer::Periodic->new(
            interval  => $self->time_step,
            on_tick => sub {
                $it->iterate;
                my $cc = [ 'control_change', $self->channel, $self->control, $it->i ];
                $self->rtc->send_it($cc);
            },
        )->start
    );

    return 0;
}


sub scatter ($self, $device, $dt, $event) {
    return 0 if $self->running;

    my ($ev, $chan, $note, $val) = $event->@*;
    return 0 if defined $self->trigger && $note != $self->trigger;
    return 0 if defined $self->value && $val != $self->value;

    $self->running(1);

    my $value  = $self->initial_point;
    my @values = ($self->range_bottom .. $self->range_top);

    $self->rtc->loop->add(
        IO::Async::Timer::Periodic->new(
            interval  => $self->time_step,
            on_tick => sub {
                my $cc = [ 'control_change', $self->channel, $self->control, $value ];
                $self->rtc->send_it($cc);
                $value = $values[ int rand @values ];
            },
        )->start
    );

    return 0;
}


sub stair_step ($self, $device, $dt, $event) {
    return 0 if $self->running;

    my ($ev, $chan, $note, $val) = $event->@*;
    return 0 if defined $self->trigger && $note != $self->trigger;
    return 0 if defined $self->value && $val != $self->value;

    $self->running(1);

    my $it = Iterator::Breathe->new(
        bottom => $self->range_bottom,
        top    => $self->range_top,
    );

    my $value     = $self->initial_point;
    my $direction = 1; # up

    $self->rtc->loop->add(
        IO::Async::Timer::Periodic->new(
            interval  => $self->time_step,
            on_tick => sub {
                my $cc = [ 'control_change', $self->channel, $self->control, $value ];
                $self->rtc->send_it($cc);

                # compute the stair-stepping
                if ($direction) {
                    $it->step($self->step_up);
                }
                else {
                    $it->step(- $self->step_down);
                }

                # toggle the stair-step direction
                $direction = !$direction;

                # iterate the breathing
                $it->iterate;
                $value = $it->i;
                $value = $self->range_top    if $value >= $self->range_top;
                $value = $self->range_bottom if $value <= $self->range_bottom;
            },
        )->start
    );
    return 0;
}


sub ramp_up ($self, $device, $dt, $event) {
    return 0 if $self->running;

    my ($ev, $chan, $note, $val) = $event->@*;
    return 0 if defined $self->trigger && $note != $self->trigger;
    return 0 if defined $self->value && $val != $self->value;

    $self->running(1);

    my $value = $self->initial_point;

    $self->rtc->loop->add(
        IO::Async::Timer::Countdown->new(
            delay     => $self->time_step,
            on_expire => sub {
                my $c = shift;

                my $cc = [ 'control_change', $self->channel, $self->control, $value ];
                $self->rtc->send_it($cc);

                $value += $self->range_step;

                if ($value > $self->range_top) {
                    $c->stop;
                    $self->running(0);
                }
                else {
                    $c->start;
                }
            },
        )->start
    );

    return 0;
}


sub ramp_down ($self, $device, $dt, $event) {
    return 0 if $self->running;

    my ($ev, $chan, $note, $val) = $event->@*;
    return 0 if defined $self->trigger && $note != $self->trigger;
    return 0 if defined $self->value && $val != $self->value;

    $self->running(1);

    my $value = $self->initial_point;

    $self->rtc->loop->add(
        IO::Async::Timer::Countdown->new(
            delay     => $self->time_step,
            on_expire => sub {
                my $c = shift;

                my $cc = [ 'control_change', $self->channel, $self->control, $value ];
                $self->rtc->send_it($cc);

                $value -= $self->range_step;

                if ($value < $self->range_bottom) {
                    $c->stop;
                    $self->running(0);
                }
                else {
                    $c->start;
                }
            },
        )->start
    );

    return 0;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MIDI::RtController::Filter::CC - Control-change based RtController filters

=head1 VERSION

version 0.0904

=head1 SYNOPSIS

  use curry;
  use MIDI::RtController ();
  use MIDI::RtController::Filter::CC ();

  my $control = MIDI::RtController->new(
    input  => 'keyboard',
    output => 'usb',
  );

  my $filter = MIDI::RtController::Filter::CC->new(rtc => $control);

  $filter->control(1); # CC#01 = mod-wheel
  $filter->channel(0);
  $filter->range_bottom(10);
  $filter->range_top(100);
  $filter->range_step(2);
  $filter->time_step(0.25);

  $control->add_filter('breathe', all => $filter->curry::breathe);

  $control->run;

=head1 DESCRIPTION

C<MIDI::RtController::Filter::CC> is a (growing) collection of
control-change based L<MIDI::RtController> filters.

Passing C<all> to the C<add_filter> method means that any MIDI event
will trigger the filter.

=head2 Making filters

All filter methods must accept the object, a MIDI device name, a
delta-time, and a MIDI event ARRAY reference, like:

  sub breathe ($self, $device, $delta, $event) {
    return 0 if $self->running;
    my ($event_type, $chan, $control, $value) = $event->@*;
    ...
    return $boolean;
  }

A filter also must return a boolean value. This tells
L<MIDI::RtController> to continue processing other known filters or
not.

=head1 ATTRIBUTES

=head2 rtc

  $rtc = $filter->rtc;

The required L<MIDI::RtController> instance provided in the
constructor.

=head2 channel

  $channel = $filter->channel;
  $filter->channel($number);

The current MIDI channel value between C<0> and C<15>.

Default: C<0>

=head2 control

  $control = $filter->control;
  $filter->control($number);

Return or set the control change number between C<0> and C<127>.

Default: C<1> (mod-wheel)

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

=head2 initial_point

  $initial_point = $filter->initial_point;
  $filter->initial_point($number);

Return or set the control change initial point number between C<0> and
C<127>.

Default: C<0>

=head2 range_bottom

  $range_bottom = $filter->range_bottom;
  $filter->range_bottom($number);

The current iteration lowest number value.

Default: C<0>

=head2 range_top

  $range_top = $filter->range_top;
  $filter->range_top($number);

The current iteration highest number value.

Default: C<127>

=head2 range_step

  $range_step = $filter->range_step;
  $filter->range_step($number);

A number greater than zero representing the current iteration step
size between B<bottom> and B<top>.

Default: C<1>

=head2 time_step

  $time_step = $filter->time_step;
  $filter->time_step($number);

The current iteration step in seconds (probably fractions).

Default: C<0.25> (a quarter of a second)

=head2 step_up

  $step_up = $filter->step_up;
  $filter->step_up($number);

The current iteration upward step.

Default: C<2>

=head2 step_down

  $step_down = $filter->step_down;
  $filter->step_down($number);

The current iteration downward step.

Default: C<1>

=head2 running

  $running = $filter->running;
  $filter->running($boolean);

Are we running a filter?

Default: C<0>

=head1 METHODS

=head2 new

  $filter = MIDI::RtController::Filter::CC->new(%arguments);

Return a new C<MIDI::RtController::Filter::CC> object.

=head1 UTILITIES

=head2 add_filters

  MIDI::RtController::Filter::CC::add_filters(\@filters, $controllers);

Add an array reference of B<filters> to controller instances. For
example:

  [
    { # mod-wheel
      port => 'keyboard',        # what is controlling it
      type => 'breathe',         # the type of filter
      event => 'control_change', # or [qw(note_on note_off)] etc
      control => 1,              # what CC# is being controlled
      trigger => 25,             # what CC# triggers the controlling
      time_step => 0.25,         # a parameter
    },
    ...
  ]

In this list, C<port> and C<type> are required, and C<event> is
optional. These keys are metadata, and all others are assumed to be
object attributes to set.

The B<controllers> come from L<MIDI::RtController/open_controllers>
and is a hash reference of C<MIDI::RtController> instances keyed by a
MIDI input device port name.

=head1 FILTERS

=head2 single

  $control->add_filter('single', all => $filter->curry::single);

This filter sets a single B<control> change message, over the MIDI
B<channel> once.

If B<trigger> is set, the filter checks that against the MIDI event
C<note> to see if the filter should be applied.

=head2 breathe

  $control->add_filter('breathe', all => $filter->curry::breathe);

This filter sets the B<running> flag, then iterates between the
B<range_bottom> and B<range_top> by B<range_step> increments, sending
a B<control> change message, over the MIDI B<channel> every iteration.

Passing C<all> means that any MIDI event will cause this filter to be
triggered.

If B<trigger> or B<value> is set, the filter checks those against the
MIDI event C<note> or C<value>, respectively, to see if the filter
should be applied.

=head2 scatter

  $control->add_filter('scatter', all => $filter->curry::scatter);

This filter sets the B<running> flag, chooses a random number between
the B<range_bottom> and B<range_top>, and sends that as the value of a
B<control> change message, over the MIDI B<channel>, every iteration.

The B<initial_point> is used as the first CC# message, then the
randomization takes over.

If B<trigger> or B<value> is set, the filter checks those against the
MIDI event C<note> or C<value>, respectively, to see if the filter
should be applied.

=head2 stair_step

  $control->add_filter('stair_step', all => $filter->curry::stair_step);

This filter sets the B<running> flag, uses the B<initial_point> for
the fist CC# message, then adds B<step_up> or subtracts B<step_down>
from that number successively, sending the value as a B<control>
change message, over the MIDI B<channel>, every iteration.

If B<trigger> or B<value> is set, the filter checks those against the
MIDI event C<note> or C<value>, respectively, to see if the filter
should be applied.

=head2 ramp_up

  $control->add_filter('ramp_up', all => $filter->curry::ramp_up);

This filter ramps-up a B<control> change message, over the MIDI
B<channel>, from B<range_bottom> until the B<range_top> is reached.

If B<trigger> or B<value> is set, the filter checks those against the
MIDI event C<note> or C<value>, respectively, to see if the filter
should be applied.

=head2 ramp_down

  $control->add_filter('ramp_down', all => $filter->curry::ramp_down);

This filter ramps-down a B<control> change message, over the MIDI
B<channel>, from B<range_top> until the B<range_bottom> is reached.

If B<trigger> or B<value> is set, the filter checks those against the
MIDI event C<note> or C<value>, respectively, to see if the filter
should be applied.

=head1 SEE ALSO

The F<eg/*.pl> program(s) in this distribution

L<IO::Async::Timer::Periodic>

L<Iterator::Breathe>

L<MIDI::RtController>

L<Moo>

L<Types::MIDI>

L<Types::Common::Numeric>

L<Types::Standard>

=head1 AUTHOR

Gene Boggs <gene.boggs@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Gene Boggs.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
