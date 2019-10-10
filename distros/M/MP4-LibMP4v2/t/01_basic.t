use strict;
use warnings;

use Test::More;
use MP4::LibMP4v2;

my $filename = 't/SampleVideo_1280x720_1mb.mp4';
my $mp4 = MP4::LibMP4v2->read($filename);
ok $mp4;
isa_ok $mp4, 'MP4::LibMP4v2';

is(MP4::LibMP4v2->get_log_level, MP4_LOG_NONE);
MP4::LibMP4v2->set_log_level(MP4_LOG_ERROR);
is(MP4::LibMP4v2->get_log_level, MP4_LOG_ERROR);
MP4::LibMP4v2->set_log_level(MP4_LOG_NONE);

is $mp4->get_file_name, $filename;
ok $mp4->info;

is $mp4->get_number_of_tracks, 2;

is $mp4->find_track_id(0), 1;
is $mp4->find_track_id(1), 2;
is $mp4->find_track_index(1), 0;
is $mp4->find_track_index(2), 1;
is $mp4->get_track_type(1), MP4_VIDEO_TRACK_TYPE;
is $mp4->get_track_type(2), MP4_AUDIO_TRACK_TYPE;

is $mp4->get_duration, 5312;
is $mp4->convert_from_movie_duration($mp4->get_duration, MP4_USECS_TIME_SCALE), 5312000;
is $mp4->get_time_scale, 1000;
is $mp4->get_od_profile_level, 0;
is $mp4->get_scene_profile_level, 0;
is $mp4->get_video_profile_level, 0;
is $mp4->get_audio_profile_level, 0;
is $mp4->get_graphics_profile_level, 0;
ok $mp4->have_atom('ftyp');
is $mp4->get_string_property('ftyp.majorBrand'), 'isom';
is $mp4->get_integer_property('ftyp.minorVersion'), 512;

subtest track1 => sub {
    my $track_id = 1;
    is $mp4->get_hint_track_rtp_payload($track_id)      => undef;
    is $mp4->get_track_audio_channels($track_id)        => -1;
    is $mp4->get_track_audio_mpeg4_type($track_id)      => 0;
    is $mp4->get_track_bit_rate($track_id)              => 1205959;
    is $mp4->get_track_duration($track_id)              => 67584;
    is $mp4->get_track_duration_per_chunk($track_id)    => 12800;
    is $mp4->get_track_es_configuration($track_id)      => undef;
    is $mp4->get_track_esds_object_type_id($track_id)   => 0;
    is $mp4->get_track_fixed_sample_duration($track_id) => 512;
    is $mp4->get_track_h264_length_size($track_id)      => 4;
    is $mp4->get_track_language($track_id)              => 'und';
    is $mp4->get_track_media_data_name($track_id)       => 'avc1';
    is $mp4->get_track_media_original_format($track_id) => undef;
    is $mp4->get_track_name($track_id)                  => undef;
    is $mp4->get_track_number_of_samples($track_id)     => 132;
    is $mp4->get_track_time_scale($track_id)            => 12800;
    is $mp4->get_track_type($track_id)                  => MP4_VIDEO_TRACK_TYPE;
    is $mp4->get_track_video_frame_rate($track_id)      => '25';
    is $mp4->get_track_video_height($track_id)          => 720;
    is $mp4->get_track_video_metadata($track_id)        => undef;
    is $mp4->get_track_video_width($track_id)           => 1280;
    is $mp4->is_isma_cryp_media_track($track_id)        => '';
};

subtest track2 => sub {
    my $track_id = 2;
    is $mp4->get_hint_track_rtp_payload($track_id)        => undef;
    is $mp4->get_track_audio_channels($track_id)          => 2;
    is $mp4->get_track_audio_mpeg4_type($track_id)        => MP4_MPEG4_AAC_LC_AUDIO_TYPE;
    is $mp4->get_track_bit_rate($track_id)                => 384829;
    is $mp4->get_track_duration($track_id)                => 254976;
    is $mp4->get_track_duration_per_chunk($track_id)      => 48000;
    is_deeply $mp4->get_track_es_configuration($track_id) => [17,176];
    is $mp4->get_track_esds_object_type_id($track_id)     => 64;
    is $mp4->get_track_fixed_sample_duration($track_id)   => 1024;
    is $mp4->get_track_h264_length_size($track_id)        => undef;
    is $mp4->get_track_language($track_id)                => 'und';
    is $mp4->get_track_media_data_name($track_id)         => 'mp4a';
    is $mp4->get_track_media_original_format($track_id)   => undef;
    is $mp4->get_track_name($track_id)                    => undef;
    is $mp4->get_track_number_of_samples($track_id)       => 249;
    is $mp4->get_track_time_scale($track_id)              => 48000;
    is $mp4->get_track_type($track_id)                    => MP4_AUDIO_TRACK_TYPE;
    is $mp4->get_track_video_frame_rate($track_id)        => '46.875';
    is $mp4->get_track_video_height($track_id)            => 0;
    is $mp4->get_track_video_metadata($track_id)          => undef;
    is $mp4->get_track_video_width($track_id)             => 0;
    is $mp4->is_isma_cryp_media_track($track_id)          => '';
};

done_testing;
