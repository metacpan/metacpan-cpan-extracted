#!perl

use strict;
use warnings;
use FFmpeg::Command;
use Test::More qw( no_plan );

my $ffmpeg = FFmpeg::Command->new;

$ffmpeg->options(qw/-ga -gb -ia -ib -oa -ob/);
$ffmpeg->input_file('filename1');
$ffmpeg->output_file('output_file');

my $cmd = $ffmpeg->_compose_command;

is(
    join(' ', @$cmd),
    $ffmpeg->ffmpeg . ' -y -i filename1 -ga -gb -ia -ib -oa -ob output_file'
);
