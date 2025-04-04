package MIDI::RtController::Filter::CC;
our $AUTHORITY = 'cpan:GENE';

# ABSTRACT: Control-change based RtController filters

our $VERSION = '0.0100';

use v5.36;

use strictures 2;
use Iterator::Breathe ();
use Moo;
use Time::HiRes qw(usleep);
use Types::MIDI qw(Channel Velocity);
use Types::Common::Numeric qw(PositiveNum);
use Types::Standard qw(Bool Num);
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


has range_bottom => (
    is      => 'rw',
    isa     => Num,
    default => 0,
);


has range_top => (
    is      => 'rw',
    isa     => Num,
    default => 127,
);


has range_step => (
    is      => 'rw',
    isa     => PositiveNum,
    default => 1,
);


has time_step => (
    is      => 'rw',
    isa     => PositiveNum,
    default => 250_000,
);


has running => (
    is      => 'rw',
    isa     => Bool,
    default => 0,
);


has stop => (
    is      => 'rw',
    isa     => Bool,
    default => 0,
);


sub breathe ($self, $device, $dt, $event) {
    return 0 if $self->running;

    my ($ev, $chan, $ctl, $val) = $event->@*;

    my $it = Iterator::Breathe->new(
        bottom => $self->range_bottom,
        top    => $self->range_top,
        step   => $self->range_step,
    );

    $self->running(1);

    while (!$self->stop) {
        $it->iterate;
        my $cc = [ 'control_change', $self->channel, $self->control, $it->i ];
        $self->rtc->send_it($cc);
        usleep $self->time_step;
    }

    return 0;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MIDI::RtController::Filter::CC - Control-change based RtController filters

=head1 VERSION

version 0.0100

=head1 SYNOPSIS

  use curry;
  use Future::IO::Impl::IOAsync;
  use MIDI::RtController ();
  use MIDI::RtController::Filter::CC ();

  my $rtc = MIDI::RtController->new; # * input/output required

  my $rtf = MIDI::RtController::Filter::CC->new(rtc => $rtc);

  $rtc->add_filter('breathe', note_on => $rtf->curry::breathe);

  $rtc->run;

=head1 DESCRIPTION

C<MIDI::RtController::Filter::CC> is a (growing) collection of
control-change based L<MIDI::RtController> filters.

=head1 ATTRIBUTES

=head2 rtc

  $rtc = $rtf->rtc;

The required L<MIDI::RtController> instance provided in the
constructor.

=head2 channel

  $channel = $rtf->channel;
  $rtf->channel($number);

The current MIDI channel value between C<0> and C<15>.

Default: C<0>

=head2 control

  $control = $rtf->control;
  $rtf->control($number);

The current MIDI control-change number ("CC#") between C<0> and C<127>.

Default: C<1> (synthesizer mod-wheel)

=head2 range_bottom

  $range_bottom = $rtf->range_bottom;
  $rtf->range_bottom($number);

The current iteration lowest number value.

Default: C<0>

=head2 range_top

  $range_top = $rtf->range_top;
  $rtf->range_top($number);

The current iteration highest number value.

Default: C<127>

=head2 range_step

  $range_step = $rtf->range_step;
  $rtf->range_step($number);

A number greater than zero representing the current iteration step
size between B<bottom> and B<top>.

Default: C<1>

=head2 time_step

  $time_step = $rtf->time_step;
  $rtf->time_step($number);

The current iteration step in microseconds (where
C<1,000,000> = C<1> second).

Default: C<250_000> (a quarter of a second)

=head2 running

  $running = $rtf->running;
  $rtf->running($boolean);

Are we running a filter?

Default: C<0>

=head2 stop

  $stop = $rtf->stop;
  $rtf->stop($boolean);

Stop running a filter.

Default: C<0>

=head1 METHODS

All filter methods must accept the object, a MIDI device name, a
delta-time, and a MIDI event ARRAY reference, like:

  sub breathe ($self, $device, $delta, $event) {
    my ($event_type, $chan, $note, $value) = $event->@*;
    ...
    return $boolean;
  }

A filter also must return a boolean value. This tells
L<MIDI::RtController> to continue processing other known filters or
not.

=head2 breathe

This filter sets the B<running> flag and then iterates between the
B<range_bottom> and B<range_top> by B<range_step> increments, sending
a B<control> change message, over the MIDI B<channel> every iteration,
until B<stop> is seen.

=head1 SEE ALSO

L<Iterator::Breathe>

L<Moo>

L<Time::HiRes>

L<Types::Common::Numeric>

L<Types::MIDI>

L<Types::Standard>

=head1 AUTHOR

Gene Boggs <gene.boggs@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Gene Boggs.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
