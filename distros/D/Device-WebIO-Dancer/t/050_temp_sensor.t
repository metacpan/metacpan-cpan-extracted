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
use Test::More tests => 6;
use v5.12;
use lib 't/lib';
use PlackTest;
use HTTP::Request::Common;
use Device::WebIO::Dancer;
use Device::WebIO;
use MockTempSensor;

my $temp = MockTempSensor->new;
my $webio = Device::WebIO->new;
$webio->register( 'foo', $temp );
my $test = PlackTest->get_plack_test( $webio );

$temp->set_celsius( 0 );

my $res = $test->request( GET '/devices/foo/sensor/temperature/c' );
cmp_ok( $res->code, '==', 200, "Got celsius response" );
cmp_ok( $res->content, 'eq', '0' );

$res = $test->request( GET '/devices/foo/sensor/temperature/k' );
cmp_ok( $res->code, '==', 200, "Got kelvin response" );
cmp_ok( $res->content, 'eq', '273.15' );

$res = $test->request( GET '/devices/foo/sensor/temperature/f' );
cmp_ok( $res->code, '==', 200, "Got fahrenheit" );
cmp_ok( $res->content, 'eq', '32' );
