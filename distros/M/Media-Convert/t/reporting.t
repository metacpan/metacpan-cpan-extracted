#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More tests => 7;

use_ok('Media::Convert::Asset');
use_ok('Media::Convert::Pipe');

my $input = Media::Convert::Asset->new(url => 't/testvids/bbb.mp4');
my $output = Media::Convert::Asset->new(url => 't/testvids/out.ts', video_codec => 'mpeg2video');

my $old_perc;
my $ok = 1;

sub progress {
	my $perc = shift;

	print "progress: $perc\n";
	if(defined($old_perc) && $perc < $old_perc) {
		$ok = 0;
	}
	$old_perc = $perc;
}

my $pipe = Media::Convert::Pipe->new(inputs => [$input], output => $output, progress => \&progress, vcopy => 0, acopy => 0);

isa_ok($pipe, 'Media::Convert::Pipe');

$pipe->run;
ok($ok == 1, "progress information is strictly increasing");
ok($old_perc == 100, "progress stops at 100%");

$old_perc = undef;

unlink($output->url);
$output = Media::Convert::Asset->new(url => 't/testvids/out.webm', duration => 10, video_codec => 'vp8', audio_codec => 'libvorbis');
$pipe = Media::Convert::Pipe->new(inputs => [$input], output => $output, progress => \&progress, vcopy => 0, acopy => 0, multipass => 1);
$pipe->run;

ok($ok == 1, "progress information is strictly incresing when doing multipass");
ok($old_perc == 100, "progress stops at 100% when doing multipass");

unlink($output->url);
unlink($output->url . "-multipass-0.log");
