#!perl

use strict;
use warnings;
use FFmpeg::Command;
use Test::More qw( no_plan );

BEGIN {
	use_ok( 'FFmpeg::Command' );
}

diag( "Testing FFmpeg::Command $FFmpeg::Command::VERSION, Perl $], $^X" );

my $ff = FFmpeg::Command->new();
$ff->options( [ '-version' ] );
$ff->exec();
my $out = $ff->stderr || $ff->stdout;
my $expected = $ff->ffmpeg . ' version';
like $out, qr/^$expected/i;
