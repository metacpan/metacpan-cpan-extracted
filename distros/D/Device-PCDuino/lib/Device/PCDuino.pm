# Copyright (c) 2014, Timm Murray
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
# 
# * Redistributions of source code must retain the above copyright notice, 
#   this list of conditions and the following disclaimer.
# 
# * Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.
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
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF 
# THE POSSIBILITY OF SUCH DAMAGE.
#
package Device::PCDuino;
$Device::PCDuino::VERSION = '0.001';
use v5.14;

# ABSTRACT: Control the pcDuino with Perl

use base 'Exporter';
our @EXPORT_OK = qw{
    set_input
    input
    set_output
    output
    input_adc
    output_pwm
};
our @EXPORT = @EXPORT_OK;

use constant MODE_FILE_PATH => '/sys/devices/virtual/misc/gpio/mode/gpio';
use constant PIN_FILE_PATH  => '/sys/devices/virtual/misc/gpio/pin/gpio';
use constant ADC_PIN_FILE_PATH => '/proc/adc';


sub set_input
{
    my ($pin) = @_;
    return _set_pin( $pin, 0 );
}

sub set_output
{
    my ($pin) = @_;
    return _set_pin( $pin, 1 );
}

sub input
{
    my ($pin) = @_;
    my $file = PIN_FILE_PATH . $pin;
    open( my $in, '<', $file, ) or die "Can't open '$file': $!\n";

    my $input = '';
    read( $in, $input, 4 );

    close $in;

    chomp $input;
    return $input;
}

sub output
{
    my ($pin, $output) = @_;
    my $file = PIN_FILE_PATH . $pin;
    open( my $out, '>', $file, ) or die "Can't open '$file': $!\n";
    print $out "$output";
    close $out;
    return 1;
}

sub input_adc
{
    my ($pin) = @_;
    my $path = ADC_PIN_FILE_PATH . $pin;

    open( my $in, '<', $path ) or die "Can't open '$path': $!\n";
    my $input = <$in>;
    close $in;

    my ($val) = $input =~ /\A [^:]* : ([0-9]+) /x;
    return $val;
}

sub output_pwm
{
    my ($pin, $output) = @_;

    return 1;
}

sub _set_pin
{
    my ($pin, $type) = @_;
    my $file = MODE_FILE_PATH . $pin;
    open( my $out, '>', $file, ) or die "Can't open '$file': $!\n";
    print $out "$type";
    close $out;
    return 1;
}


1;
__END__



=head1 NAME

  Device::PCDuino - Control the pcDuino with Perl

=head1 SYNOPSIS

  use Device::PCDuino;
  set_input( 0 );
  set_output( 1 );

  # Mirror the input from pin 0 to pin 1 );
  my $input = input( 0 );
  output( 1, $input );

  # Show value of ADC pin 0
  say input_adc( 0 )

=head1 DESCRIPTION

Hardware interface for the pcDuino.  Gives access to GPIO and ADC pins.

All functions documented below are exported by default

Before using, be sure to load the kernel modules.

  # modprobe gpio
  # modprobe adc
  # modprobe pwm

=head1 FUNCTIONS

=head2 set_input( PIN_NUMBER )

Set the given pin as an input pin.

=head2 set_output( PIN_NUMBER )

Set the given pin as an output pin.

=head2 input( PIN_NUMBER )

Get the boolean value of the given pin.

=head2 output( PIN_NUMBER, VALUE )

Set the boolean value of the given pin.

=head2 input_adc( ADC_PIN_NUMBER )

Get the value of the given ADC pin.

=head1 TODO

=over 4

=item * PWM

=item * I2C

=item * SPI

=item * Serial

=back

=head1 SEE ALSO

pcDuino Homepage: L<http://www.pcduino.com>

Author Homepage: L<https://www.wumpus-cave.net>

=head1 LICENSE

Copyright (c) 2014, Timm Murray
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this
  list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright notice,
  this list of conditions and the following disclaimer in the documentation
  and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut
