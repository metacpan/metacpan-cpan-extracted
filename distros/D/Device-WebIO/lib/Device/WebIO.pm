# Copyright (c) 2014  Timm Murray
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without 
# modification, are permitted provided that the following conditions are met:
# 
#     * Redistributions of source code must retain the above copyright notice, 
#       this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright 
#       notice, this list of conditions and the following disclaimer in the 
#       documentation and/or other materials provided with the distribution.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE 
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
# POSSIBILITY OF SUCH DAMAGE.
package Device::WebIO;
$Device::WebIO::VERSION = '0.010';
# ABSTRACT: Duct Tape for the Internet of Things
use v5.12;
use Moo;
use namespace::clean;
use Device::WebIO::Exceptions;

has '_device_by_name' => (
    is      => 'ro',
    default => sub {{
    }},
);


sub register
{
    my ($self, $name, $device) = @_;
    $self->_device_by_name->{$name} = $device;
    return 1;
}


sub pin_desc
{
    my ($self, $name) = @_;
    my $obj = $self->_get_obj( $name );
    return $obj->pin_desc;
}

sub all_desc
{
    my ($self, $name) = @_;
    my $obj = $self->_get_obj( $name );
    return $obj->all_desc;
}


sub set_as_input
{
    my ($self, $name, $pin) = @_;
    my $obj = $self->_get_obj( $name );
    $self->_role_check( $obj, 'DigitalInput' );
    $self->_pin_count_check( $name, $obj, $pin, 'DigitalInput' );
    $obj->set_as_input( $pin );
    return 1;
}

sub set_as_output
{
    my ($self, $name, $pin) = @_;
    my $obj = $self->_get_obj( $name );
    $self->_role_check( $obj, 'DigitalOutput' );
    $self->_pin_count_check( $name, $obj, $pin, 'DigitalOutput' );
    $obj->set_as_output( $pin );
    return 1;
}

sub is_set_input
{
    my ($self, $name, $pin) = @_;
    my $obj = $self->_get_obj( $name );
    $self->_role_check( $obj, 'DigitalInput' );
    $self->_pin_count_check( $name, $obj, $pin, 'DigitalInput' );
    return $obj->is_set_input( $pin );
}

sub is_set_output
{
    my ($self, $name, $pin) = @_;
    my $obj = $self->_get_obj( $name );
    $self->_role_check( $obj, 'DigitalOutput' );
    $self->_pin_count_check( $name, $obj, $pin, 'DigitalOutput' );
    return $obj->is_set_output( $pin );
}

sub digital_input_pin_count
{
    my ($self, $name) = @_;
    my $obj = $self->_get_obj( $name );
    $self->_role_check( $obj, 'DigitalInput' );
    my $count = $obj->input_pin_count;
    return $count;
}

sub digital_output_pin_count
{
    my ($self, $name) = @_;
    my $obj = $self->_get_obj( $name );
    $self->_role_check( $obj, 'DigitalOutput' );
    my $count = $obj->output_pin_count;
    return $count;
}

sub digital_input
{
    my ($self, $name, $pin) = @_;
    my $obj = $self->_get_obj( $name );
    $self->_role_check( $obj, 'DigitalInput' );
    $self->_pin_count_check( $name, $obj, $pin, 'DigitalInput' );
    return $obj->input_pin( $pin );
}

sub digital_input_port
{
    my ($self, $name) = @_;
    my $obj = $self->_get_obj( $name );
    $self->_role_check( $obj, 'DigitalInput' );
    return $obj->input_port;
}

sub digital_input_callback
{
    my ($self, $name, $pin, $type, $callback) = @_;
    my $obj = $self->_get_obj( $name );
    $self->_role_check( $obj, 'DigitalInputCallback' );
    $self->_pin_count_check( $name, $obj, $pin, 'DigitalInputCallback' );
    return $obj->input_callback_pin( $pin, $type, $callback );
}

sub digital_input_begin_loop
{
    my ($self, $name) = @_;
    my $obj = $self->_get_obj( $name );
    $self->_role_check( $obj, 'DigitalInputCallback' );
    return $obj->input_begin_loop();
}

sub digital_output_port
{
    my ($self, $name, $out) = @_;
    my $obj = $self->_get_obj( $name );
    $self->_role_check( $obj, 'DigitalOutput' );
    $obj->output_port( $out );
    return 1;
}

sub digital_output
{
    my ($self, $name, $pin, $val) = @_;
    my $obj = $self->_get_obj( $name );
    $self->_role_check( $obj, 'DigitalOutput' );
    $self->_pin_count_check( $name, $obj, $pin, 'DigitalOutput' );
    $obj->output_pin( $pin, $val );
    return 1;
}

sub adc_count
{
    my ($self, $name) = @_;
    my $obj = $self->_get_obj( $name );
    $self->_role_check( $obj, 'ADC' );
    return $obj->adc_pin_count;
}

sub adc_resolution
{
    my ($self, $name, $pin) = @_;
    my $obj = $self->_get_obj( $name );
    $self->_role_check( $obj, 'ADC' );
    return $obj->adc_bit_resolution( $pin );
}

sub adc_max_int
{
    my ($self, $name, $pin) = @_;
    my $obj = $self->_get_obj( $name );
    $self->_role_check( $obj, 'ADC' );
    return $obj->adc_max_int( $pin );
}

sub adc_volt_ref
{
    my ($self, $name, $pin) = @_;
    my $obj = $self->_get_obj( $name );
    $self->_role_check( $obj, 'ADC' );
    return $obj->adc_volt_ref( $pin );
}

sub adc_input_int
{
    my ($self, $name, $pin) = @_;
    my $obj = $self->_get_obj( $name );
    $self->_role_check( $obj, 'ADC' );
    $self->_pin_count_check( $name, $obj, $pin, 'ADC' );
    return $obj->adc_input_int( $pin );
}

sub adc_input_float
{
    my ($self, $name, $pin) = @_;
    my $obj = $self->_get_obj( $name );
    $self->_role_check( $obj, 'ADC' );
    $self->_pin_count_check( $name, $obj, $pin, 'ADC' );
    return $obj->adc_input_float( $pin );
}

sub adc_input_volts
{
    my ($self, $name, $pin) = @_;
    my $obj = $self->_get_obj( $name );
    $self->_role_check( $obj, 'ADC' );
    $self->_pin_count_check( $name, $obj, $pin, 'ADC' );
    return $obj->adc_input_volts( $pin );
}

sub pwm_count
{
    my ($self, $name) = @_;
    my $obj = $self->_get_obj( $name );
    $self->_role_check( $obj, 'PWM' );
    return $obj->pwm_pin_count;
}

sub pwm_resolution
{
    my ($self, $name, $pin) = @_;
    my $obj = $self->_get_obj( $name );
    $self->_role_check( $obj, 'PWM' );
    return $obj->pwm_bit_resolution( $pin );
}

sub pwm_max_int
{
    my ($self, $name, $pin) = @_;
    my $obj = $self->_get_obj( $name );
    $self->_role_check( $obj, 'PWM' );
    return $obj->pwm_max_int( $pin );
}

sub pwm_output_int
{
    my ($self, $name, $pin, $value) = @_;
    my $obj = $self->_get_obj( $name );
    $self->_role_check( $obj, 'PWM' );
    $self->_pin_count_check( $name, $obj, $pin, 'PWM' );
    return $obj->pwm_output_int( $pin, $value );
}

sub pwm_output_float
{
    my ($self, $name, $pin, $value) = @_;
    my $obj = $self->_get_obj( $name );
    $self->_role_check( $obj, 'PWM' );
    $self->_pin_count_check( $name, $obj, $pin, 'PWM' );
    return $obj->pwm_output_float( $pin, $value );
}

sub vid_channels
{
    my ($self, $name) = @_;
    my $obj = $self->_get_obj( $name );
    $self->_role_check( $obj, 'VideoOutput' );
    return $obj->vid_channels;
}

sub vid_width
{
    my ($self, $name, $pin) = @_;
    my $obj = $self->_get_obj( $name );
    $self->_pin_count_check( $name, $obj, $pin, 'VideoOutput' );
    $self->_role_check( $obj, 'VideoOutput' );
    return $obj->vid_width( $pin );
}

sub vid_height
{
    my ($self, $name, $pin) = @_;
    my $obj = $self->_get_obj( $name );
    $self->_pin_count_check( $name, $obj, $pin, 'VideoOutput' );
    $self->_role_check( $obj, 'VideoOutput' );
    return $obj->vid_height( $pin );
}

sub vid_fps
{
    my ($self, $name, $pin) = @_;
    my $obj = $self->_get_obj( $name );
    $self->_pin_count_check( $name, $obj, $pin, 'VideoOutput' );
    $self->_role_check( $obj, 'VideoOutput' );
    return $obj->vid_fps( $pin );
}

sub vid_kbps
{
    my ($self, $name, $pin) = @_;
    my $obj = $self->_get_obj( $name );
    $self->_pin_count_check( $name, $obj, $pin, 'VideoOutput' );
    $self->_role_check( $obj, 'VideoOutput' );
    return $obj->vid_kbps( $pin );
}

sub vid_set_width
{
    my ($self, $name, $pin, $value) = @_;
    my $obj = $self->_get_obj( $name );
    $self->_pin_count_check( $name, $obj, $pin, 'VideoOutput' );
    $self->_role_check( $obj, 'VideoOutput' );
    return $obj->vid_set_width( $pin, $value );
}

sub vid_set_height
{
    my ($self, $name, $pin, $value) = @_;
    my $obj = $self->_get_obj( $name );
    $self->_pin_count_check( $name, $obj, $pin, 'VideoOutput' );
    $self->_role_check( $obj, 'VideoOutput' );
    return $obj->vid_set_height( $pin, $value );
}

sub vid_set_fps
{
    my ($self, $name, $pin, $value) = @_;
    my $obj = $self->_get_obj( $name );
    $self->_pin_count_check( $name, $obj, $pin, 'VideoOutput' );
    $self->_role_check( $obj, 'VideoOutput' );
    return $obj->vid_set_fps( $pin, $value );
}

sub vid_set_kbps
{
    my ($self, $name, $pin, $value) = @_;
    my $obj = $self->_get_obj( $name );
    $self->_pin_count_check( $name, $obj, $pin, 'VideoOutput' );
    $self->_role_check( $obj, 'VideoOutput' );
    return $obj->vid_set_kbps( $pin, $value );
}

sub vid_allowed_content_types
{
    my ($self, $name, $pin) = @_;
    my $obj = $self->_get_obj( $name );
    $self->_pin_count_check( $name, $obj, $pin, 'VideoOutput' );
    $self->_role_check( $obj, 'VideoOutput' );
    return $obj->vid_allowed_content_types( $pin );
}

sub vid_stream
{
    my ($self, $name, $pin, $type) = @_;
    my $obj = $self->_get_obj( $name );
    $self->_pin_count_check( $name, $obj, $pin, 'VideoOutput' );
    $self->_role_check( $obj, 'VideoOutput' );
    return $obj->vid_stream( $pin, $type );
}

sub vid_stream_callback
{
    my ($self, $name, $pin, $type, $callback) = @_;
    my $obj = $self->_get_obj( $name );
    $self->_pin_count_check( $name, $obj, $pin, 'VideoOutput' );
    $self->_role_check( $obj, 'VideoOutputCallback' );
    return $obj->vid_stream_callback( $pin, $type, $callback );
}

sub vid_stream_begin_loop
{
    my ($self, $name, $pin) = @_;
    my $obj = $self->_get_obj( $name );
    $self->_pin_count_check( $name, $obj, $pin, 'VideoOutput' );
    $self->_role_check( $obj, 'VideoOutputCallback' );
    return $obj->vid_stream_begin_loop( $pin );
}

sub img_channels
{
    my ($self, $name) = @_;
    my $obj = $self->_get_obj( $name );
    $self->_role_check( $obj, 'StillImageOutput' );
    return $obj->img_channels;
}

sub img_width
{
    my ($self, $name, $pin) = @_;
    my $obj = $self->_get_obj( $name );
    $self->_role_check( $obj, 'StillImageOutput' );
    $self->_pin_count_check( $name, $obj, $pin, 'StillImageOutput' );
    return $obj->img_width( $pin );
}

sub img_height
{
    my ($self, $name, $pin) = @_;
    my $obj = $self->_get_obj( $name );
    $self->_role_check( $obj, 'StillImageOutput' );
    $self->_pin_count_check( $name, $obj, $pin, 'StillImageOutput' );
    return $obj->img_height( $pin );
}

sub img_quality
{
    my ($self, $name, $pin) = @_;
    my $obj = $self->_get_obj( $name );
    $self->_role_check( $obj, 'StillImageOutput' );
    $self->_pin_count_check( $name, $obj, $pin, 'StillImageOutput' );
    return $obj->img_quality( $pin );
}

sub img_set_width
{
    my ($self, $name, $pin, $value) = @_;
    my $obj = $self->_get_obj( $name );
    $self->_role_check( $obj, 'StillImageOutput' );
    $self->_pin_count_check( $name, $obj, $pin, 'StillImageOutput' );
    return $obj->img_set_width( $pin, $value );
}

sub img_set_height
{
    my ($self, $name, $pin, $value) = @_;
    my $obj = $self->_get_obj( $name );
    $self->_role_check( $obj, 'StillImageOutput' );
    $self->_pin_count_check( $name, $obj, $pin, 'StillImageOutput' );
    return $obj->img_set_height( $pin, $value );
}

sub img_set_quality
{
    my ($self, $name, $pin, $value) = @_;
    my $obj = $self->_get_obj( $name );
    $self->_role_check( $obj, 'StillImageOutput' );
    $self->_pin_count_check( $name, $obj, $pin, 'StillImageOutput' );
    return $obj->img_set_quality( $pin, $value );
}

sub img_allowed_content_types
{
    my ($self, $name, $pin) = @_;
    my $obj = $self->_get_obj( $name );
    $self->_pin_count_check( $name, $obj, $pin, 'StillImageOutput' );
    return $obj->img_allowed_content_types( $pin );
}

sub img_stream
{
    my ($self, $name, $pin, $type) = @_;
    my $obj = $self->_get_obj( $name );
    $self->_pin_count_check( $name, $obj, $pin, 'StillImageOutput' );
    return $obj->img_stream( $pin, $type );
}

sub i2c_read
{
    my ($self, $name, $pin, $addr, $register, $num_bytes) = @_;
    my $obj = $self->_get_obj( $name );
    $self->_pin_count_check( $name, $obj, $pin, 'I2CProvider' );
    return $obj->i2c_read( $pin, $addr, $register, $num_bytes );
}

sub i2c_write
{
    my ($self, $name, $pin, $addr, $register, @bytes) = @_;
    my $obj = $self->_get_obj( $name );
    $self->_pin_count_check( $name, $obj, $pin, 'I2CProvider' );
    return $obj->i2c_write( $pin, $addr, $register, @bytes );
}

sub temp_celsius
{
    my ($self, $name) = @_;
    my $obj = $self->_get_obj( $name );
    Device::WebIO::FunctionNotSupportedException->throw(
        message => "Asked for temperature, but $name does not do the"
            . " TempSensor role"
    ) if ! $obj->does( 'Device::WebIO::Device::TempSensor' );
    return $obj->temp_celsius;
}

sub temp_kelvins
{
    my ($self, $name) = @_;
    my $obj = $self->_get_obj( $name );
    Device::WebIO::FunctionNotSupportedException->throw(
        message => "Asked for temperature, but $name does not do the"
            . " TempSensor role"
    ) if ! $obj->does( 'Device::WebIO::Device::TempSensor' );
    return $obj->temp_kelvins;
}

sub temp_fahrenheit
{
    my ($self, $name) = @_;
    my $obj = $self->_get_obj( $name );
    Device::WebIO::FunctionNotSupportedException->throw(
        message => "Asked for temperature, but $name does not do the"
            . " TempSensor role"
    ) if ! $obj->does( 'Device::WebIO::Device::TempSensor' );
    return $obj->temp_fahrenheit;
}

sub spi_set_speed
{
    my ($self, $name, $pin, $speed) = @_;
    my $obj = $self->_get_obj( $name );
    $self->_pin_count_check( $name, $obj, $pin, 'SPI' );
    return $obj->spi_set_speed( $pin, $speed );
}

sub spi_read
{
    my ($self, $name, $pin, $len) = @_;
    my $obj = $self->_get_obj( $name );
    $self->_pin_count_check( $name, $obj, $pin, 'SPI' );
    return $obj->spi_read( $pin, $len );
}

sub spi_write
{
    my ($self, $name, $pin, $data) = @_;
    my $obj = $self->_get_obj( $name );
    $self->_pin_count_check( $name, $obj, $pin, 'SPI' );
    return $obj->spi_write( $pin, $data );
}


sub _get_obj
{
    my ($self, $name) = @_;
    my $obj = $self->_device_by_name->{$name};
    return $obj;
}

sub _pin_count_check
{
    my ($self, $name, $obj, $pin, $type) = @_;
    my $pin_count = $self->_pin_count_for_obj( $obj, $type );

    if( $pin_count <= $pin ) {
        Device::WebIO::PinDoesNotExistException->throw(
            message => "Asked for $type pin $pin, but device $name"
                . " only has $pin_count pins",
        );
    }

    return 1;
}

sub _pin_count_for_obj
{
    my ($self, $obj, $type) = @_;

    my $count;
    if( $type eq 'DigitalInput' &&
        $obj->does( 'Device::WebIO::Device::DigitalInput' ) ) {
        $count = $obj->input_pin_count;
    }
    elsif( $type eq 'DigitalInputCallback' &&
        $obj->does( 'Device::WebIO::Device::DigitalInputCallback' ) ) {
        $count = $obj->input_pin_count;
    }
    elsif( $type eq 'DigitalOutput' &&
        $obj->does( 'Device::WebIO::Device::DigitalOutput' ) ) {
        $count = $obj->output_pin_count;
    }
    elsif( $type eq 'ADC' &&
        $obj->does( 'Device::WebIO::Device::ADC' ) ) {
        $count = $obj->adc_pin_count;
    }
    elsif( $type eq 'PWM' &&
        $obj->does( 'Device::WebIO::Device::PWM' ) ) {
        $count = $obj->pwm_pin_count;
    }
    elsif( $type eq 'VideoOutput' &&
        $obj->does( 'Device::WebIO::Device::VideoOutput' ) ) {
        $count = $obj->vid_channels;
    }
    elsif( $type eq 'StillImageOutput' &&
        $obj->does( 'Device::WebIO::Device::StillImageOutput' ) ) {
        $count = $obj->img_channels;
    }
    elsif( $type eq 'I2CProvider' &&
        $obj->does( 'Device::WebIO::Device::I2CProvider' ) ) {
        $count = $obj->i2c_channels;
    }
    elsif( $type eq 'SPI' &&
        $obj->does( 'Device::WebIO::Device::SPI' ) ) {
        $count = $obj->spi_channels;
    }

    return $count;
}

sub _role_check
{
    my ($self, $obj, @want_types) = @_;

    my $does = 0;
    for (@want_types) {
        my $full_type = 'Device::WebIO::Device::' . $_;
        if( $obj->does( $full_type ) ) {
            $does = 1;
            last;
        }
    }
    if(! $does ) {
        Device::WebIO::FunctionNotSupportedException->throw( message =>
            "Object of type " . ref($obj)
                . " does not any of the " . join( ', ', @want_types ) . " roles"
        );
    }

    return 1;
}


1;
__END__


=head1 NAME

  Device::WebIO - Duct Tape for the Internet of Things

=head1 SYNOPSIS

    my $webio = Device::WebIO->new;
    $webio->register( 'foo', $dev ); # Register a device with the name 'foo'
    
    # Input pin 0 on device registered with the name 'foo'
    my $in_value = $webio->digital_input( 'foo', 0 );
    # Output pin 0 on device registered with the name 'foo'
    $webio->digital_input( 'foo', 0, $in_value );

=head1 DESCRIPTION

Device::WebIO provides a standardized interface for accessing GPIO, 
Analog-to-Digital, Pulse Width Modulation, and many other devices.  Drivers 
are available for the Raspberry Pi, PCDuino, Arduino (via Firmata attached 
over USB), and many others in the future.

The 35,000-foot-view is that the Device::WebIO object is registered with 
one or more objects that do the C<Device::WebIO::Device> role.  These objects 
provide certain services, in accordance with the individual roles under the 
C<Device::WebIO::Device::*> namespace, such as DigitalInput, DigitalOutput, 
ADC, etc.

=head1 METHODS

=head3 new

Constructor.

=head3 register

  register( $name, $obj );

Register a driver object with the given name.  The object must do the 
c<Device::WebIO::Device> role.

=head3 all_desc

    all_desc( $name );

Returns hashref specifying the capabilities of the device.

Entries in the hashref are:

=over 4

=item * UART [bool]

=item * SPI [bool]

=item * I2C [bool]

=item * ONEWIRE [bool]

=item * GPIO [hashref]

=back

GPIO's entries are numbers mapping to each GPIO pin.  The values are hashrefs
containing:

=over 4

=item * function ["IN", "OUT", "ALTn" (where n is some number)]

=item * value [bool]

=back



=head3 pin_desc

    pin_desc( $name );

Returns an arrayref containing a definition for each pin in order.

Each entry can be:

=over 4

=item * Some number (corresponding to a GPIO number)

=item * "V33" (3.3 volt power)

=item * "V50" (5.0 volt power)

=item * "GND" (ground)

=back


=head2 Input

=head3 set_as_input

  set_as_input( $name, $pin );

Set the given pin as input.

=head3 is_set_input

  is_set_input( $name, $pin );

Check if the given pin is already set as input.

=head3 digital_input_pin_count

  digital_input_pin_count( $name );

Returns how many input pins there are for this device.

=head3 digital_input

  digital_input( $name, $pin );

Returns the input status of the given pin.  1 for on, 0 for off.

=head3 digital_input_port

  digital_input_port( $name );

Returns an integer with each bit representing the on or off status of the 
associated pin.

=head2 Input Callback

These can be used if the device does the C<DigialInputCallback> role.

=head3 digital_input_callback

  digital_input_callback( $name, $pin, $type, $callback );

Set a callback that will be triggered when C<$pin> changes state.  C<$type> 
is one of the constants in the C<DigitalInputCallback> role, which controls 
when the callback is triggered--C<TRIGGER_RISING>, C<TRIGGER_FALLING>, or 
C<TRIGGER_RISING_FALLING>.

C<$callback> is a subref that will be called.

=head3 digital_input_begin_loop

  digital_input_begin_loop( $name );

Start the loop that will trigger callbacks.

=head2 Output

=head3 set_as_output

  set_as_output( $name, $pin );

Set the given pin as output.

=head3 is_set_output

  is_set_output( $name, $pin );

Check if the given pin is set as output.

=head3 digital_output_pin_count

  digital_output_pin_count( $name );

Returns the number of output pins.

=head3 digital_output

  digital_output( $name, $pin, $value );

Sets the value of the output for the given pin.  1 for on, 0 for off.

=head3 digital_output_port

  digital_output_port( $name, $int );

Sets the value of all output pins.  Each bit of C<$int> corresponds to a pin.

=head2 Analog-to-Digital

=head3 adc_count

  adc_count( $name );

Returns the number of ADC pins.

=head3 adc_resolution

  adc_resolution( $name, $pin );

Returns the number of bits of resolution for the given pin.

=head3 adc_max_int

  adc_max_int( $name, $pin );

Returns the max integer value for the given pin.

=head3 adc_volt_ref

  adc_volt_ref( $name, $pin );

Returns the voltage reference for the given pin.  All ADC values are scaled 
between 0 (ground) and the volt ref.

=head3 adc_input_int

  adc_input_int( $name, $pin );

Return the ADC integer input value.

=head3 adc_input_float

  adc_input_float( $name, $pin );

Return the ADC floating point input value.  The value will be between 0.0 and 
1.0.

=head3 adc_input_volts

  adc_input_volts( $name, $pin );

Return the voltage level of the given pin.  This will be between 0.0 (ground) 
and the volt ref.

=head2 PWM

=head3 pwm_count

  pwm_count( $name );

Return the number of PWM pins.

=head3 pwm_resolution

  pwm_resolution( $name, $pin );

Return the number of bits of resolution for the given PWM pin.

=head3 pwm_max_int

  pwm_max_int( $name, $pin );

Return the max int value for the given PWM ping.

=head3 pwm_output_int

  pwm_output_int( $name, $pin, $value );

Set the value of the given PWM pin.

=head3 pwm_output_float

  pwm_output_float( $name, $pin, $value );

Set the value of the given PWM pin with a floating point value between 0.0 
and 1.0.

=head2 Video

=head3 vid_channels

  vid_channels( $name );

Get the number of video channels.

=head3 vid_width

  vid_width( $name, $channel );

Return the width of the video channel.

=head3 vid_height

  vid_height( $name, $channel );

Return the height of the video channel.

=head3 vid_fps

  vid_fps( $name, $channel );

Return the Frames Per Second of the video channel.

=head3 vid_kbps

  vid_kbps( $name, $channel );

Return the bitrate of the video channel.

=head3 vid_set_width

  vid_set_width( $name, $channel, $width );

Set the width of the video channel.

=head3 vid_set_height

  vid_set_height( $name, $channel, $height );

Set the height of the video channel.

=head3 vid_allowed_content_types

  vid_allowed_content_types( $name, $channel );

Returns a list of MIME types allowed for the given video channel.

=head3 vid_stream

  vid_stream( $name, $channel, $type );

Returns a filehandle for streaming the video channel.  C<$type> is one of the 
MIME types returned by C<vid_allowed_content_types()>.

=head2 Video Callback

These can be used if the device does the C<VideoOutputCallback> role.

=head3 vid_stream_callback

  vid_stream_callback( $name, $channel, $type, $callback );

Set a callback that will be triggered when the given video channel gets a 
new frame.  C<$type> is one of the MIME types returned by 
C<vid_allowed_content_types()>.

Only 1 callback per channel will be kept.

=head3 vid_stream_begin_loop

  vid_stream_begin_loop( $name, $channel );

Start the loop that will trigger callbacks.

=head2 Still Image

=head3 img_channels

  img_channels( $name );

Get the number of still image channels.

=head3 img_width

  img_width( $name, $channel );

Return the width of the image channel.

=head3 img_height

  img_height( $name, $channel );

Return the height of the image channel.

=head3 img_quality

  img_quality( $name, $channel );

Return the quality of the image channel.

=head3 img_set_width

  img_set_width( $name, $channel, $width );

Set the width of the image channel.

=head3 img_set_height

  img_set_height( $name, $channel, $height );

Set the height of the image channel.

=head3 img_set_quality

  img_set_quality( $name, $channel, $height );

Set the quality of the image channel.

=head3 img_allowed_content_types

  img_allowed_content_types( $name, $channel );

Returns a list of MIME types allowed for the given video channel.

=head3 img_stream

  img_stream( $name, $channel, $type );

Returns a filehandle for streaming the video channel.  C<$type> is one of the 
MIME types return by C<img_allowed_content_types()>.

=head2 I2C

=head3 i2c_read

    i2c_read( $name, $pin, $addr, $register, $num_bytes );

Read C<$num_bytes> bytes from the I2C register for the device on the given 
bus and address.  Returns a list C<$num_bytes> long.

=head3 i2c_write

    i2c_write( $name, $pin, $addr, $register, @bytes );

Write the C<@bytes> list of bytes to the I2C register for the device on the 
given bus and address.

=head2 SPI

=head3 spi_set_speed

    spi_set_speed( $name, $pin, $speed );

Set the speed on the given SPI device.

=head3 spi_read

    spi_read( $name, $pin, $len );

Read C<$len> bytes from the given SPI device.  Returns an array of bytes.

=head3 spi_write

    spi_write( $name, $pin, $packed_data );

Write C<$packed_data> to the given SPI device.  This data should be a packed 
string For many devices, a single byte can packed using:

  my $packed_data = pack 'n', $data;

For an array of bytes, try:

  my $packed_data = pack 'C*', @data;

This can often be different based on the device, which is why we don't do it 
for you.


=head1 SEE ALSO

WebIOPi, the Python project where Device::WebIO gets its inspiration: 
L<https://code.google.com/p/webiopi/>

=head1 LICENSE

Copyright (c) 2014  Timm Murray
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are 
permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice, this list of 
      conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright notice, this list of
      conditions and the following disclaimer in the documentation and/or other materials 
      provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS 
OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF 
MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE 
COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, 
EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) 
HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR 
TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, 
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut
