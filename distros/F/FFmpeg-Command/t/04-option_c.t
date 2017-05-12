#!perl

use strict;
use warnings;
use FFmpeg::Command;
use Test::More qw( no_plan );

my $ffmpeg = FFmpeg::Command->new;

$ffmpeg->global_options(qw/-ga -gb/);
$ffmpeg->infile_options(qw/-ia -ib/);
$ffmpeg->outfile_options(qw/-oa -ob/);
$ffmpeg->input_file(['filename1','filename2']);
$ffmpeg->output_file('output_file');

my $cmd = $ffmpeg->_compose_command;

is(
    join(' ', @$cmd),
    $ffmpeg->ffmpeg . ' -y -ga -gb -ia -ib -i filename1 -ia -ib -i filename2 -oa -ob output_file'
);
