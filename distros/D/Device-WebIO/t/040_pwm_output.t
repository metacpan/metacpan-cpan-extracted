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
use Test::More tests => 13;
use v5.12;
use lib 't/lib/';
use Device::WebIO;
use MockPWMOutput;


my $output = MockPWMOutput->new({
    pwm_bit_resolution_by_pin => [ (8) x 2, (10) x 6 ],
    pwm_pin_count             => 8,
});
ok( $output->does( 'Device::WebIO::Device' ), "Does Device role" );
ok( $output->does( 'Device::WebIO::Device::PWM' ), "Does PWM role" );

my $webio = Device::WebIO->new;
$webio->register( 'foo', $output );

cmp_ok( $webio->pwm_count( 'foo' ),         '==',8, "Pin count" );
cmp_ok( $webio->pwm_resolution( 'foo', 0 ), '==',8, "Bit resolution pin 0");
cmp_ok( $webio->pwm_max_int( 'foo', 0 ),    '==',255, "Max int pin 0" );
cmp_ok( $webio->pwm_resolution( 'foo', 2 ), '==',10, "Bit resolution pin 0");
cmp_ok( $webio->pwm_max_int( 'foo', 2 ),    '==',1023, "Max int pin 0" );

$webio->pwm_output_int( 'foo', 0, 255 );
$webio->pwm_output_int( 'foo', 1, 0 );
$webio->pwm_output_float( 'foo', 2, 0.5 );
cmp_ok( $output->mock_get_output( 0 ), '==', 255, "PWM pin 0 set" );
cmp_ok( $output->mock_get_output( 1 ), '==', 0,   "PWM pin 1 set" );
cmp_ok( $output->mock_get_output( 2 ), '==', 512, "PWM pin 2 set" );


eval {
    $webio->pwm_output_int( 'foo', 10, 1 );
};
ok( ($@ && Device::WebIO::PinDoesNotExistException->caught( $@ )),
    "Caught exception for using too high a pin for pwm_output_int()" );

eval {
    $webio->pwm_output_float( 'foo', 10, 1 );
};
ok( ($@ && Device::WebIO::PinDoesNotExistException->caught( $@ )),
    "Caught exception for using too high a pin for pwm_output_float()" );

eval {
    $webio->digital_output( 'foo', 0 );
};
ok( ($@ && Device::WebIO::FunctionNotSupportedException->caught( $@ )),
    "Caught exception for using a digital output function on a"
        . " pwm-only object"
);
