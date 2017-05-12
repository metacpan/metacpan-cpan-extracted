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
use Test::More tests => 11;
use v5.12;
use lib 't/lib';
use PlackTest;
use HTTP::Request::Common;
use Device::WebIO::Dancer;
use Device::WebIO;
use MockStillImageOutput;

my $STREAM_FILE = 't_data/test.jpg';

my $img = MockStillImageOutput->new({
    file         => $STREAM_FILE,
    content_type => [ 'image/jpeg' ],
    _img_width   => [ 640 ],
    _img_height  => [ 480 ],
});
my $webio = Device::WebIO->new;
$webio->register( 'foo', $img );
my $test = PlackTest->get_plack_test( $webio );

my $res = $test->request( GET '/devices/foo/image/count' );
cmp_ok( $res->code, '==', 200, "Got image count response" );
cmp_ok( $res->content, 'eq', 1, "Got image count" );

$res = $test->request( GET '/devices/foo/image/0/resolution' );
cmp_ok( $res->code, '==', 200, "Got img resolution response" );
cmp_ok( $res->content, 'eq', '640x480' );

$res = $test->request( POST '/devices/foo/image/0/resolution/1024/768' );
cmp_ok( $res->code, '==', 200, "Set resolution/framerate" );

$res = $test->request( GET '/devices/foo/image/0/resolution' );
cmp_ok( $res->code, '==', 200, "Got new image resolution/framerate response" );
cmp_ok( $res->content, 'eq', '1024x768' );

$res = $test->request( GET '/devices/foo/image/0/allowed-content-types' );
cmp_ok( $res->code, '==', 200, "Got image allowed content type response" );
cmp_ok( $res->content, 'eq', 'image/jpeg' );

$res = $test->request( GET '/devices/foo/image/0/stream/image/jpeg' );
cmp_ok( $res->code, '==', 200, "Got video stream" );
cmp_ok( length($res->content), '==', -s $STREAM_FILE );

# TODO error for trying to read a stream with an unsupported content type
