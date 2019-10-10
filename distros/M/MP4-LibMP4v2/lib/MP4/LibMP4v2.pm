package MP4::LibMP4v2;
use 5.008001;
use strict;
use warnings;
use Exporter 'import';

our $VERSION = "0.01";

use XSLoader;
XSLoader::load(__PACKAGE__, $VERSION);

1;
__END__

=encoding utf-8

=head1 NAME

MP4::LibMP4v2 - Perl interface to the libmp4v2

=head1 SYNOPSIS

    use MP4::LibMP4v2;
    my $mp4 = MP4::LibMP4v2->read('/path/to/movie.mp4');
    my $num_tracks = $mp4->get_number_of_tracks;
    for (my $i = 0; $i < $num_tracks; $i++) {
        my $track_id = $mp4->find_track_id($i);
        my $bit_rate = $mp4->get_track_bit_rate($track_id);
    }

=head1 DESCRIPTION

The MP4::LibMP4v2 module provides an interface to the libmp4v2.
This module supports libmp4v4 version 2 or above.
Please use L<MP4::File> for its version 1.

=head1 METHODS

=head2 MP4::LibMP4v2->optimize($filename [, $to_filename])

Optimize the mp4 file.

=head2 MP4::LibMP4v2->read($filename) :MP4::LibMP4v2

Read the file and return an instance of MP4::LibMP4v2.

=head2 MP4::LibMP4v2->set_log_level($level)

Set log level. Defaults to MP4_LOG_NONE.

=head2 MP4::LibMP4v2->get_log_level() :Int

Get log level.

=head2 $mp4->get_file_name() :Str

=head2 $mp4->info() :Str

=head2 $mp4->have_atom($atom_name) :Bool

=head2 $mp4->get_integer_property($prop_name) :Int

=head2 $mp4->get_float_property($prop_name) :Num

=head2 $mp4->get_string_property($prop_name) :Str

=head2 $mp4->get_bytes_property($prop_name) :ArrayRef[Str]

=head2 $mp4->get_duration() :Int

=head2 $mp4->get_time_scale() :Int

=head2 $mp4->get_od_profile_level() :Int

=head2 $mp4->get_scene_profile_level() :Int

=head2 $mp4->get_video_profile_level() :Int

=head2 $mp4->get_audio_profile_level() :Int

=head2 $mp4->get_graphics_profile_level() :Int

=head2 $mp4->get_number_of_tracks() :Int

=head2 $mp4->find_track_id($index [, $type, $subtype]) :Int

=head2 $mp4->find_track_index($track_id) :Int

=head2 $mp4->get_track_duration_per_chunk($track_id) :Int

=head2 $mp4->have_track_atom($track_id, $atom_name) :Bool

=head2 $mp4->get_track_type($track_id) :Str

=head2 $mp4->get_track_media_data_name($track_id) :Str

=head2 $mp4->get_track_media_original_format($track_id) :Str

=head2 $mp4->get_track_duration($track_id) :Int

=head2 $mp4->get_track_time_scale($track_id) :Int

=head2 $mp4->get_track_language($track_id) :Str

=head2 $mp4->get_track_name($track_id) :Str

=head2 $mp4->get_track_audio_mpeg4_type($track_id) :Int

=head2 $mp4->get_track_esds_object_type_id($track_id) :Int

=head2 $mp4->get_track_fixed_sample_duration($track_id) :Int

=head2 $mp4->get_track_bit_rate($track_id) :Int

=head2 $mp4->get_track_video_metadata($track_id) :ArrayRef[Str]

=head2 $mp4->get_track_es_configuration($track_id) :ArrayRef[Str]

=head2 $mp4->get_track_h264_length_size($track_id) :Int

=head2 $mp4->get_track_number_of_samples($track_id) :Int

=head2 $mp4->get_track_video_width($track_id) :Int

=head2 $mp4->get_track_video_height($track_id) :Int

=head2 $mp4->get_track_video_frame_rate($track_id) :Num

=head2 $mp4->get_track_audio_channels($track_id) :Int

=head2 $mp4->is_isma_cryp_media_track($track_id) :Bool

=head2 $mp4->get_track_integer_property($track_id, $prop_name) :Int

=head2 $mp4->get_track_float_property($track_id, $prop_name) :Num

=head2 $mp4->get_track_string_property($track_id, $prop_name) :Str

=head2 $mp4->get_track_bytes_property($track_id, $prop_name) :ArrayRef[Str]

=head2 $mp4->get_hint_track_rtp_payload($track_id) :Str

=head2 $mp4->convert_from_movie_duration($duration, $time_scale) :Int

=head2 $mp4->convert_from_track_timestamp($track_id, $timestamp, $time_scale) :Int

=head2 $mp4->convert_to_track_timestamp($track_id, $timestamp, $time_scale) :Int

=head2 $mp4->convert_from_track_duration($track_id, $duration, $time_scale) :Int

=head2 $mp4->convert_to_track_duration($track_id, $duration, $time_scale) :Int

=head1 CONSTANTS

=head2 MP4_LOG_NONE

=head2 MP4_LOG_ERROR

=head2 MP4_LOG_WARNING

=head2 MP4_LOG_INFO

=head2 MP4_LOG_VERBOSE1

=head2 MP4_LOG_VERBOSE2

=head2 MP4_LOG_VERBOSE3

=head2 MP4_LOG_VERBOSE4

=head2 MP4_OD_TRACK_TYPE

=head2 MP4_SCENE_TRACK_TYPE

=head2 MP4_AUDIO_TRACK_TYPE

=head2 MP4_VIDEO_TRACK_TYPE

=head2 MP4_HINT_TRACK_TYPE

=head2 MP4_CNTL_TRACK_TYPE

=head2 MP4_TEXT_TRACK_TYPE

=head2 MP4_SUBTITLE_TRACK_TYPE

=head2 MP4_SUBPIC_TRACK_TYPE

=head2 MP4_CLOCK_TRACK_TYPE

=head2 MP4_MPEG7_TRACK_TYPE

=head2 MP4_OCI_TRACK_TYPE

=head2 MP4_IPMP_TRACK_TYPE

=head2 MP4_MPEGJ_TRACK_TYPE

=head2 MP4_SECONDS_TIME_SCALE

=head2 MP4_MILLISECONDS_TIME_SCALE

=head2 MP4_MICROSECONDS_TIME_SCALE

=head2 MP4_NANOSECONDS_TIME_SCALE

=head2 MP4_SECS_TIME_SCALE

=head2 MP4_MSECS_TIME_SCALE

=head2 MP4_USECS_TIME_SCALE

=head2 MP4_NSECS_TIME_SCALE

=head2 MP4_MPEG4_INVALID_AUDIO_TYPE

=head2 MP4_MPEG4_AAC_MAIN_AUDIO_TYPE

=head2 MP4_MPEG4_AAC_LC_AUDIO_TYPE

=head2 MP4_MPEG4_AAC_SSR_AUDIO_TYPE

=head2 MP4_MPEG4_AAC_LTP_AUDIO_TYPE

=head2 MP4_MPEG4_AAC_HE_AUDIO_TYPE

=head2 MP4_MPEG4_AAC_SCALABLE_AUDIO_TYPE

=head2 MP4_MPEG4_CELP_AUDIO_TYPE

=head2 MP4_MPEG4_HVXC_AUDIO_TYPE

=head2 MP4_MPEG4_TTSI_AUDIO_TYPE

=head2 MP4_MPEG4_MAIN_SYNTHETIC_AUDIO_TYPE

=head2 MP4_MPEG4_WAVETABLE_AUDIO_TYPE

=head2 MP4_MPEG4_MIDI_AUDIO_TYPE

=head2 MP4_MPEG4_ALGORITHMIC_FX_AUDIO_TYPE

=head2 MP4_MPEG4_ALS_AUDIO_TYPE

=head2 MP4_MPEG4_LAYER1_AUDIO_TYPE

=head2 MP4_MPEG4_LAYER2_AUDIO_TYPE

=head2 MP4_MPEG4_LAYER3_AUDIO_TYPE

=head2 MP4_MPEG4_SLS_AUDIO_TYPE

=head1 SEE ALSO

L<https://github.com/sergiomb2/libmp4v2>, L<MP4::File>

=head1 LICENSE

Copyright (C) Jiro Nishiguchi.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Jiro Nishiguchi E<lt>jiro@cpan.orgE<gt>

=cut
