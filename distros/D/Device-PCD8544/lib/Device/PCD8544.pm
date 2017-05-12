# Copyright (c) 2015  Timm Murray
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
#
#
# Some of this code is based on Adafruit Industries' Python library, which is
# covered by:
#
#
# Copyright (c) 2014 Adafruit Industries
# Author: Tony DiCola
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#
package Device::PCD8544;
$Device::PCD8544::VERSION = '0.0268329147520525';
# ABSTRACT: Driver for the PCD8544 LCD controller (aka Nokia 5110)
use v5.14;
use warnings;
use Moo;
use namespace::clean;
use Device::WebIO::Device::DigitalOutput;
use Device::WebIO::Device::SPI;
use Time::HiRes ();

use constant DEBUG => 0;

use constant {
    BIAS_1_100 => 0b000,
    BIAS_1_80  => 0b001,
    BIAS_1_65  => 0b010,
    BIAS_1_48  => 0b011,
    BIAS_1_40  => 0b100,
    BIAS_1_24  => 0b101,
    BIAS_1_18  => 0b110,
    BIAS_1_10  => 0b111,
};
use constant {
    SPEED_1MHZ => 1_000_000,
    SPEED_2MHZ => 2_000_000,
    SPEED_4MHZ => 4_000_000,
};
use constant {
    POWERDOWN            => 0x04,
    ENTRYMODE            => 0x02,
    EXTENDED_INSTRUCTION => 0x01,
    DISPLAY_BLANK        => 0x00,
    DISPLAY_NORMAL       => 0x04,
    DISPLAY_ALL_ON       => 0x01,
    DISPLAY_INVERTED     => 0x05,
    FUNCTIONSET          => 0x20,
    DISPLAY_CONTROL      => 0x08,
    SETYADDR             => 0x40,
    SETXADDR             => 0x80,
    SETTEMP              => 0x04,
    SETBIAS              => 0x10,
    SETVOP               => 0x80,
};

has dev => (
    is       => 'ro',
    required => 1,
);
has speed => (
    is      => 'ro',
    default => sub { SPEED_4MHZ },
);
has webio => (
    is  => 'ro',
    isa => sub {
        my ($obj) = @_;
        if(! (
            $obj->does( 'Device::WebIO::Device::DigitalOutput' )
            && $obj->does( 'Device::WebIO::Device::SPI' )
        )) {
            die "The webio object must do the roles Device::WebIO::Device::DigitalOutput and Device::WebIO::Device::SPI\n";
        }
    },
    required => 1,
);
has 'power' => (
    is       => 'ro',
    required => 1,
);
has 'rst' => (
    is       => 'ro',
    required => 1,
);
has 'dc' => (
    is       => 'ro',
    required => 1,
);
has 'contrast' => (
    is      => 'rw',
    default => sub { 0x3C },
    trigger => sub {
        my ($self, $val) = @_;
        return 1 unless $self->_was_init_called;
        $self->_send_extended_command( SETVOP | $val );
        return 1;
    },
);
has 'bias' => (
    is      => 'rw',
    default => sub { BIAS_1_40 },
    trigger => sub {
        my ($self, $val) = @_;
        return 1 unless $self->_was_init_called;
        $self->_send_extended_command( SETBIAS | $val );
        return 1;
    },
);
has '_buffer' => (
    is      => 'rw',
    default => sub {[]},
);
has '_was_init_called' => (
    is      => 'rw',
    default => sub { 0 },
);


sub init
{
    my ($self) = @_;
    return 1 if $self->_was_init_called;
    my $webio = $self->webio;

    foreach ($self->power, $self->rst, $self->dc ) {
        $webio->set_as_output( $_ );
        $webio->output_pin( $_, 1 );
    }

    $webio->spi_set_speed( $self->dev, $self->speed );

    $self->reset;
    $self->_was_init_called( 1 );
    return 1;
}

sub reset
{
    my ($self) = @_;
    my $webio = $self->webio;
    my $power = $self->power;
    my $rst   = $self->rst;

    # Created using suggestions from 'Kuy' on Sparkfun product comments:
    # https://www.sparkfun.com/products/10168
    #
    $webio->output_pin( $power, 1 );
    $webio->output_pin( $rst,   1 );
    Time::HiRes::usleep( 5_000 );

    $webio->output_pin( $rst, 0 );
    Time::HiRes::usleep( 1_000 );

    $webio->output_pin( $rst, 1 );
    Time::HiRes::usleep( 5_000 );

    say "Setting bias (" . SETBIAS . " | " . $self->bias . ")" if DEBUG;
    $self->_send_extended_command( SETBIAS | $self->bias );
    say "Setting contrast (" . SETVOP . " | " . $self->contrast . ")" if DEBUG;
    $self->_send_extended_command( SETVOP  | $self->contrast );
    say "Setting Y Addr (" . SETYADDR . ")" if DEBUG;
    $self->_send_command( SETYADDR | 0x00 );
    say "Setting X Addr (" . SETXADDR . ")" if DEBUG;
    $self->_send_command( SETXADDR | 0x00 );

    return 1;
}

sub set_image
{
    my ($self, $img) = @_;
    $self->_buffer( $img );
    return 1;
}

sub update
{
    my ($self) = @_;
    $self->_send_buffer;
    return 1;
}

sub display_blank
{
    my ($self) = @_;
    $self->_send_command( DISPLAY_CONTROL | DISPLAY_BLANK );
    return 1;
}

sub display_normal
{
    my ($self) = @_;
    $self->_send_command( DISPLAY_CONTROL | DISPLAY_NORMAL );
    return 1;
}

sub display_all_on
{
    my ($self) = @_;
    $self->_send_command( DISPLAY_CONTROL | DISPLAY_ALL_ON );
    return 1;
}

sub display_inverse
{
    my ($self) = @_;
    $self->_send_command( DISPLAY_CONTROL | DISPLAY_INVERTED );
    return 1;
}

sub _send_command
{
    my ($self, $cmd) = @_;
    say "Sending command $cmd" if DEBUG;

    my $webio = $self->webio;
    $webio->output_pin( $self->dc, 0 );

    my $fmt_cmd = pack 'n', $cmd;
    $webio->spi_write( $self->dev, $fmt_cmd );

    return 1;
}

sub _send_extended_command
{
    my ($self, $cmd) = @_;
    say "Sending extended command $cmd {" if DEBUG;
    $self->_send_command( FUNCTIONSET | EXTENDED_INSTRUCTION );
    $self->_send_command( $cmd );
    $self->_send_command( FUNCTIONSET );
    $self->_send_command( DISPLAY_CONTROL | DISPLAY_NORMAL );
    say "}" if DEBUG;
    return 1;
}

sub _send_buffer
{
    my ($self) = @_;
    my $buffer = $self->_buffer;
    my $webio = $self->webio;

    $self->_send_command( SETYADDR  | 0x00 );
    $self->_send_command( SETXADDR | 0x00 );

    $webio->output_pin( $self->dc, 1 );

    my $fmt_buf = pack 'C*', @$buffer;
    $webio->spi_write( $self->dev, $fmt_buf );

    return 1;
}


1;
__END__

=head1 NAME

  Device::PCD8544 - Driver for the PCD8544 LCD controller (aka Nokia 5110)

=head1 SYNOPSIS

    my $rpi = Device::WebIO::RaspberryPi->new;
    my $lcd = Device::PCD8544->new({
        dev      => 0,
        speed    => Device::PCD8544->SPEED_4MHZ,
        webio    => $rpi,
        power    => 2,
        rst      => 24,
        dc       => 23,
        contrast => 0x3C,
        bias     => Device::PCD8544->BIAS_1_40,
    });
    
    $lcd->init;
    $lcd->set_image( \@PIC_OUT );
    $lcd->update;

=head1 DESCRIPTION

Implements the PCD8544 LCD controller using C<Device::WebIO>. This display is 
84x48 pixels of black-and-white.  It's similar to the one on the Nokia 5110 
phone.

=head1 METHODS

=head2 new

     new({
        dev      => 0,
        speed    => Device::PCD8544->SPEED_4MHZ,
        webio    => $webio,
        power    => 2,
        rst      => 24,
        dc       => 23,
        contrast => 0x60,
        bias     => Device::PCD8544->BIAS_1_48,
    }); 

Constructor.  Params:

=over 4

=item * dev: SPI device number against the C<webio> object

=item * speed: SPI speed to run at.  Using C<SPEED_4MHZ> is good for most purposes.  If you're running at much less than 3V, you may want to reduce this to C<SPEED_2MHZ>.

=item * webio: C<Device::WebIO> object that does the C<DigitalOutput> and C<SPI> roles.

=item * power: GPIO pin that's powering the device.  As the display itself only draws a few milliamps, it's safe to power it from GPIO.

=item * rst: GPIO pin for the reset wire.

=item * dc: GPIO pin for the Data/Control wire.

=item * contrast: Contrast level for the display.  This should be between 0x00 and 0x7F.  0x3C is usually a nice default.

=item * bias: Set bias level of the device.  Default is BIAS_1_48.  See the device datasheet for details.

=back

=head2 init

Sets up the pins and brings the device up.  Must be called before doing anything
else.

=head2 set_image

  set_image( \@IMG );

Sets an arrayref image.  Each entry is an 8-bit word, with each bit representing 
a pixel.  See C<Device::PCD8544::ConvertImage> for converting Imager objects 
into this format.

Be sure to call C<update()> to actually send the image to the display.

=head2 update

Send our image buffer to the display.

=head2 reset

Reset the device.

=head2 contrast

    contrast( 0x40 )

Set the contrast on the device.

=head2 bias

    $self->bias( $self->BIAS_1_80 )

Set the bias on the device.  See the datasheet for details.  The following 
constants are defined:

    BIAS_1_100
    BIAS_1_80
    BIAS_1_65
    BIAS_1_48
    BIAS_1_40
    BIAS_1_24
    BIAS_1_18
    BIAS_1_10

=head2 display_blank

Blank out all pixels on the display.

=head2 display_normal

Normal display mode of black on white background.

=head2 display_all_on

Turns on all pixels.

=head2 display_inverse

Inverse display mode of white on black background.

=head1 SEE ALSO

Datasheet: L<http://www.sparkfun.com/datasheets/LCD/Monochrome/Nokia5110.pdf>

=head1 LICENSE

Copyright (c) 2015  Timm Murray
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
