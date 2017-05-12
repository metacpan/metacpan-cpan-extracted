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
use Test::More tests => 9;
use v5.12;
use lib 't/lib/';
use MockStillImageOutput;
use Device::WebIO;

my $img = MockStillImageOutput->new({
    file         => 't_data/test.jpg',
    content_type => 'image/jpeg',
    _img_width   => [640],
    _img_height  => [480],
});
my $webio = Device::WebIO->new;
$webio->register( 'foo', $img );

cmp_ok( $webio->img_channels( 'foo' ), '==', 1,    "Channel count" );
cmp_ok( $webio->img_width( 'foo', 0 ), '==', 640,  "Width" );
cmp_ok( $webio->img_height( 'foo', 0 ), '==', 480, "Height" );
cmp_ok( $webio->img_quality( 'foo', 0 ), '==', 100, "Quality" );

$webio->img_set_width( 'foo', 0, 1920 );
$webio->img_set_height( 'foo', 0, 1080 );
$webio->img_set_quality( 'foo', 0, 90 );
cmp_ok( $webio->img_width( 'foo', 0 ),  '==', 1920, "Width" );
cmp_ok( $webio->img_height( 'foo', 0 ), '==', 1080, "Height" );
cmp_ok( $webio->img_quality( 'foo', 0 ), '==', 90,  "Quality" );

ok( 'image/jpeg' ~~ [ $webio->img_allowed_content_types( 'foo', 0 ) ],
    "Content-type image/jpeg is allowed" );

my $fh = $webio->img_stream( 'foo', 0, 'image/jpeg' );
cmp_ok( ref($fh), 'eq', 'GLOB', "Got video stream" );
close $fh;
