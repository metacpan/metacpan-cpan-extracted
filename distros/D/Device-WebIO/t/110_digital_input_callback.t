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
use Test::More tests => 16;
use v5.12;
use lib 't/lib/';
use Device::WebIO;
use MockDigitalInputCallback;

my $input = MockDigitalInputCallback->new({
    input_pin_count => 8,
});
my $webio = Device::WebIO->new;
$webio->register( 'foo', $input );

ok( $input->does( 'Device::WebIO::Device' ), "Does Device role" );
ok( $input->does( 'Device::WebIO::Device::DigitalInputCallback' ),
    "Does DigitalInputCallback role" );

$webio->set_as_input( 'foo', 0 );
$webio->set_as_input( 'foo', 1 );
$webio->set_as_input( 'foo', 2 );

ok( $webio->is_set_input( 'foo', 0 ), "Pin 0 set as input" );
ok( $webio->is_set_input( 'foo', 1 ), "Pin 1 set as input" );
ok( $webio->is_set_input( 'foo', 2 ), "Pin 2 set as input" );
ok(!$webio->is_set_input( 'foo', 3 ), "Pin 3 set as input" );

cmp_ok( $webio->digital_input_pin_count( 'foo' ), '==', 8,
    "Fetch pin count" );

my $RISING_CALL = 0;
my $FALLING_CALL = 0;
$webio->digital_input_callback( 'foo', 0, $input->TRIGGER_RISING,
    sub { $RISING_CALL++ } );
$webio->digital_input_callback( 'foo', 1, $input->TRIGGER_FALLING,
    sub { $FALLING_CALL++ });
$webio->digital_input_callback( 'foo', 2, $input->TRIGGER_RISING_FALLING, sub {
    my ($is_rising) = @_;
    if( $is_rising ) {
        $RISING_CALL++;
    }
    else {
        $FALLING_CALL++;
    }
});

$input->trigger_rising( 0 );
cmp_ok( $RISING_CALL, '==', 1 );
$input->trigger_rising( 1 );
cmp_ok( $RISING_CALL, '==', 1 );
$input->trigger_falling( 0 );
cmp_ok( $FALLING_CALL, '==', 0 );
$input->trigger_falling( 1 );
cmp_ok( $FALLING_CALL, '==', 1, );
$input->trigger_rising( 2 );
cmp_ok( $RISING_CALL, '==', 2, );
cmp_ok( $FALLING_CALL, '==', 1, );
$input->trigger_falling( 2 );
cmp_ok( $RISING_CALL, '==', 2, );
cmp_ok( $FALLING_CALL, '==', 2, );

ok( $webio->digital_input_begin_loop( 'foo' ), "Began loop" );
