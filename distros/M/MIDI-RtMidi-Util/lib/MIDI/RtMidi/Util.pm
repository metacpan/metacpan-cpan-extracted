package MIDI::RtMidi::Util;
our $AUTHORITY = 'cpan:GENE';

# ABSTRACT: Handy Utilities for Real-time MIDI

our $VERSION = '0.0500';

use v5.40;
# use Data::Dumper::Compact qw(ddc);
use MIDI::RtMidi::FFI::Device ();
use Exporter 'import';

our @EXPORT = qw(
    in_port
    out_port
    stop_device
    input_ports
    output_ports
    stop_all_notes
    program_changer
);


sub in_port ($name) {
    my $midi_in = RtMidiIn->new;
    try { $midi_in->open_port_by_name(qr/\Q$name/i) }
    catch ($e) { die "Can't open MIDI port: $name\n" }
    return $midi_in;
}


sub out_port ($name) {
    my $midi_out = RtMidiOut->new;
    try { $midi_out->open_virtual_port('RtMidiOut') } # needed for mac
    catch ($e) {
        # warn 'Not a Mac';
    }
    try { $midi_out->open_port_by_name(qr/\Q$name/i) }
    catch ($e) { die "Can't open MIDI port: $name\n" }
    return $midi_out;
}


sub stop_device ($device) {
    try {
        $device->stop;
        $device->panic;
    }
    catch ($e) {
        chomp $e;
        warn "Can't stop the MIDI device: $e\n";
    }
}


sub stop_all_notes ($device) {
    for my $chan (0 .. 15) {
        for my $n (0 .. 127) {
            $device->note_off($chan, $n, 0);
        }
    }
}


sub input_ports () {
    my $device = RtMidiIn->new;
    return [
        map { $device->get_port_name($_) }
            sort { $a <=> $b } keys $device->get_all_port_nums->%*
    ];
}


sub output_ports () {
    my $device = RtMidiOut->new;
    return [
        map { $device->get_port_name($_) }
            sort { $a <=> $b } keys $device->get_all_port_nums->%*
    ];
}


sub program_changer ($device, $program = 0, $channel = 0, $msb_bank = 0, $lsb_bank = undef) {
    try {
        $device->control_change($channel, 0, $msb_bank);
        $device->control_change($channel, 32, $lsb_bank) if defined $lsb_bank;
        $device->program_change($channel, $program);
    }
    catch ($e) {
        # BUGFIX: errors usually end in a newline already; avoid a doubled one.
        chomp $e;
        die "ERROR: $e\n";
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MIDI::RtMidi::Util - Handy Utilities for Real-time MIDI

=head1 VERSION

version 0.0500

=head1 SYNOPSIS

  use MIDI::RtMidi::Util qw(out_port stop_device input_ports output_ports);

  my $ports = input_ports(); # e.g. ['USB MIDI Interface', ...]
  $ports = output_ports();

  my $midi_in  = in_port('keyboard');
  my $midi_out = out_port('usb');
  # Do something cool ...

  END {
    stop_device($midi_out);
    stop_all_notes($midi_out);
  }

=head1 DESCRIPTION

C<MIDI::RtMidi::Util> is a junk drawer for Real-time MIDI utilities.

=head1 FUNCTIONS

=head2 in_port

  $in_port = in_port($name);

Open and return a named L<MIDI::RtMidi::FFI::Device> C<RtMidiIn> device.

This function takes a unique part of an open port name as its argument.

=head2 out_port

  $out_port = out_port($name);

Open and return a named L<MIDI::RtMidi::FFI::Device> C<RtMidiOut> device.

This function takes a unique part of an open port name as its argument.

=head2 stop_device

  stop_device($device);

Stop an open C<MIDI::RtMidi::FFI::Device> device.

=head2 stop_all_notes

  stop_all_notes($device);

Send a C<note_off()> message to all 16 channels and all 128 notes.

=head2 input_ports

  $input_ports = input_ports();

Return an array-reference of open MIDI input port names.

=head2 output_ports

  $output_ports = output_ports();

Return an array-reference of open MIDI output port names.

=head2 program_changer

  program_changer($device, $program, $channel, $msb_bank, $lsb_bank);

Send a bank select (CC 0 MSB, and CC 32 LSB when given) followed by a
program change.  All arguments but the device are optional and default
to C<0> (the LSB is skipped if it is not defined).

=head1 SEE ALSO

L<MIDI::RtMidi::FFI::Device>

=head1 AUTHOR

Gene Boggs <gene.boggs@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Gene Boggs.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
