package MIDI::RtController::Filter;
our $AUTHORITY = 'cpan:GENE';

# ABSTRACT: Parent class of RtController filters

our $VERSION = '0.0101';

use Moo;
use strictures 2;
use Types::Standard qw(Bool Maybe);
use Types::MIDI qw(Channel Velocity);
use namespace::clean;


has rtc => (
    is  => 'ro',
    isa => sub { die 'Invalid controller' unless ref($_[0]) eq 'MIDI::RtController' },
);


has channel => (
    is      => 'rw',
    isa     => Channel,
    default => sub { 0 },
);


has value => (
    is      => 'rw',
    isa     => Maybe[Velocity],
    default => sub { undef },
);


has trigger => (
    is      => 'rw',
    isa     => Maybe[Velocity],
    default => sub { undef },
);


has running => (
    is      => 'rw',
    isa     => Bool,
    default => 0,
);


has halt => (
    is      => 'rw',
    isa     => Bool,
    default => 0,
);


has continue => (
    is      => 'rw',
    isa     => Bool,
    default => 0,
);


has verbose => (
    is      => 'rw',
    isa     => Bool,
    default => sub { 0 },
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MIDI::RtController::Filter - Parent class of RtController filters

=head1 VERSION

version 0.0101

=head1 SYNOPSIS

  package Your::Filter;
  extends 'MIDI::RtController::Filter';

=head1 DESCRIPTION

C<MIDI::RtController::Filter> is the parent class of
L<MIDI::RtController> filters.

=head2 Making filters

All filter methods must accept the object, a MIDI device name, a
delta-time, and a MIDI event ARRAY reference, like:

  sub breathe ($self, $device, $delta, $event) {
    return 0 if $self->running;
    my ($event_type, $chan, $control, $value) = $event->@*;
    ...
    return $self->continue;
  }

A filter also must return a boolean value. This tells
L<MIDI::RtController> to continue processing other known filters or
not. The B<continue> attribute is used for this purpose.

=head2 Calling filters

  $controller->add_filter('breathe', note_on => $filter->curry::breathe);

Passing C<all> to the C<add_filter> method means that any MIDI event
will fire the filter. But C<note_on>, C<[qw(note_on note_off)]>, or
C<control_change> works, as well.

=head1 ATTRIBUTES

=head2 rtc

  $controller = $filter->rtc;

A L<MIDI::RtController> instance provided in the constructor.

=head2 channel

  $channel = $filter->channel;
  $filter->channel($number);

The current MIDI channel value between C<0> and C<15>.

Default: C<0>

=head2 value

  $value = $filter->value;
  $filter->value($number);

Return or set the MIDI event value. This is a generic setting that can
be used by filters to set or retrieve state. This often a whole number
between C<0> and C<127>, but can be C<undef>.

Default: C<undef>

=head2 trigger

  $trigger = $filter->trigger;
  $filter->trigger($number);

Return or set the trigger. This is a generic setting that
can be used by filters to set or retrieve state. This often a whole
number between C<0> and C<127> representing an event note or
control-change.

Default: C<undef>

=head2 running

  $running = $filter->running;
  $filter->running($boolean);

Are we running a filter?

Default: C<0>

=head2 halt

  $halt = $filter->halt;
  $filter->halt($boolean);

This Boolean can be used to terminate B<running> filters.

Default: C<0>

=head2 continue

  $continue = $filter->continue;
  $filter->continue($boolean);

This Boolean can be used to either stop or continue processing other
filters by L<MIDI::RtController> when returned from a filter.

Default: C<0>

=head2 verbose

  $verbose = $filter->verbose;

Show progress.

=head1 SEE ALSO

L<Moo>

L<MIDI::RtController>

L<MIDI::RtController::Filter-CC>

L<MIDI::RtController::Filter-Drums>

L<MIDI::RtController::Filter-Tonal>

L<Types::Standard>

=head1 AUTHOR

Gene Boggs <gene.boggs@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Gene Boggs.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
