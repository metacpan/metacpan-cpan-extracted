package MIDI::RtController::Filter::Math;
$MIDI::RtController::Filter::Math::VERSION = '0.0201';
our $AUTHORITY = 'cpan:GENE';

# ABSTRACT: Math based RtController filters

use v5.36;

use Moo;
use strictures 2;
use Types::Standard qw(Num);
use namespace::clean;



has rtc => (
    is  => 'ro',
    isa => sub { die 'Invalid rtc' unless ref($_[0]) eq 'MIDI::RtController' },
    required => 1,
);


has channel => (
    is  => 'rw',
    isa => Num,
    default => sub { 0 },
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
    my ($ev, $chan, $note, $vel) = $event->@*;
    my @notes = $self->_stair_step_notes($note);
    my $delay_time = 0;
    for my $n (@notes) {
        $delay_time += $self->delay;
        $self->rtc->delay_send($delay_time, [ $ev, $self->channel, $n, $vel ]);
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

version 0.0201

=head1 SYNOPSIS

  use curry;
  use Future::IO::Impl::IOAsync;
  use MIDI::RtController ();
  use MIDI::RtController::Filter::Math ();

  my $rtc = MIDI::RtController->new; # * input/output required

  my $rtf = MIDI::RtController::Filter::Math->new(rtc => $rtc);

  $rtc->add_filter('stair_step', note_on => $rtf->curry::stair_step);

  $rtc->run;

=head1 DESCRIPTION

C<MIDI::RtController::Filter::Math> is the collection of Math based
L<MIDI::RtController> filters.

=head1 ATTRIBUTES

=head2 rtc

  $rtc = $rtf->rtc;

The required L<MIDI::RtController> instance provided in the
constructor.

=head2 channel

  $channel = $rtf->channel;
  $rtf->channel($number);

The current MIDI channel (0-15, drums=9).

Default: C<0>

=head2 delay

  $delay = $rtf->delay;
  $rtf->delay($number);

The current delay time.

Default: C<0.1> seconds

=head2 feedback

  $feedback = $rtf->feedback;
  $rtf->feedback($number);

The amount of feedback.

Default: C<3>

=head2 up

  $up = $rtf->up;
  $rtf->up($number);

The upward movement steps.

Default: C<2>

=head2 down

  $down = $rtf->down;
  $rtf->down($number);

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

=head1 SEE ALSO

L<Moo>

L<Types::Standard>

=head1 AUTHOR

Gene Boggs <gene.boggs@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Gene Boggs.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
