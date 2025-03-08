package MIDI::RtController;
our $AUTHORITY = 'cpan:GENE';

# ABSTRACT: Control your MIDI controller

use v5.36;

our $VERSION = '0.0201';

use Moo;
use strictures 2;
use Carp qw(croak carp);
use Future::AsyncAwait;
use IO::Async::Channel ();
use IO::Async::Loop ();
use IO::Async::Routine ();
use IO::Async::Timer::Countdown ();
use MIDI::RtMidi::FFI::Device ();
use namespace::clean;


has verbose => (
    is      => 'ro',
    isa     => sub { croak "$_[0] is not a boolean" unless $_[0] =~ /^[01]$/ },
    default => sub { 0 },
);


has input => (
    is       => 'ro',
    required => 1,
);


has output => (
    is       => 'ro',
    required => 1,
);


has loop => (
    is      => 'ro',
    default => sub { IO::Async::Loop->new },
);


has filters => (
    is      => 'rw',
    default => sub { {} },
);

# Private attributes

has _msg_channel => (
    is      => 'ro',
    default => sub { IO::Async::Channel->new },
);

has _midi_channel => (
    is      => 'ro',
    default => sub { IO::Async::Channel->new },
);

has _midi_out => (
    is      => 'ro',
    default => sub { RtMidiOut->new },
);


sub BUILD {
    my ($self) = @_;
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
            $self->_filter_and_forward($event);
        }
    );
    my $input_name = $self->input;
    $self->_msg_channel->send(\$input_name);

    $self->_midi_out->open_virtual_port('foo');
    _open_port($self->_midi_out, $self->output);
}

sub _log {
    return unless $ENV{PERL_FUTURE_DEBUG};
    carp @_;
}

sub _open_port($device, $name) {
    _log("Opening $device->{type} port $name ...");
    $device->open_port_by_name(qr/\Q$name/i)
        || croak "Failed to open port $name";
    _log("Opened $device->{type} port $name");
}

sub _rtmidi_loop ($msg_ch, $midi_ch) {
    my $midi_in = MIDI::RtMidi::FFI::Device->new(type => 'in');
    _open_port($midi_in, ${ $msg_ch->recv });
    $midi_in->set_callback_decoded(sub { $midi_ch->send($_[2]) });
    sleep;
}

sub _filter_and_forward ($self, $event) {
    my $event_filters = $self->filters->{ $event->[0] } // [];
    for my $filter ($event_filters->@*) {
        return if $filter->($event);
    }
    $self->send_it($event);
}


sub send_it ($self, $event) {
    $self->_midi_out->send_event($event->@*);
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


sub add_filter ($self, $event_type, $action) {
    push $self->filters->{$event_type}->@*, $action;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MIDI::RtController - Control your MIDI controller

=head1 VERSION

version 0.0201

=head1 SYNOPSIS

  use MIDI::RtController ();

  my $rtc = MIDI::RtController->new(
    input  => 'input-MIDI-device',
    output => 'output-MIDI-device',
  );

  sub filter_notes {
    my ($note) = @_;
    return $note, $note + 7, $note + 12;
  }
  sub filter_tone {
    my ($event) = @_;
    my ($ev, $channel, $note, $vel) = $event->@*;
    my @notes = filter_notes($note);
    $rtc->send_it([ $ev, $channel, $_, $vel ]) for @notes;
    return 0;
  }

  $rtc->add_filter($_ => \&pedal_tone) for qw(note_on note_off);

  # add other stuff to the $rtc->loop...

  $rtc->run;

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

=head1 METHODS

=head2 new

  $rtc = MIDI::RtController->new(verbose => 1);

Create a new C<MIDI::RtController> object.

=for Pod::Coverage BUILD

=head2 send_it

  $rtc->send_it($event);

Send a MIDI B<event> to the output port.

=head2 delay_send

  $rtc->delay_send($delay_time, $event);

Send a MIDI B<event> to the output port when the B<delay_time> expires.

=head2 run

  $rtc->run;

Run the B<loop>!

=head2 add_filter

  $rtc->add_filter($event_type, $action);

Add a filter, defined by the CODE reference B<action>, for an
B<event_type> like C<note_on> or B<note_off>.

=head1 SEE ALSO

The F<eg/*.pl> program(s)

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
