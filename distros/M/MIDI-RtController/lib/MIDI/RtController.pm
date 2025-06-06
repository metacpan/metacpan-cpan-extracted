package MIDI::RtController;
our $AUTHORITY = 'cpan:GENE';

# ABSTRACT: Control your MIDI controller

use v5.36;

our $VERSION = '0.0801';

use Moo;
use strictures 2;
use Carp qw(croak);
use IO::Async::Channel ();
use IO::Async::Loop ();
use IO::Async::Routine ();
use IO::Async::Timer::Countdown ();
use MIDI::RtMidi::FFI::Device ();
use namespace::clean;


has verbose => (
    is => 'lazy',
);
sub _build_verbose {
    my ($self) = @_;
    return $ENV{PERL_FUTURE_DEBUG} ? 1 : 0;
}


has input => (
    is       => 'ro',
    required => 1,
);


has output => (
    is => 'ro',
);


has loop => (
    is      => 'ro',
    default => sub { IO::Async::Loop->new },
);


has filters => (
    is      => 'rw',
    default => sub { {} },
);

has _msg_channel => (
    is      => 'ro',
    default => sub { IO::Async::Channel->new },
);

has _midi_channel => (
    is      => 'ro',
    default => sub { IO::Async::Channel->new },
);


has midi_out => (
    is      => 'ro',
    default => sub { RtMidiOut->new },
);


sub BUILD {
    my ($self, $args) = @_;

    my $midi_rtn = IO::Async::Routine->new(
        channels_in  => [ $self->_msg_channel ],
        channels_out => [ $self->_midi_channel ],
        model        => 'spawn',
        module       => __PACKAGE__,
        func         => '_rtmidi_loop',
    );
    $self->loop->add($midi_rtn);
    $self->_midi_channel->configure(
        on_recv => sub ($channel, $event) {
            my $dt   = shift @$event;
            my $ev   = shift @$event;
            my $port = shift @$event;
            print "Delta time: $dt, MIDI port: $port\n" if $self->verbose;
            $self->_filter_and_forward($port, $dt, $ev);
        }
    );

    my $input_name = $self->input;
    $self->_msg_channel->send(\$input_name);

    unless ($args->{midi_out}) {
        $self->midi_out->open_virtual_port('RtController');

        _log(sprintf 'Opening %s port %s...', $self->midi_out->{type}, $self->output)
            if $self->verbose;
        _open_port($self->midi_out, $self->output);
        _log(sprintf 'Opened %s port %s', $self->midi_out->{type}, $self->output)
            if $self->verbose;
    }
}

sub _log {
    print join("\n", @_), "\n";
}

sub _open_port($device, $name) {
    $device->open_port_by_name(qr/\Q$name/i)
        || croak "Failed to open port $name";
    return $name;
}

sub _rtmidi_loop ($msg_ch, $midi_ch) {
    my $midi_in = MIDI::RtMidi::FFI::Device->new(type => 'in');
    my $name = _open_port($midi_in, ${ $msg_ch->recv });
    $midi_in->set_callback_decoded(
        sub {
            my (@event) = @_;
            my @e = $event[0] eq 'clock' || $event[0] eq 'start' || $event[0] eq 'stop'
                ? ($event[0], 0) : @event[0, 2];
            $midi_ch->send([ @e, $name ])
        }
    ); # delta-time, event, midi port
    sleep;
}

sub _filter_and_forward ($self, $port, $dt, $event) {
    my $event_filters = $self->filters->{all} // [];
    push @$event_filters, @{ $self->filters->{ $event->[0] } // [] };

    for my $filter (@$event_filters) {
        return if $filter->($port, $dt, $event);
    }

    $self->send_it($event);
}


sub add_filter ($self, $name, $event_type, $action) {
    if ( ref $event_type eq 'ARRAY' ) {
        $self->add_filter( $name, $_, $action ) for @$event_type;
        return;
    }
    _log("Add $name filter for $event_type")
        if $self->verbose;
    push @{ $self->filters->{$event_type} }, $action;
}


sub send_it ($self, $event) {
    _log("Event: @$event") if $self->verbose;
    $self->midi_out->send_event(@$event);
}


sub delay_send ($self, $delay_time, $event) {
    $self->loop->add(
        IO::Async::Timer::Countdown->new(
            delay     => $delay_time,
            on_expire => sub { $self->send_it($event) }
        )->start
    )
}


sub run ($self) {
    $self->loop->run;
}


sub open_controllers ($inputs, $output, $verbose) {
    my %controllers;
    my $name = $inputs->[0];
    my $control = __PACKAGE__->new(
        input   => $name,
        output  => $output,
        verbose => $verbose,
    );
    $controllers{$name} = $control;
    for my $i (@$inputs[1 .. $#$inputs]) {
        $controllers{$i} = __PACKAGE__->new(
            input    => $i,
            loop     => $control->loop,
            midi_out => $control->midi_out,
            verbose  => 1,
        );
    }
    return \%controllers;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MIDI::RtController - Control your MIDI controller

=head1 VERSION

version 0.0801

=head1 SYNOPSIS

  # Control via command line:
  # > perl -MMIDI::RtController -E \
  #   '$rtc = MIDI::RtController->new(input=>shift, output=>shift); $rtc->run' \
  #   keyboard usb
  # now play the keyboard... ctrl-c to exit

  # Filter with a program:
  use MIDI::RtController ();

  my $rtc = MIDI::RtController->new(
    input  => 'input device 1',
    output => 'output device',
  );

  sub filter_notes {
    my ($note) = @_;
    return $note, $note + 7, $note + 12;
  }
  sub filter_tone {
    my ($midi_port, $delta_time, $event) = @_; # 3 required filter arguments
    my ($ev, $channel, $note, $vel) = $event->@*;
    my @notes = filter_notes($note);
    $rtc->send_it([ $ev, $channel, $_, $vel ]) for @notes;
    return 0;
  }

  # respond to specific events:
  $rtc->add_filter('filter_tone', $_, \&filter_tone)
    for qw(note_on note_off);
  # Or:
  $rtc->add_filter('filter_tone', [qw(note_on note_off)], \&filter_tone);

  # respond to all events:
  $rtc->add_filter(
    'echo',
    all => sub {
      my ($port, $dt, $event) = @_;
      print "port: $port, delta-time: $dt, ev: ", join(', ', @$event), "\n"
        unless $event->[0] eq 'clock';
      return 0;
    }
  );

  # add stuff to the $rtc->loop...
  $rtc->run;

  # you can also use multiple input sources simultaneously:
  my $rtc2 = MIDI::RtController->new(
    input    => 'input device 2',
    loop     => $rtc->loop,
    midi_out => $rtc->midi_out,
  );
  $rtc2->run;

=head1 DESCRIPTION

C<MIDI::RtController> allows you to control your MIDI controller using
plug-in filters.

=head1 ATTRIBUTES

=head2 verbose

  $verbose = $rtc->verbose;

Show progress.

=head2 input

  $input = $rtc->input;

Return the MIDI B<input> port.

=head2 output

  $output = $rtc->output;

Return the MIDI B<output> port.

=head2 loop

  $loop = $rtc->loop;

Return the L<IO::Async::Loop>.

=head2 filters

  $filters = $rtc->filters;

Return or set the B<filters>.

=head2 midi_out

  $midi_out = $rtc->midi_out;

Return the B<midi_out> port.

=head1 METHODS

=head2 new

  $rtc = MIDI::RtController->new(%attributes);

Create a new C<MIDI::RtController> object given the above attributes.

=for Pod::Coverage BUILD

=head2 add_filter

  $rtc->add_filter($name, $event_type, $action);

Add a named filter, defined by the CODE reference B<action> for an
B<event_type> like C<note_on> or C<note_off>. An ARRAY reference
of event types like: C<[qw(note_on note_off)]> may also be given.

The special event type C<all> may also be used to refer to any
controller event (e.g. C<note_on>, C<control_change>,
C<pitch_wheel_change>, etc.).

=head2 send_it

  $rtc->send_it($event);

Send a MIDI B<event> to the output port, where the MIDI event is an
ARRAY reference like, C<['note_on', 0, 40, 107]> or
C<['control_change', 0, 1, 24]>, etc.

=head2 delay_send

  $rtc->delay_send($delay_time, $event);

Send a MIDI B<event> to the output port when the B<delay_time> (in
seconds) expires.

=head2 run

  $rtc->run;

Run the asynchronous B<loop>!

=head1 UTILITIES

=head2 open_controllers

  $controllers = MIDI::RtController::open_controllers(
    \@inputs, $output_name, $verbose
  );

Return a hash reference of C<MIDI::RtController> instances, keyed by
each input (given by an array reference of MIDI controller device
names like C<[keyboard,pad,joystick]>).

The B<output_name> (e.g. C<usb>) is used for the MIDI output device
for each instance. The B<verbose> Boolean flag is passed to the
instances.

=head1 THANK YOU

This code would not exist without the help of CPAN's JBARRETT (John
Barrett AKA fuzzix).

=head1 SEE ALSO

The F<eg/*.pl> example programs!

L<MIDI::RtController::Filter::Tonal> - Related module

L<MIDI::RtController::Filter::Math> - Related module

L<MIDI::RtController::Filter::Drums> - Related module

L<Future::AsyncAwait>

L<IO::Async::Channel>

L<IO::Async::Loop>

L<IO::Async::Routine>

L<IO::Async::Timer::Countdown>

L<MIDI::RtMidi::FFI::Device>

L<Moo>

=head1 AUTHOR

Gene Boggs <gene.boggs@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Gene Boggs.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
