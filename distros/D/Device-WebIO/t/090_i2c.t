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
use Test::More tests => 2;
use v5.14;
use lib 't/lib/';
use Device::WebIO;
use MockI2CProvider;
use MockI2CUser;


my $i2c_provider = MockI2CProvider->new({
    i2c_channels => 1,
});
my $webio = Device::WebIO->new;
$webio->register( 'i2c', $i2c_provider );

my $i2c_user = MockI2CUser->new({
    webio    => $webio,
    provider => 'i2c',
    address  => 0x42,
    channel  => 0,
});

$i2c_user->set_first_register( 5 );
cmp_ok( ($webio->i2c_read( 'i2c', 0, 0x42, 0x00, 1 ))[0], '==', 5,
    "Set/get first register" );
$webio->i2c_write( 'i2c', 0, 0x42, 0x01, 3 );
cmp_ok( ($i2c_user->get_second_register())[0], '==', 3,
    "Set/get second register" );
