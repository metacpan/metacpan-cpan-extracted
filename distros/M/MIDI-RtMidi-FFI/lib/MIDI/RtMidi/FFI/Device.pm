use v5.26;
use warnings;

package MIDI::RtMidi::FFI::Device;

# ABSTRACT: OO interface for MIDI::RtMidi::FFI


use MIDI::RtMidi::FFI ':all';
use Carp qw/ carp croak /;

our $VERSION = '0.12';


sub new {
    my $class = shift;
    my %args = ( @_ == 1 and ref $_[0] eq 'HASH' )
        ? $_[0]->%*
        : @_;
    if ( delete $args{ '14bit_mode' } ) {
        warn "14 bit modes are no longer supported";
        $args{enable_14bit_cc} //= 1;
    }
    delete $args{ type } eq 'in'
        ? RtMidiIn->new( %args )
        : RtMidiOut->new( %args );
}


{
    package RtMidiIn;
    use strict; use warnings;
    sub new {
        shift;
        require MIDI::RtMidi::FFI::Device::In;
        MIDI::RtMidi::FFI::Device::In->new( @_ );
    }
}

{
    package RtMidiOut;
    use strict; use warnings;
    sub new {
        shift;
        require MIDI::RtMidi::FFI::Device::Out;
        MIDI::RtMidi::FFI::Device::Out->new( @_ );
    }
}

1;

#__END__

__END__

=pod

=encoding UTF-8

=head1 NAME

MIDI::RtMidi::FFI::Device - OO interface for MIDI::RtMidi::FFI

=head1 VERSION

version 0.12

=head1 SYNOPSIS

    use MIDI::RtMidi::FFI::Device;

    # Create a new device instance
    my $device = RtMidiOut->new;

    # Open a "virtual port" - this is a virtual MIDI device which may be
    # connected to directly from external synths and software.
    # This is unsupported on Windows.
    $device->open_virtual_port( 'foo' );

    # An alternative to opening a virtual port is connecting to an available
    # MIDI device on your system, such as a loopback device, or virtual or
    # hardware synth. Your device must be connected to some sort of synth to
    # make noise.
    $device->open_port_by_name( qr/wavetable|loopmidi|timidity|fluid/i );

    # Now that a port is open we can start to send MIDI messages, such as
    # this annoying sequence
    while ( 1 ) {
        # Send Middle C (0x3C) to channel 0, strong velocity (0x7A)
        $device->note_on( 0x00, 0x3C, 0x7A );

        # Send a random control change value to Channel 0, CC 1
        $device->cc( 0x00, 0x01, int rand( 128 ) );

        sleep 1;

        # Stop playing Middle C on channel 0
        $device->note_off( 0x00, 0x40 );

        sleep 1;
    }

=head1 DESCRIPTION

MIDI::RtMidi::FFI::Device is an OO interface for L<MIDI::RtMidi::FFI> to help
you manage devices, ports and MIDI events.

See L<MIDI::RtMidi::FFI::Device::In> and L<MIDI::RtMidi::FFI::Device::Out> for
documentation on methods specific to input and output devices respectively.

=head1 METHODS

=head2 new

    my $device = MIDI::RtMidi::FFI::Device->new( %options );
    my $midiin = RtMidiIn->new( %options );
    my $midiout = RtMidiOut->new( %options );

Returns a new MIDI::RtMidi::FFI::Device object. RtMidiIn and RtMidiOut are
provided as shorthand to instantiate L<MIDI::RtMidi::FFI::Device::In> and
L<MIDI::RtMidi::FFI::Device::Out> respectively. Valid attributes:

=head3 type

Device type : 'in' or 'out' (defaults to 'out')

This option is invalid if directly instantiating RtMidiIn, RtMidiOut,
L<MIDI::RtMidi::FFI::Device::In>, or L<MIDI::RtMidi::FFI::Device::Out>.

=head3 name

Device / Client name

=head3 api

MIDI API to use. This should be a L<RtMidiApi
constant|MIDI::RtMidi::FFI/"RtMidiApi">.  By default the device should use the
first compiled API available. See search order notes in L<Using Simultaneous
Multiple APIs|https://caml.music.mcgill.ca/~gary/rtmidi/index.html#multi> on
the RtMidi website.

=head3 api_name

MIDI API to use by name. One of 'alsa', 'jack', 'core', 'winmm' or 'dummy'.

=head2 name

Device name read-only acessor.

=head2 port_name

Port name read-only acessor.

=head2 ok, msg, data, ptr

    warn $device->msg unless $device->ok;

Getters for RtMidiWrapper device struct members

=head2 open_virtual_port

    $device->open_virtual_port( $name );

Open a virtual device port. A virtual device may be connected to other MIDI
software, just as with a hardware device. The name is an arbitrary name of
your choosing, though it is perhaps safest if you stick to plain ASCII for
this.

This method will not work on Windows. See L</Virtual Devices and Windows>
for details and possible workarounds.

=head2 open_port

    $device->open_port( $port, $name );

Open a (numeric) port on a device, with a name of your choosing.

See L</open_port_by_name> for a potentially more flexible option.

=head2 get_ports_by_name

    $device->get_ports_by_name( $name );
    $device->get_ports_by_name( qr/name/ );
    $device->open_port_by_name( [ $name, $othername, qr/anothername/ ] );

Returns a list of port numbers matching the supplied name criteria.

=head2 open_port_by_name

    $device->open_port_by_name( $name );
    $device->open_port_by_name( qr/name/ );
    $device->open_port_by_name( [ $name, $othername, qr/anothername/ ] );

Opens the first port found matching the supplied name criteria.

=head2 get_all_port_nums

    $device->get_all_port_nums();

Return a hashref of ports visible to the device, of the form { port number => port name }

=head2 get_all_port_names

    $device->get_all_port_names();

Return a hashref of ports visible to the device, of the form { port name => port number }

=head2 print_ports

    $device->print_ports();
    $device->print_ports( $handle );

Prints the port number and name of all ports visible to the device.

=head2 close_port

    $device->close_port();

Closes the currently open port

=head2 get_port_count

    $device->get_port_count();

Return the number of available MIDI ports to connect to.

=head2 get_port_name

    $self->get_port_name( $port );

Returns the corresponding port name for the supplied port number.

=head2 get_current_api

    $device->get_current_api();

Returns the MIDI API in use for the device.

This is a L<RtMidiApi constant|MIDI::RtMidi::FFI/"RtMidiApi">.

=head2 get_compiled_api

    $device->get_current_api();

Returns a list of available L<RtMidiApi constant|MIDI::RtMidi::FFI/MIDI APIs>.

=head1 Some MIDI Terms

There are terms specific to MIDI which are somewhat overloaded by this
interface. I will try to disambiguate them here.

=head2 Device

A MIDI device, virtual or physical, is required to mediate MIDI messages.  That
is, you may not simply connect RtMidi to another piece of software without a
virtual or loopback device in between, e.g. via the L</open_virtual_port>
method. RtMidi may talk to connected physical devices directly, without the use
of a virtual device. The same is true of any software-defined virtual or
loopback devices external to your software, RtMidi may connect directly to
these.

"Virtual device" and "virtual port" are effectively interchangeable
terms when using RtMidi - each
MIDI::RtMidi::FFI::Device may represent a single input or output port,
so any virtual device instantiated has a single virtual port.

See L</Virtual Devices and Windows> for caveats and workarounds for virtual
device support on that platform.

=head2 Port

Every MIDI device has at least one port for Input and/or Output.  In hardware,
connections between ports are usually 1:1, though MIDI merging devices exist.
Some software implementations allow for multiple connections to a port.

There is a special Output port usually called "MIDI Thru" or
"MIDI Through" which mirrors every message sent to a given Input port.

=head2 Channel

Each port has 16 channels, numbered 0-15, which are used to route messages
to specifically configured instruments, modules or effects.

Channel must be specified in any message related to performance, such as
"note on" or "control change".

System common and realtime messages do not have a channel.

=head2 Messages and Events

A MIDI message is a (usually) short series of bytes sent on a port, instructing
an instrument on how to behave - which notes to play, when, how loudly, with which
timbral variations & expression, and so on. They may also contain configuration
info, clock and transport signals, or some other sort of instruction.

In this module "events" usually refer to incoming message bytes decoded into a
descriptive sequence of values, or a mechanism for turning these descriptive
sequences into message bytes for ouput.

=head2 General MIDI and Soundfonts

General MIDI is a specification which standardises a single set of musical
instruments, accessed via the "patch change" command. Any of 128 instruments
may be assigned to any of 16 channels, with the exception of channel 10
(0x09) which is reserved for percussion.

Soundfonts are banks of sampled instruments which may be loaded by a General
MIDI compatible softsynth. These can be quite large and complex, though they
usually tend to be small and cheesy. If you remember 90s video game
music or web pages playing .mid files, you're on the right track.

Some implementations also support DLS files, which are similar to soundfonts,
though unlike soundfonts the specification is freely available.

=head1 Virtual Devices and Windows

Windows currently (as of June 2024) lacks built-in support for on-the-fly
creation of virtual MIDI devices. While
L<Windows MIDI Services|https://microsoft.github.io/MIDI/>
will offer dynamic virtual loopback, alongside MIDI 2.0 support, it is a
work in progress.

This situation has resulted in some confusion for MIDI users on Windows,
and a number of solutions exist to work around the issue.

=head2 Loopback Devices

Virtual loopback drivers allow for the
creation of external ports which may be connected to by each participant
in the MIDI conversation.

Rather than create a virtual port, you connect your Perl code to a
virtual loopback device, and connect your DAW or synth to the other side
of the loopback device.

The best currently working virtual loopback drivers based on my research are:

L<loopMIDI|https://www.tobias-erichsen.de/software/loopmidi.html> by
Tobias Erichsen

L<Sbvmidi|https://springbeats.com/sbvmidi/> by Springbeats

L<LoopBe|https://www.nerds.de/en/loopbe1.html> by nerds.de

In my own experience loopMIDI is the simplest and most flexible option,
allowing for arbitrary numbers of devices, with arbitrary names.

You should review the licensing terms of any software you choose to
incorporate into your projects to ensure it is appropriate for your use case.
Each of the above is free for personal, non-commercial use.

=head2 General MIDI

A General MIDI synth called "Microsoft GS Wavetable Synth" should be available
for direct connection on Windows. While the sounds are basic, it can act as a
useful device for testing. This should play a middle-C note on the default
piano instrument:

    use MIDI::RtMidi::FFI::Device;
    my $device = RtMidiOut->new;
    $device->open_port_by_name( qr/gs\ wavetable/i );
    $device->note_on( 0x00, 0xc3, 0x7f );
    sleep( 1 );
    $device->note_off( 0x00, 0xc3 );

=head1 General MIDI on Linux

The days of consumer sound cards containing their own wavetable banks are
behind us.  These days, General MIDI is usually supported in software.

A commonly available General MIDI soft-synth is
L<TiMidity++|https://timidity.sourceforge.net/> - a version is likely packaged
for your distro. This package may or
may not install a timidity service (it may be packaged separately as
timidity-daemon). If not, you can quickly make a timidity port available by
running:

    $ timidity -iAD

You may also need to install and configure a soundfont for TiMidity++.

Another option is FluidSynth, which should also be packaged for any given
distro. To run FluidSynth you'll need a SF2 or SF3 soundfont file. See
L<Getting started with fluidsynth|https://github.com/FluidSynth/fluidsynth/wiki/GettingStarted>
and
L<Example Command Lines to start fluidsynth|https://github.com/FluidSynth/fluidsynth/wiki/ExampleCommandLines>.
L<FluidR3_GM.sf2 Professional|https://musical-artifacts.com/artifacts/738>
is a high quality sound font with a complete set of General MIDI instruments.

A typical FluidSynth invocation on Linux might be:

    $ fluidsynth -a pulseaudio -m alsa_seq -g 1.0 your_soundfont.sf2

=head1 General MIDI on MacOS

An Audio Unit named DLSMusicDevice is available for use within GarageBand,
Logic, and other Digital Audio Workstation (DAW) software on MacOS.

If you wish to use banks other than the default QuickTime set, place
them in C<~/Library/Audio/Sounds/Banks/>. You may now create a new track
within GarageBand or Logic with the DLSMusicDevice instrument, and
select your Sound Bank within the settings for this instrument.

The next step is to open a virtual port, which should autoconnect within
your DAW and be ready to send performance info to DLSMusicDevice:

    # Open virtual port with a name of your choosing
    $device->open_virtual_port('My Snazzy Port');
    # Send middle C
    $device->note_on( 0x00, 0xc3, 0x7f );
    sleep( 1 );
    $device->note_off( 0x00, 0xc3 );

The 'MUS 214: MIDI Composition' channel on YouTube has a
L<Video on setting up DLSMusicDevice in Logic|https://youtu.be/YIb-H10yzyI>.

A potential alternative option is FluidSynth. This has more limited support for
DLS banks but should load SF2/3 banks just fine. See L</General MIDI on Linux>
for links to get started using FluidSynth. A typical FluidSynth invocation on
MacOS might be:

    % fluidsynth -a coreaudio -m coremidi your_soundfont.sf2

=head1 KNOWN ISSUES

The callback interface does not currently work on threaded perls. Most, if not
all, perls currently built for Windows are threaded. I have been working around
this with a non-threaded Perl built within the cygwin environment with
perlbrew. See L<MIDI::RtMidi::FFI::Device::In/get_fh> for an alternative
approach to callback-driven operation.

Test coverage, both automated testing and hands-on testing, is limited. Some
elements of this module (especially around 14 bit CC and (N)RPN) are based on
reading, and probably often misreading, MIDI specifications, device
documentation and forum posts. Issues in the Codeberg.org repo are more than
welcome, even if just to ask questions. You may also find me in #perl-music
on irc.perl.org - look for fuzzix.

This software has been fairly well exercised on Linux and Windows, but not
so much on MacOS / CoreMIDI. I am interested in feedback on successes
and failures on this platform.

NRPN and 14 bit CC have not been tested on real hardware, though they work
well in the "virtual" domain - for controlling software-defined instruments.

L<Currently open MIDI::RtMidi::FFI issues on Codeberg.org|https://codeberg.org/jbarrett/MIDI-RtMidi-FFI/issues>

=head1 SEE ALSO

L<RtMidi|https://caml.music.mcgill.ca/~gary/rtmidi/>

L<Sound on Sound's MIDI Basics series|https://www.soundonsound.com/series/midi-basics>

L<MIDI CC & NRPN database|https://midi.guide/>

L<Phil Rees Music Tech page on NRPN/RPN|http://www.philrees.co.uk/nrpnq.htm>

L<MIDI::RtMidi::FFI>

L<MIDI::Event>

=head1 CONTRIBUTING

L<https://codeberg.org/jbarrett/MIDI-RtMidi-FFI>

LLM-generated (or "assisted") contributions are not welcome.

All other comments and contributions welcome.

=head1 BUGS AND SUPPORT

Please direct all requests to L<https://codeberg.org/jbarrett/MIDI-RtMidi-FFI/issues>

=head1 CONTRIBUTORS

=over 4

=item *

Gene Boggs L<https://metacpan.org/author/GENE>

=back

=head1 AUTHOR

John Barrett <john@jbrt.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by John Barrett.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
