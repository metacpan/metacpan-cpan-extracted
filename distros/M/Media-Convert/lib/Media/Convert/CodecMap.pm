package Media::Convert::CodecMap;

use strict;
use warnings;

use Exporter 'import';

our @EXPORT_OK=qw/detect_to_write/;

my %writemap = (
	'vorbis' => 'libvorbis',
	'vp8' => 'libvpx',
	'vp9' => 'libvpx-vp9',
	'h264' => 'libx264',
	'hevc' => 'libx265',
	'opus' => 'libopus',
);

open my $check_fdk, "-|", "ffmpeg -hide_banner -h encoder=libfdk_aac";
if(<$check_fdk> !~ /is not recognized/) {
	$writemap{aac} = 'libfdk_aac';
}
close $check_fdk;

sub detect_to_write {
	my $detected = shift;
	if(exists($writemap{$detected})) {
		return $writemap{$detected};
	} else {
		return $detected;
	}
}

1;
