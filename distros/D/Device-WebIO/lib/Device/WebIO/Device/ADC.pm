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
package Device::WebIO::Device::ADC;
$Device::WebIO::Device::ADC::VERSION = '0.010';
use v5.12;
use Moo::Role;

with 'Device::WebIO::Device';

requires 'adc_bit_resolution';
requires 'adc_volt_ref';
requires 'adc_pin_count';
requires 'adc_input_int';


sub adc_max_int
{
    my ($self, $pin) = @_;
    my $bit_resolution = $self->adc_bit_resolution( $pin );
    return 2 ** $bit_resolution - 1;
}

sub adc_input_float
{
    my ($self, $pin) = @_;
    my $in       = $self->adc_input_int( $pin );
    my $max_int  = $self->adc_max_int( $pin );
    my $in_float = $in / $max_int;
    return $in_float;
}

sub adc_input_volts
{
    my ($self, $pin) = @_;
    my $in_float = $self->adc_input_float( $pin );
    my $volt_ref = $self->adc_volt_ref( $pin );
    my $in_volt  = $volt_ref * $in_float;
    return $in_volt;
}


1;
__END__


=head1 NAME

  Device::WebIO::Device::ADC - Role for Analog-to-Digital Input Converters

=head1 REQUIRED METHODS

=head2 adc_bit_resolution

    adc_bit_resolution( $pin );

Return the resolution for the given pin.

=head2 adc_volt_ref

    adc_volt_ref( $pin );

Return the voltage reference for the given pin.

=head2 adc_pin_count

    adc_pin_count();

Return the number of ADC pins.

=head2 adc_input_int

    adc_input_int( $pin );

Return the integer input value for the given pin.

=head1 PROVIDED METHODS

=head2 adc_max_int

    adc_max_int( $pin );

Return the maximum integer value for the given pin.  In the default 
implementation, this is calculated based on C<adc_bit_resolution()>.

=head2 adc_input_float

    adc_input_float( $pin );

Returns a floating point number of the input between 0.0 and 1.0.  In the 
default implementation, this is calculated based on C<adc_input_int()> and 
C<adc_max_int()>.

=head2 adc_input_volt

    adc_input_volt( $pin );

Returns the voltage level input of the pin.  In the default implementation, 
this is calculated based on <adc_input_float()> and C<adc_volt_ref()>.

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
