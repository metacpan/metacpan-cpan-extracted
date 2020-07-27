use strict;
use warnings;

use Test::More 0.98;

use Media::MediaInfoLib qw(
    STREAM_GENERAL
    STREAM_AUDIO
    STREAM_VIDEO
);

my $info = Media::MediaInfoLib->open('t/small.mp4');
isa_ok $info, 'Media::MediaInfoLib';
is $info->count_get(STREAM_AUDIO), 1;
is $info->count_get(STREAM_VIDEO), 1;
is $info->get(STREAM_GENERAL, 0, 'CodecID'), 'mp42';
is $info->get(STREAM_VIDEO, 0, 'BitRate'), 465642;
is $info->get(STREAM_VIDEO, 0, 'Width'), 560;
is $info->get(STREAM_VIDEO, 0, 'Height'), 320;
is $info->get(STREAM_VIDEO, 0, 'Duration'), 5533;
is $info->get(STREAM_VIDEO, 0, 'FrameRate'), '30.000';
is $info->get(STREAM_VIDEO, 0, 'ScanType'), 'Progressive';
is $info->get(STREAM_AUDIO, 0, 'Format'), 'AAC';
is $info->get(STREAM_AUDIO, 0, 'Channels'), '1';
is $info->get(STREAM_AUDIO, 0, 'BitRate'), '83051';
is $info->get(STREAM_AUDIO, 0, 'SamplingRate'), '48000';

# open from content
undef $info;
$info = Media::MediaInfoLib->open(\do { open my $fh, '<', 't/small.mp4' or die $!; local $/; <$fh> });
isa_ok $info, 'Media::MediaInfoLib';

done_testing;
