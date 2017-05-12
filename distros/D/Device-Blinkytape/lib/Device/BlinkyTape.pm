package Device::BlinkyTape;
use strict;
BEGIN {
    our $AUTHORITY = 'cpan:OKKO'; # AUTHORITY
    our $VERSION = '0.004'; # VERSION
}
use Moose;
use Device::SerialPort;
use Device::BlinkyTape::SimulationPort;
use Moose::Util::TypeConstraints;
use utf8;

=encoding utf-8
=cut

# ABSTRACT: Control a BlinkyTape led strip

=for Pod::Coverage BUILD

=head1 NAME

Device::BlinkyTape - Control a BlinkyTape led strip

=head1 SYNOPSIS

    use Device::BlinkyTape::WS2811; # BlinkyTape uses WS2811
    my $bb = Device::BlinkyTape::WS2811->new(dev => '/dev/tty.usbmodem');
    # Set all led pixels on full white
    $bb->all_on();
    # Set all led pixels off
    $bb->all_off();

    # Send a white pixel (RGB 255/255/255).
    # Pixels are sent one by one from left to right.
    $bb->send_pixel(255,255,255);
    $bb->send_pixel(5,5,5);
    # Show all sent pixels and reset send_pixel to the first pixel.
    $bb->show();

=cut

# These Moose subtypes are defined for isa validation.
subtype 'GammaInt',
    as 'Int',
    where { $_ >= 0 and $_ <= 255 },
    message { "Gamma number ($_) must be between 0..255" }
;

subtype 'DeviceSerialPort',
    as 'Device::SerialPort'
;

subtype 'SimulationPort',
    as 'Device::BlinkyTape::SimulationPort'
;

=head2 dev

The device where your usb ledstrip is at. Defaults to /dev/tty.usbmodem.

=cut

has 'dev' => (is => 'rw', isa => 'Str', default => '/dev/tty.usbmodem');

=head2 port

Instead of giving the device you can create the instance of this module by directly
giving it a Device:SerialPort object. By default the Device::SerialPort object
is created from the device given in the 'dev' parameter.

=cut

has 'port' => (is => 'rw', isa => 'DeviceSerialPort | SimulationPort');

=head2 gamma

Specify the gamma correction. Defaults to [1,1,1]

=cut

has 'gamma' => (is => 'rw', isa => 'ArrayRef[GammaInt]', default => sub { [1,1,1] });

=head2 led_count

Specify the led count, counting from 1. The default is 60.

=cut

has 'led_count' => (is => 'rw', isa => 'Int', default => 60);

=head2 simulate

Specify if the module should simulate a BlinkyTape onscreen instead of using one in the usb port.
Defaults to 0 (false). If this is true then the port and dev parameters have no effect.

=cut

has 'simulate' => (is => 'rw', isa => 'Bool', default => 0);

=head2 sleeptime

Sending data too fast freezes the BlinkyTape. Sleeping for 30 microseconds between each byte
makes sure the atmega processor of the BlinkyTape can keep up with the incoming data.

=cut

has 'sleeptime' => (is => 'rw', default => 30);

sub BUILD {
    my $self = shift;
    # Initialize $self->port from $self->dev if one was not given in new
    if ($self->simulate) {
        $self->port(Device::BlinkyTape::SimulationPort->new(led_count => $self->led_count));
        warn 'simulation on.';
    }
    $self->port(Device::SerialPort->new($self->dev)) if (!$self->port);
    
    if ($self->port) {
        # Set default communication settings
        $self->port->baudrate(19200);
        $self->port->databits(8);
        $self->port->parity('none');
        $self->port->stopbits(1);
    }

    # $self->lookclear; # empty buffers
}

=head2 all_on

Turns all leds on.

=cut

sub all_on {
    my $self = shift;
    for (my $a=0; $a<=$self->led_count-1; $a++) {
        $self->send_pixel(255,255,255);
    }
    $self->show();
}

=head2 all_off

Turns all leds off.

=cut

sub all_off {
    my $self = shift;
    for (my $a=0; $a<=$self->led_count-1; $a++) {
        $self->send_pixel(0,0,0);
    }
    $self->show();
}

1;

=head2 send_pixel(r,g,b)

Send the RGB value for the next pixel. Values 0-254 are sent as is, value 255 is converted to 254.

=cut

=head2 show

Shows the sent pixels and resets the send_pixel to the first led pixel of the strip. This is done
by sending a single 255 value byte to the led strip.

=cut

=head1 ABOUT BLINKYTAPE

Blinkytape is a controllable led strip available at http://blinkiverse.com/blinkytape/

=cut

=head1 USING THE MODULE ON OS X WITHOUT OWNING A BLINKYTAPE

This module comes with a BlinkyTape simulator. Install X11 server to use the simulator:
    http://xquartz.macosforge.org/landing/

=cut

=head1 BUGS

The device is not yet available so the module has been implemented by inspecting partly
undocumented and unfinished code in other languages. Feel free to file any bug reports
in Github, patches welcome.

=cut

=head1 REFERENCE READING

Communicating with the Arduino in Perl http://playground.arduino.cc/interfacing/PERL

Perl communication to Arduino over serial USB http://www.windmeadow.com/node/38

=cut

=head1 AUTHOR

Oskari Okko Ojala E<lt>okko@cpan.orgE<gt>

Based on exampls/Blinkyboard.py in Blinkiverse's BlinkyTape repository at
https://github.com/blinkiverse/BlinkyTape/ 
by Max Henstell (mhenstell) and Marty McGuire (martymcguire).

=cut

=head1 COPYRIGHT AND LICENSE

Copyright (C) Oskari Okko Ojala 2013

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl you may have available.

=cut
