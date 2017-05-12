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
use lib 't/lib';
use PlackTest;
use HTTP::Request::Common;
use Device::WebIO::Dancer;
use Device::WebIO;
use MockVideoOutput;

my $STREAM_FILE = 't_data/wumpus_video_dump.h264';

my $vid = MockVideoOutput->new({
    stream_vid_file => $STREAM_FILE,
    content_type    => [ 'video/h264' ],
    _vid_width      => [ 640 ],
    _vid_height     => [ 480 ],
    _vid_fps        => [ 30  ],
    _vid_kbps       => [ 500 ],
});
my $webio = Device::WebIO->new;
$webio->register( 'foo', $vid );
my $test = PlackTest->get_plack_test( $webio );

my $res = $test->request( GET '/devices/foo/video/count' );
cmp_ok( $res->code, '==', 200, "Got video count response" );
cmp_ok( $res->content, 'eq', 1, "Got video count" );

$res = $test->request( GET '/devices/foo/video/0/resolution' );
cmp_ok( $res->code, '==', 200, "Got video resolution/framerate response" );
cmp_ok( $res->content, 'eq', '640x480p30' );

$res = $test->request( POST '/devices/foo/video/0/resolution/1024/768/60' );
cmp_ok( $res->code, '==', 200, "Set resolution/framerate" );

$res = $test->request( GET '/devices/foo/video/0/resolution' );
cmp_ok( $res->code, '==', 200, "Got new video resolution/framerate response" );
cmp_ok( $res->content, 'eq', '1024x768p60' );

$res = $test->request( GET '/devices/foo/video/0/kbps' );
cmp_ok( $res->code, '==', 200, "Got video bitrate response" );
cmp_ok( $res->content, 'eq', '500' );

$res = $test->request( POST '/devices/foo/video/0/kbps/1000' );
cmp_ok( $res->code, '==', 200, "Set resolution/framerate" );

$res = $test->request( GET '/devices/foo/video/0/kbps' );
cmp_ok( $res->code, '==', 200, "Got new video bitrate response" );
cmp_ok( $res->content, 'eq', '1000' );

$res = $test->request( GET '/devices/foo/video/0/allowed-content-types' );
cmp_ok( $res->code, '==', 200, "Got video allowed content type response" );
cmp_ok( $res->content, 'eq', 'video/h264' );

SKIP: {
    skip q{Plack::Test doesn't seem to handle streaming correctly}, 2;

    $res = $test->request( GET '/devices/foo/video/0/stream/video/h264' );
    cmp_ok( $res->code, '==', 200, "Got video stream" );
    cmp_ok( length($res->content), '==', -s $STREAM_FILE );
}

# TODO error for trying to read a stream with an unsupported content type
