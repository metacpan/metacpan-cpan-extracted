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
use Test::More tests => 12;
use v5.12;
use lib 't/lib/';
use Device::WebIO;
use MockDigitalInputOutput;

my $io = MockDigitalInputOutput->new;
ok( $io->does( 'Device::WebIO::Device::DigitalInput' ),
    "Does DigitalInput role" );
ok( $io->does( 'Device::WebIO::Device::DigitalOutput' ),
    "Does DigitalOutput role" );

my $webio = Device::WebIO->new;
$webio->register( 'foo', $io );

cmp_ok( $webio->digital_input_pin_count( 'foo' ), '==', 10,
    "Input pin count" );
cmp_ok( $webio->digital_output_pin_count( 'foo' ), '==', 8,
    "Output pin count" );

$webio->set_as_input( 'foo', 0 );
$webio->set_as_output( 'foo', 1 );
ok( $webio->is_set_input( 'foo', 0 ), "Pin 0 set as input" );
ok( $webio->is_set_output( 'foo', 1 ), "Pin 1 set as output" );

$io->mock_set_input( 0, 1 );
ok( $webio->digital_input( 'foo', 0 ), "Input 1 on pin 0" );
$webio->digital_output( 'foo', 1, 1 );
ok( $io->mock_get_output( 1 ), "Output 1 on pin 1" );

cmp_ok( $webio->digital_input_port( 'foo' ), '==', 0b0000000011, 
    "Read whole port" );

$webio->digital_output_port( 'foo', 0b00110000 );
cmp_ok( $io->mock_get_output( 1 ), '==', 0, "Port write pin 0" );
cmp_ok( $io->mock_get_output( 4 ), '==', 1, "Port write pin 5" );

eval {
    $webio->set_as_output( 'foo', 9 );
};
ok( ($@ && Device::WebIO::PinDoesNotExistException->caught( $@ )),
    "Caught exception for using too high a pin on set_as_output()" );
