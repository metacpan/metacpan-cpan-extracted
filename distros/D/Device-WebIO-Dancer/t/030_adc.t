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
use Test::More tests => 18;
use v5.14;
use lib 't/lib';
use PlackTest;
use HTTP::Request::Common;
use Device::WebIO::Dancer;
use Device::WebIO;
use MockADCInput;

my $io = MockADCInput->new({
    adc_bit_resolution_by_pin  => [ (8) x 2, (10) x 6 ],
    adc_volt_ref_by_pin        => [ (5.0) x 2, (3.3) x 6 ],
    adc_pin_count              => 8,
});
$io->mock_set_input( 0, 255 );
$io->mock_set_input( 1, 0 );
$io->mock_set_input( 2, 127 );

my $webio = Device::WebIO->new;
$webio->register( 'foo', $io );
my $test = PlackTest->get_plack_test( $webio );

my $res = $test->request( GET "/devices/foo/analog/count" );
cmp_ok( $res->code, '==', 200, "Got adc input count response" );
cmp_ok( $res->content, '==', 8 );

$res = $test->request( GET "/devices/foo/analog/0/maximum" );
cmp_ok( $res->code, '==', 200, "Got adc max response" );
cmp_ok( $res->content, '==', 2**8 - 1 );

$res = $test->request( GET "/devices/foo/analog/maximum" );
cmp_ok( $res->code, '==', 200, "Got adc max response from default pin" );
cmp_ok( $res->content, '==', 2**8 - 1 );

$res = $test->request( GET "/devices/foo/analog/0/integer/vref" );
cmp_ok( $res->code, '==', 200, "Got adc vref response" );
cmp_ok( $res->content, '==', 5.0 );

$res = $test->request( GET "/devices/foo/analog/integer/vref" );
cmp_ok( $res->code, '==', 200, "Got adc vref response from default pin" );
cmp_ok( $res->content, '==', 5.0 );

$res = $test->request( GET "/devices/foo/analog/0/integer" );
cmp_ok( $res->code, '==', 200, "Got adc input integer response" );
cmp_ok( $res->content, '==', 255 );

$res = $test->request( GET "/devices/foo/analog/0/float" );
cmp_ok( $res->code, '==', 200, "Got adc input float response" );
cmp_ok( $res->content, '==', 1 );

$res = $test->request( GET "/devices/foo/analog/0/volt" );
cmp_ok( $res->code, '==', 200, "Got adc input volt response" );
cmp_ok( $res->content, '==', 5.0 );

$res = $test->request( GET "/devices/foo/analog/*/integer" );
cmp_ok( $res->code, '==', 200, "Got adc input all response" );
cmp_ok( $res->content, 'eq', '255,0,127,0,0,0,0,0' );
