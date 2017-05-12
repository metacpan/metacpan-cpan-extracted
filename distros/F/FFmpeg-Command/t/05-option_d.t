#!perl

use strict;
use warnings;
use FFmpeg::Command;
use Test::More qw( no_plan );

my $ffmpeg = FFmpeg::Command->new;

$ffmpeg->options(qw/-ga -gb -ia1 -ib1 -i filename1 -ia2 -ib2 -i filename2 -oa -ob output_file/);

my $cmd = $ffmpeg->_compose_command;

is(
    join(' ', @$cmd),
    $ffmpeg->ffmpeg . ' -y -ga -gb -ia1 -ib1 -i filename1 -ia2 -ib2 -i filename2 -oa -ob output_file',
);
