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
use Test::More tests => 3;
use v5.14;
use lib 't/lib/';
use Device::WebIO;
use MockDigitalInput;

my $webio = Device::WebIO->new;
my $input = MockDigitalInput->new({
    input_pin_count => 4,
});
$webio->register( 'foo', $input );

is_deeply( $webio->pin_desc( 'foo' ), [qw{
    V50 GND GND 0 1 2 3 GND
}]);

is_deeply( $webio->all_desc( 'foo' ), {
    UART    => 0,
    SPI     => 0,
    I2C     => 0,
    ONEWIRE => 0,
    GPIO    => {
        0 => { function => 'IN', value => 0 },
        1 => { function => 'IN', value => 0 },
        2 => { function => 'IN', value => 0 },
        3 => { function => 'IN', value => 0 },
    },
});

$input->mock_set_input( 0, 1 );

is_deeply( $webio->all_desc( 'foo' ), {
    UART    => 0,
    SPI     => 0,
    I2C     => 0,
    ONEWIRE => 0,
    GPIO    => {
        0 => { function => 'IN', value => 1 },
        1 => { function => 'IN', value => 0 },
        2 => { function => 'IN', value => 0 },
        3 => { function => 'IN', value => 0 },
    },
});
