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
package Device::WebIO::TMP102;
$Device::WebIO::TMP102::VERSION = '0.002';
# ABSTRACT: Implement the TMP102 temperature sensor for Device::WebIO
use v5.14;
use warnings;
use Moo;
use namespace::autoclean;

use constant SLAVE_ADDR    => 0x48;
use constant TEMP_REGISTER => 0x00;


with 'Device::WebIO::Device::TempSensor';
with 'Device::WebIO::Device::I2CUser';

sub BUILDARGS
{
    my ($class, $args) = @_;
    $args->{address} //= $class->SLAVE_ADDR;
    return $args;
}


sub pin_desc
{
    # Placeholder
}

sub all_desc
{
    # Placeholder
}


sub temp_celsius
{
    my ($self) = @_;
    my $temp = $self->_read_temp;
    return $temp;
}

sub temp_kelvins
{
    my ($self) = @_;
    return $self->_convert_c_to_k( $self->temp_celsius );
}

sub temp_fahrenheit
{
    my ($self) = @_;
    return $self->_convert_c_to_f( $self->temp_celsius );
}


sub _read_temp
{
    my ($self) = @_;
    my $webio    = $self->webio;
    my $provider = $self->provider;
    my $channel  = $self->channel;
    my $addr     = $self->address;

    my ($temp1, $temp2) = $webio->i2c_read( $provider,
        $channel, $addr, $self->TEMP_REGISTER, 2 );
    my $temp = $self->_convert_reading( $temp1, $temp2 );
    return $temp
}


#####
# Taken from Device::Temperature::TMP102, which is under the following
# This software is Copyright (c) 2014 by Alex White.
#  
# This is free software, licensed under:
# 
# The (three-clause) BSD License
# 
# The BSD License
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
# 
# * Redistributions of source code must retain the above copyright
#   notice, this list of conditions and the following disclaimer.
# 
# * Redistributions in binary form must reproduce the above copyright
#   notice, this list of conditions and the following disclaimer in the
#   documentation and/or other materials provided with the distribution.
# 
# * Neither the name of Alex White nor the names of its
#   contributors may be used to endorse or promote products derived from
#   this software without specific prior written permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
# IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
# TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
# PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR
# CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
# PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
# PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
# LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
# NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
sub _convert_reading
{
    my ($self, $msb, $lsb) = @_;

    my $temp = ( $msb << 8 ) | $lsb;

    # The TMP102 temperature registers are left justified, correctly
    # right justify them
    $temp = $temp >> 4;

    # test for negative numbers
    if ( $temp & ( 1 << 11 ) ) {
        # twos compliment plus one, per the docs
        $temp = ~$temp + 1;

        # keep only our 12 bits
        $temp &= 0xfff;

        # negative
        $temp *= -1;
    }

    # convert to a celsius temp value
    $temp = $temp / 16;

    return $temp;
}
# End Device::Temperature::TMP102 code
#####


1;
__END__


=head1 NAME

  Device::WebIO::TMP102 - Implement the TMP102 temperature sensor in Device::WebIO

=head1 DESCRIPTION

Does the roles C<Device::WebIO::Device::TempSensor> and 
C<Device::WebIO::Device::I2CUser>.  You probably want to look at the docs 
for C<TempSensor> for how to use this.

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
