
=head1 NAME

Device::Osram::Lightify::API - API Documentation

=head1 API Overview

The starting point for using this module is that you have a hub with
an IP address upon your local LAN, which is able to communicate successfully
with any installed bulbs you have.

The module itself is responsible for talking to your hub, and sending
commands to it to initiate actions, or perform introspection, so you'll
need the IP address of your hub available.

=cut

=head1 Overview

The communication to/from the hub is carried out via short binary
communication with the hub over TCP/IP on port 4000.

=cut

=head1 Light Discovery

To discover the lights which are available to your hub we connect and
send the following binary string to it:

=for example begin

    0x0B 0x00 0x00 0x13 0x00 0x00 0x00 0x00 0x01 0x00 0x00 0x00 0x00

=for example end

Once sent we then read back a header.  The header contains 11 bytes
of reply.  From this header we read the 10th byte which will tell us
the number of bulbs which are available.

Once we know the number of lights we can then read 50 bytes for each
one, and this block of data can be parsed to show the current state
of that specific bulb.

=for example begin

  01 - ID byte 1
  02 - ID byte 2
  03 - MAC Address 1
  04 - MAC Address 2
  05 - MAC Address 3
  05 - MAC Address 4
  06 - MAC Address 5
  07 - MAC Address 6
  08 - MAC Address 7
  09 - MAC Address 8
  10 - Bulb Type
  11 - Firmware Version 1
  12 - Firmware Version 2
  13 - Firmware Version 3
  14 - Firmware Version 4
  15 - Online/Offline
  16 - Group ID 1
  17 - Group ID 2
  18 - Status 0 == off, 1 == on
  19 - Brightness (0-100)
  20 - Temperature 1
  21 - Temperature 2
  22 - R
  23 - G
  24 - B
  25 - W
  26 - Name 1
  27 - Name 2
  28 - Name 3
  29 - Name 4
  30 - Name 5
  31 - Name 6
  .. - Name 15

=for example end

B<NOTE> The returned 50 bytes are NULL-terminated/padded.

You'll almost certainly want to make sure you can parse this stuff,
because users will want to operate upon bulbs by name - and the API
only allows you to operate on specific devices by MAC-address, so at
the very least you must be able to lookup `NAME -> MAC`.

=cut


=head1 Broadcast

There are two simple commands which will turn B<all> lights on, or off,
these are simple to get started with because you don't need to set the
MAC address of the bulb inside the command.

To turn all bulbs on send this:

=for example begin

    0x0f 0x00 0x00 0x32 0x01 0x00 0x00 0x00 0xff 0xff 0xff 0xff 0xff 0xff 0xff 0xff 0x01

=for example end

To turn all bulbs off send this:

=for example begin

    0x0f 0x00 0x00 0x32 0x01 0x00 0x00 0x00 0xff 0xff 0xff 0xff 0xff 0xff 0xff 0xff 0x00

=for example end

Once sent read back 20 bytes to get your result.

=cut


=head1 Light-Specific Commands

The rest of the commands are going to be bulb-specific, and involve
sending a command with the MAC address of the destination device inside
their bodies.

It seems to be the case that we need to set a session ID with each
command, to avoid issues with commands being dropped as previously-seen
or otherwise prevent replay-attacks.

I've denoted such bytes as SS SS SS SS in the following commands.

=cut

=head2 On/Off

To set a specific bulb ON or OFF you need to send the following
magic string:

=for example begin

    0F 00 00 32 SS SS SS SS NN NN NN NN NN NN NN NN ON

=for example end

Here `NN` should be replaced with the MAC address of the device you
wish to control, backwards, and the last byte C<ON> should be replaced
by C<0x00> to turn the device off, and C<0x01> to turn it on.

Once set read back 20 bytes to get your result.

=cut

=head2 Brightness

To set a specific brightness for a bulb you need to send the following
magic string:

=for example begin

     11 00 00 31 SS SS SS SS NN NN NN NN NN NN NN NN XX 00 00

=for example end

Here `NN` should be replaced with the MAC address of the device you
wish to control, backwards, and the byte C<XX> should be replaced
with the brighness level you wish to set, in the range 0-100.

Once sent read back 20 bytes to get your result.

=cut

=head2 Colour

To set specific RGBW values for a bulb you need to send the following
magic string:

=for example begin

 14 00 00 36 SS SS SS SS NN NN NN NN NN NN NN NN RR GG BB WW 00 00

=for example end

Here `NN` should be replaced with the MAC address of the device you
wish to control, backwards, and the bytes RR,GG,BB,WW should be updated
with the appropriate values.

Once sent read back 20 bytes to get your result.

=cut


use strict;
use warnings;

1;
