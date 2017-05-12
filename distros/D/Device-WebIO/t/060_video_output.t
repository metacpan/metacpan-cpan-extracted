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
use Test::More tests => 13;
use v5.12;
use lib 't/lib/';
use MockVideoOutput;
use Device::WebIO;

my $vid = MockVideoOutput->new({
    stream_vid_file => 't_data/wumpus_video_dump.h264',
    content_type    => 'video/h264',
    _vid_width       => [640],
    _vid_height      => [480],
    _vid_fps         => [30],
    _vid_kbps        => [500],
});
my $webio = Device::WebIO->new;
$webio->register( 'foo', $vid );

ok( $vid->does( 'Device::WebIO::Device' ), "Does Device role" );
ok( $vid->does( 'Device::WebIO::Device::VideoOutput' ),
    "Does VideoOutput role" );

cmp_ok( $webio->vid_channels( 'foo' ),    '==', 1,   "Channel count" );
cmp_ok( $webio->vid_width( 'foo', 0 ),  '==', 640, "Width" );
cmp_ok( $webio->vid_height( 'foo', 0 ), '==', 480, "Height" );
cmp_ok( $webio->vid_fps( 'foo', 0 ),    '==', 30,  "FPS" );
cmp_ok( $webio->vid_kbps( 'foo', 0 ),   '==', 500, "Kbps" );

$webio->vid_set_width( 'foo', 0, 1920 );
$webio->vid_set_height( 'foo', 0, 1080 );
$webio->vid_set_fps( 'foo', 0, 60 );
$webio->vid_set_kbps( 'foo', 0, 4000 );
cmp_ok( $webio->vid_width( 'foo', 0 ),  '==', 1920, "Width" );
cmp_ok( $webio->vid_height( 'foo', 0 ), '==', 1080, "Height" );
cmp_ok( $webio->vid_fps( 'foo', 0 ),    '==', 60,  "FPS" );
cmp_ok( $webio->vid_kbps( 'foo', 0 ),   '==', 4000, "Kbps" );

ok( 'video/h264' ~~ [ $webio->vid_allowed_content_types( 'foo', 0 ) ],
    "Content-type video/h264 is allowed" );

my $fh = $webio->vid_stream( 'foo', 0, 'video/h264' );
cmp_ok( ref($fh), 'eq', 'GLOB', "Got video stream" );
close $fh;
