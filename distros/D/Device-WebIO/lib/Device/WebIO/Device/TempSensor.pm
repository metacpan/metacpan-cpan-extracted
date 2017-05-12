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
package Device::WebIO::Device::TempSensor;
$Device::WebIO::Device::TempSensor::VERSION = '0.010';
use v5.12;
use Moo::Role;

with 'Device::WebIO::Device';
requires 'temp_kelvins';
requires 'temp_celsius';
requires 'temp_fahrenheit';


sub _convert_c_to_k
{
    my ($self, $val) = @_;
    return $val + 273.15
}

sub _convert_c_to_f
{
    my ($self, $val) = @_;
    return (9/5) * $val + 32;
}

sub _convert_f_to_k
{
    my ($self, $val) = @_;
    return $self->_convert_c_to_k(
        $self->_convert_f_to_c( $val )
    );
}

sub _convert_f_to_c
{
    my ($self, $val) = @_;
    return (5/9) * ($val - 32);
}

sub _convert_k_to_c
{
    my ($self, $val) = @_;
    return $val - 273.15;
}

sub _convert_k_to_f
{
    my ($self, $val) = @_;
    return $self->_convert_c_to_f(
        $self->_convert_k_to_c( $val )
    );
}



1;
__END__


=head1 NAME

  Device::WebIO::Device::TempSensor - Role for Temperature Sensors

=head1 PROVIDED CONVERSION METHODS

These are mainly for internal use.  A given temperature sensor will probably 
return values in one type of unit (usually Celsius or Kelvin).  Use these 
to convert to all other types.

Each of these take a value in one unit, and return in another.

=over

=item * _convert_f_to_k

=item * _convert_f_to_c

=item * _convert_c_to_k

=item * _convert_c_to_f

=item * _convert_k_to_c

=item * _convert_k_to_f

=back

=head1 REQUIRED METHODS

These all return the temperature in the given unit.  Generally, the 
implementation will return one of these as its "natural" unit type, and then 
do conversions for the rest.

=over

=item * temp_kelvins

=item * temp_celsius

=item * temp_fahrenheit

=back

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
