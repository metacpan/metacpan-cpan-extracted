#!perl

use strict;
use warnings;
use FFmpeg::Command;
use Test::More qw( no_plan );

my $ffmpeg = FFmpeg::Command->new;

$ffmpeg->input_file('in.mp4');

$ffmpeg->output_options({
    file                => 'out.mp4',
    format              => 'mp4',
    video_codec         => 'mpeg4',
    bitrate             => 600,
    frame_size          => '320x240',
    audio_codec         => 'libaac',
    audio_sampling_rate => 48000,
    audio_bit_rate      => 64,
});

my $cmd = $ffmpeg->_compose_command;

is(
    join(' ', @$cmd),
    $ffmpeg->ffmpeg . ' -y -i in.mp4 -acodec libaac -b 600 -f mp4 -vcodec mpeg4 -ar 48000 -s 320x240 -ab 64 out.mp4'
);

$ffmpeg = FFmpeg::Command->new;
$ffmpeg->input_options({ file => 'in.mp4' });
$ffmpeg->output_options({
    file   => 'out.mp4',
    device => 'ipod',
});

$cmd = $ffmpeg->_compose_command;
is(
    join(' ', @$cmd),
    $ffmpeg->ffmpeg . ' -y -i in.mp4 -b 600 -acodec libfaac -f mp4 -vcodec mpeg4 -ar 48000 -s 320x240 -ab 64 out.mp4'
);
