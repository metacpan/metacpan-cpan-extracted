package Device::Yeelight::Light;

use 5.026;
use utf8;
use strict;
use warnings;

use Carp;
use JSON;
use IO::Socket;

=encoding utf8
=head1 NAME

Device::Yeelight::Light - WiFi Smart LED Light

=head1 VERSION

Version 0.10

=cut

our $VERSION = '0.10';

=head1 SYNOPSIS

This module provides base class for Yeelight smart device

=head1 SUBROUTINES/METHODS

=head2 new

Creates new Yeelight light device.

=cut

sub new {
    my $class = shift;
    my $data  = {
        id       => undef,
        location => 'yeelight://',
        support  => [],
        @_,
        _socket          => undef,
        _next_command_id => 1,
    };
    return bless( $data, $class );
}

sub DESTROY {
    my $self = shift;
    $self->{_socket}->close if defined $self->{_socket};
}

=head2 is_supported

Checks if method is supported by the device.

=cut

sub is_supported {
    my $self = shift;
    my ($method) = @_;

    unless ( grep { $method =~ m/::$_$/ } @{ $self->{support} } ) {
        carp "$method is not supported by this device";
        return;
    }

    return 1;
}

sub AUTOLOAD {
    my $self = shift;
    our $AUTOLOAD;
    return unless $self->is_supported($AUTOLOAD);
    $self->call( $AUTOLOAD, @_ );
    return $self;
}

sub command_id {
    my $self = shift;
    $self->{_next_command_id}++;
}

=head2 connection

Create and return socket connected to the device.

=cut

sub connection {
    my $self = shift;
    return $self->{_socket}
      if defined $self->{_socket} and $self->{_socket}->connected;
    my ( $addr, $port ) = $self->{location} =~ m#yeelight://([^:]*):(\d*)#;
    $self->{_socket} = IO::Socket::INET->new(
        PeerAddr  => $addr,
        PeerPort  => $port,
        ReuseAddr => 1,
        Proto     => 'tcp',
    ) or croak $!;
    return $self->{_socket};
}

=head2 call

Sends command to device.

=cut

sub call {
    my $self = shift;
    my ( $cmd, @params ) = @_;
    my $id = $self->command_id;

    my $package = __PACKAGE__;
    my $json    = encode_json(
        {
            id     => $id,
            method => $cmd =~ s/^${package}:://r,
            params => \@params,
        }
    );
    $self->connection->send("$json\r\n") or croak $!;

    my $buffer;
    while ( not $self->connection->recv( $buffer, 4096 ) ) {
        my $response = decode_json($buffer);

        # Ignore notification messages
        next if not defined $response->{id};
        carp "Received response to unkown command $response->{id}"
          if $response->{id} != $id;
        if ( defined $response->{error} ) {
            carp
              "$response->{error}->{message} (code $response->{error}->{code})";
            return;
        }
        return @{ $response->{result} };
    }
}

=head1 Yeelight API CALLS

=cut

use subs
  qw/get_prop set_ct_abx set_rgb set_hsv set_bright set_power toggle set_default start_cf stop_cf set_scene cron_add cron_get cron_del set_adjust set_music set_name bg_set_rgb bg_set_hsv bg_set_ct_abx bg_start_cf bg_stop_cf bg_set_scene bg_set_default bg_set_power bg_set_bright bg_set_adjust bg_toggle dev_toggle adjust_bright adjust_ct adjust_color bg_adjust_bright bg_adjust_ct/;

=head2 get_prop

This method is used to retrieve current property of smart LED.

=cut

sub get_prop {
    my $self = shift;
    my (@properties) = @_;
    return unless $self->is_supported( ( caller(0) )[3] );
    my @res = $self->call( 'get_prop', @_ );
    my $props;
    for my $i ( 0 .. $#properties ) {
        $props->{ $properties[$i] } = $res[$i];
    }
    return $props;
}

=head2 set_ct_abx

This method is used to change the color temperature of a smart LED.

=head4 Parameters

=over

=item ct_value

Target color temperature. The type is integer and range is 1700 ~ 6500 (k).

=item effect

Support two values: I<sudden> and I<smooth>. If effect is I<sudden>, then the
color temperature will be changed directly to target value, under this case,
the third parameter I<duration> is ignored. If effect is I<smooth>, then the
color temperature will be changed to target value in a gradual fashion, under
this case, the total time of gradual change is specified in third parameter
I<duration>.

=item duration

Specifies the total time of the gradual changing. The unit is milliseconds. The
minimum support duration is 30 milliseconds.

=back

=head2 set_rgb

This method is used to change the color of a smart LED.

=head4 Parameters

=over

=item rgb_value

Target color, whose type is integer. It should be expressed in decimal integer
ranges from 0 to 16777215 (hex: 0xFFFFFF).

=item effect

Refer to C<set_ct_abx> method.

=item duration

Refer to C<set_ct_abx> method.

=back

=head2 set_hsv

This method is used to change the color of a smart LED.

=head4 Parameters

=over

=item hue

Target hue value, whose type is integer. It should be expressed in decimal
integer ranges from 0 to 359.

=item sat

Target saturation value whose type is integer. It's range is 0 to 100.

=item effect

Refer to C<set_ct_abx> method.

=item duration

Refer to C<set_ct_abx> method.

=back

=head2 set_bright

This method is used to change the brightness of a smart LED.

=head4 Parameters

=over

=item brightness

Target brightness. The type is integer and ranges from 1 to 100. The brightness
is a percentage instead of a absolute value. 100 means maximum brightness while
1 means the minimum brightness.

=item effect

Refer to C<set_ct_abx> method.

=item duration

Refer to C<set_ct_abx> method.

=back

=head2 set_power

This method is used to switch on or off the smart LED (software
managed on/off).

=head4 Parameters

=over

=item power

Can only be I<on> or I<off>. I<on> means turn on the smart LED, I<off> means turn
off the smart LED.

=item effect

Refer to C<set_ct_abx> method.

=item duration

Refer to C<set_ct_abx> method.

=item mode
(optional parameter)

=over

=item 0
Normal turn on operation (default value)

=item 1
Turn on and switch to CT mode.

=item 2
Turn on and switch to RGB mode.

=item 3
Turn on and switch to HSV mode.

=item 4
Turn on and switch to color flow mode.

=item 5
Turn on and switch to Night light mode. (Ceiling light only).

=back

=back

=head2 toggle

This method is used to toggle the smart LED.

=head2 set_default

This method is used to save current state of smart LED in persistent memory. So
if user powers off and then powers on the smart LED again (hard power reset),
the smart LED will show last saved state.

=head2 start_cf

This method is used to start a color flow. Color flow is a series of smart LED
visible state changing. It can be brightness changing, color changing or color
temperature changing. This is the most powerful command.

=head4 Parameters

=over

=item count

Total number of visible state changing before color flow stopped. 0 means
infinite loop on the state changing.

=item action

The action taken after the flow is stopped.

=over

=item 0
means smart LED recover to the state before the color flow started.

=item 1
means smart LED stay at the state when the flow is stopped.

=item 2
means turn off the smart LED after the flow is stopped.

=back

=item flow_expression

The expression of the state changing series.

=over

=item Duration

Gradual change time or sleep time, in milliseconds, minimum value 50.

=item Mode

=over

=item 1
color

=item 2
color temperature

=item 7
sleep

=back

=item Value

=over

=item
RGB value when mode is 1,

=item
CT value when mode is 2,

=item
Ignored when mode is 7

=back

=item Brightness

Brightness value, -1 or 1 ~ 100. Ignored when mode is 7. When this value is
-1, brightness in this tuple is ignored (only color or CT change takes effec

=back

=back

=head2 stop_cf

This method is used to stop a running color flow.

=head2 set_scene

This method is used to set the smart LED directly to specified state. If the
smart LED is off, then it will turn on the smart LED firstly and then apply the
specified command.

=head4 Parameters

=over

=item class

=over

=item I<color>
means change the smart LED to specified color and brightness

=item I<hsv>
means change the smart LED to specified color and brightness

=item I<ct>
means change the smart LED to specified ct and brightness

=item I<cf>
means start a color flow in specified fashion

=item I<auto_delay_off>
means turn on the smart LED to specified brightness and start a sleep timer to
turn off the light after the specified minutes

=back

=item val1

=item val2

=item val3

=back

=head2 cron_add

This method is used to start a timer job on the smart LED.

=head4 Parameters

=over

=item type

Currently can only be 0 (means power off).

=item value

Length of the timer (in minutes).

=back

=head2 cron_get

This method is used to retrieve the setting of the current cron job of the
specified type.

=head4 Parameters

=over

=item type

The type of the cron job (currently only support 0).

=back

=head2 cron_del

This method is used to stop the specified cron job.

=head4 Parameters

=over

=item type

The type of the cron job (currently only support 0).

=back

=head2 set_adjust

This method is used to change brightness, CT or color of a smart LED without
knowing the current value, it's main used by controllers.

=head4 Parameters

=over

=item action

The direction of the adjustment, the valid value can be:

=over

=item I<increase>
increase the specified property

=item I<decrease>
decrease the specified property

=item I<circle>
increase the specified property, after it reaches the max value, go back to
minimum value

=back

=item prop

The property to adjust. The valid value can be:

=over

=item I<bright>
adjust brightness

=item I<ct>
adjust color temperature

=item I<color>
adjust color.

(When C<prop> is I<color>, the C<action> can only be I<circle>, otherwise, it
will be deemed as invalid request.)

=back

=back

=head2 set_music

This method is used to start or stop music mode on a device. Under music mode,
no property will be reported and no message quota is checked.

=head4 Parameters

=over

=item action

The action of C<set_music> command. The valid value can be:

=over

=item 0
turn off music mode

=item 1
turn on music mode

=back

=item host

The IP address of the music server.

=item port

The TCP port music application is listening on.

=back

=head2 set_name

This method is used to name the device. The name will be stored on the device
and reported in discovering response. User can also read the name through
C<get_prop> method.

=head4 Parameters

=over

=item name

The name of the device.

=back

=head2 adjust_bright

This method is used to adjust the brightness by specified percentage within
specified duration.

=head4 Parameters

=over

=item percentage

The percentage to be adjusted. The range is: -100 ~ 100

=item duration

Refer to "set_ct_abx" method.

=back

=head2 adjust_ct

This method is used to adjust the color temperature by specified percentage
within specified duration.

=head4 Parameters

=over

=item percentage

The percentage to be adjusted. The range is: -100 ~ 100

=item duration

Refer to "set_ct_abx" method.

=back

=head2 adjust_color

This method is used to adjust the color within specified duration.

=head4 Parameters

=over

=item percentage

The percentage to be adjusted. The range is: -100 ~ 100

=item duration

Refer to "set_ct_abx" method.

=back

=head2 bg_set_xxx / bg_toggle

These methods are used to control background light, for each command detail,
refer to set_xxx command.

Refer to C<set_xxx> command.

=head2 bg_adjust_xxx

This method is used to adjust background light by specified percentage within
specified duration.

Refer to C<adjust_bright>, C<adjust_ct>, C<adjust_color>.

=head2 dev_toggle

This method is used to toggle the main light and background light at the same
time.

=head1 AUTHOR

Jan Baier, C<< <jan.baier at amagical.net> >>

=head1 SEE ALSO

This API is described in the Yeeling WiFi Light Inter-Operation Specification.

=head1 LICENSE AND COPYRIGHT

Copyright 2019 Jan Baier.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

=cut

1;    # End of Device::Yeelight
