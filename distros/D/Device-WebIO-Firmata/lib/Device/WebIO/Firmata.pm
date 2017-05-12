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
package Device::WebIO::Firmata;
$Device::WebIO::Firmata::VERSION = '0.002';
# ABSTRACT: Interface between Device::WebIO and Device::Firmata (Arduino)
use v5.12;
use Moo;
use namespace::clean;
use Device::Firmata ();
use Device::Firmata::Constants qw{ :all };

has '_firmata' => (
    is  => 'ro',
);
has 'input_pin_count' => (
    is  => 'ro',
    # Max GPIO pins Firmata supports.  Would be nice if it had a way to 
    # detect how many pins are actually on the device.
    default => sub { 128 },
);
has 'output_pin_count' => (
    is      => 'ro',
    default => sub { 128 },
);
has 'pwm_pin_count' => (
    is      => 'ro',
    default => sub { 128 },
);
has 'pin_desc' => (
    is => 'ro',
    # TODO this is based on the Uno's pin header.  Would be nice to have 
    # a configurable option for different boards.
    default => sub {[qw{
        SCL SDA AREF GND 13 12 11 10 9 8 7 6 5 4 3 2 1 0
        IOREF RESET 33V 50V GND GND VIN A0 A1 A2 A3 A4 A5
    }]},
);
has '_pin_mode' => (
    is => 'ro',
);

with 'Device::WebIO::Device::DigitalOutput';
with 'Device::WebIO::Device::DigitalInput';
with 'Device::WebIO::Device::PWM';
with 'Device::WebIO::Device::ADC';


sub BUILDARGS
{
    my ($class, $args) = @_;
    my $port = delete $args->{port};

    my $dev = Device::Firmata->open( $port )
        or die "Could not connect to Firmata Server on '$port'\n";
    $args->{'_firmata'} = $dev;

    $args->{'_pin_mode'} = [ ('IN') x 128 ];

    return $args;
}

sub output_pin
{
    my ($self, $pin, $set) = @_;
    $self->_firmata->digital_write( $pin, $set );
    return 1;
}

sub input_pin
{
    my ($self, $pin) = @_;
    my $value = $self->_firmata->digital_read( $pin );
    return $value;
}

sub set_as_output
{
    my ($self, $pin) = @_;
    $self->_pin_mode->[$pin] = 'OUT';
    $self->_firmata->pin_mode( $pin, PIN_OUTPUT );
    return 1;
}

sub set_as_input
{
    my ($self, $pin) = @_;
    $self->_pin_mode->[$pin] = 'IN';
    $self->_firmata->pin_mode( $pin, PIN_INPUT );
    return 1;
}

sub is_set_input
{
    my ($self, $pin) = @_;
    return 1 if $self->_pin_mode->[$pin] eq 'IN';
    return 0;
}

sub is_set_output
{
    my ($self, $pin) = @_;
    return 1 if $self->_pin_mode->[$pin] eq 'OUT';
    return 0;
}


sub pwm_bit_resolution
{
    my ($self, $pin) = @_;
    # Arduino Uno bit resolution
    return 8;
}

{
    my %did_set_pwm;
    sub pwm_output_int
    {
        my ($self, $pin, $value) = @_;
        my $firmata = $self->_firmata;

        $firmata->pin_mode( $pin, PIN_PWM )
            if ! exists $did_set_pwm{$pin};
        $did_set_pwm{$pin} = 1;

        $firmata->analog_write( $pin, $value );
        return 1;
    }
}

sub adc_bit_resolution
{
    my ($self, $pin) = @_;
    # Arduino Uno bit resolution
    return 10;
}

sub adc_volt_ref
{
    my ($self, $pin) = @_;
    # Arduino Uno, except when it's 3.3V.  This is a rather large assumption. 
    # TODO fix this
    return 5.0;
}

sub adc_pin_count
{
    my ($self, $pin) = @_;
    return 128;
}

{
    my %did_set_adc;
    sub adc_input_int
    {
        my ($self, $pin) = @_;
        my $firmata = $self->_firmata;

        $firmata->pin_mode( $pin, PIN_ANALOG )
            if ! exists $did_set_adc{$pin};
        $did_set_adc{$pin} = 1;

        my $value = $firmata->analog_write( $pin );
        return $value;
    }
}


sub all_desc
{
    my ($self) = @_;
    my $pin_count = $self->input_pin_count;
    return {
        UART    => 0,
        SPI     => 0,
        I2C     => 0,
        ONEWIRE => 0,
        GPIO => {
            map {
                my $function = $self->_pin_mode->[$_];
                my $value = $function eq 'IN'
                    ? $self->input_pin( $_ ) 
                    : $self->{'_output_pin_value'}[$_];
                $_ => {
                    function => $function,
                    value    => $value,
                };
            } 0 .. ($pin_count - 1)
        },
    };
}




1;
__END__


=head1 NAME

  Device::WebIO::Firmata - Access Arduino pins via Firmata via Device::WebIO

=head1 SYNOPSIS

    use Device::Firmata;
    use Device::WebIO;
    use Device::WebIO::Firmata;
    
    my $webio = Device::WebIO->new;
    my $firmata = Device::WebIO::Firmata->new({
        port => '/dev/ttyACM0',
    });
    $webio->register( 'foo', $firmata );
    
    my $value = $webio->adc_input_int( 'foo', 0 );

=head1 DESCRIPTION

Firmata is a protocol for accessing the pins of an Arduino connected to your 
system over USB.  Device::WebIO provides a consistent interface in Perl for 
accessing these pins.  Device::WebIO::Firmata provides the glue to bring them 
together.

After registering this with the main Device::WebIO object, you shouldn't need 
to access anything in the Firmata object.  All access should go through the 
WebIO object.

=head1 IMPLEMENTED ROLES

=over 4

=item * DigitalOutput

=item * DigitalInput

=item * PWM

=item * ADC

=back

=head1 SEE ALSO

C<Device::WebIO>

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
