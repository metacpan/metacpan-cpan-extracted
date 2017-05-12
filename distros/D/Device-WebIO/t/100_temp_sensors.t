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
use v5.14;
use lib 't/lib/';
use Device::WebIO;
use MockTempSensor;


my $sensor = MockTempSensor->new;
my $webio  = Device::WebIO->new;
$webio->register( 'temp', $sensor );

$sensor->set_celsius( 0 );
cmp_ok( $webio->temp_celsius('temp'),    '==', 0,     "Got temp in celsius" );
cmp_ok( $webio->temp_kelvins('temp'),    '==', 273.15,"Got temp in kelvins" );
cmp_ok( $webio->temp_fahrenheit('temp'), '==', 32,    "Got temp in fahrenheit" );

$sensor->set_celsius( 100 );
cmp_ok( $webio->temp_celsius('temp'),    '==', 100,   "Got temp in celsius" );
cmp_ok( $webio->temp_kelvins('temp'),    '==', 373.15,"Got temp in kelvins" );
cmp_ok( $webio->temp_fahrenheit('temp'), '==', 212,   "Got temp in fahrenheit" );
