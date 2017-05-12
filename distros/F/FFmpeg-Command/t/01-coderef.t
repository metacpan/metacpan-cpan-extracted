#!perl

use strict;
use warnings;
use FFmpeg::Command;
use Test::More tests => 2;

BEGIN {
    use_ok( 'FFmpeg::Command' );
}

my $ff = FFmpeg::Command->new();
$ff->options( [ '-version' ] );

my $stderr;
$ff->stderr(sub { $stderr .= $_[0] });

my $stdout;
$ff->stdout(sub { $stdout .= $_[0] });

$ff->exec();

my $out = $stderr || $stdout;

my $expected = $ff->ffmpeg . ' version';
like $out, qr/^$expected/i;
