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
use Test::More tests => 14;
use v5.12;

use_ok( 'Device::WebIO::Exceptions' );
use_ok( 'Device::WebIO' );
use_ok( 'Device::WebIO::Device' );
use_ok( 'Device::WebIO::Device::DigitalInput' );
use_ok( 'Device::WebIO::Device::DigitalOutput' );
use_ok( 'Device::WebIO::Device::DigitalInputCallback' );
use_ok( 'Device::WebIO::Device::ADC' );
use_ok( 'Device::WebIO::Device::PWM' );
use_ok( 'Device::WebIO::Device::SPI' );
use_ok( 'Device::WebIO::Device::I2CProvider' );
use_ok( 'Device::WebIO::Device::I2CUser' );
use_ok( 'Device::WebIO::Device::Serial' );
use_ok( 'Device::WebIO::Device::OneWire' );
use_ok( 'Device::WebIO::Device::VideoOutput' );
