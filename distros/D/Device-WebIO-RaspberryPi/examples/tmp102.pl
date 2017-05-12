#!env perl
use v5.14;
use Device::WebIO;
use Device::WebIO::RaspberryPi;
use HiPi::Device::I2C ();
use constant DEVICE        => 1;
use constant SLAVE_ADDR    => 0x48;
use constant TEMP_REGISTER => 0x00;
use constant DEBUG         => 0;


my $webio = Device::WebIO->new;
my $rpi   = Device::WebIO::RaspberryPi->new;
$webio->register( 'rpi', $rpi );

while( 1 ) {
    my ($temp1, $temp2) = $webio->i2c_read( 'rpi',
        DEVICE, SLAVE_ADDR, TEMP_REGISTER, 2 );
    my $temp = convert_reading( $temp1, $temp2 );
    say 'Temp: ' . $temp . 'C';
    sleep 1;
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
sub convert_reading
{
    my ( $msb, $lsb ) = @_;

    printf( "msb:     %02x\n", $msb )   if DEBUG;
    printf( "lsb:     %02x\n", $lsb )   if DEBUG;

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
