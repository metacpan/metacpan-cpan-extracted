#!perl
use strict ;

use Data::Dumper ;

use Test::More tests => 1;

use Linux::DVB::DVBT::Advert ;


$Linux::DVB::DVBT::Advert::DEBUG = 10 ;

my $expected_settings = {
          'total_scene_frames' => 0,
          'total_size_frames' => 0,
# max_advert = 4501
# max_gap = 11
# min_advert = 4501
# min_frames = 1
# min_program = 7501
# num_frames = 96001
# pid = 401
# reduce_end = 1
# reduce_min_gap = 1501
# frame_window = 6

          'max_advert' => 4501,
          'min_advert' => 4501,
          'min_program' => 7501,
          'start_pad' => 3001,
          'end_pad' => 3001,
          'min_frames' => 1,
          'frame_window' => 6,
          'max_gap' => 11,
          'reduce_end' => 1,
          'reduce_min_gap' => 1501,
          
          'frame' => {
                       'max_gap' => 16,
                       'schange_jump' => 36,
                       'end_pad' => 3006,
                       'reduce_end' => 6,
                       'max_black' => 46,
                       'min_program' => 7506,
                       'noise_level' => 6,
                       'remove_logo' => 6,
                       'start_pad' => 3006,
                       'schange_cutlevel' => 86,
                       'min_frames' => 6,
                       'reduce_min_gap' => 1506,
                       'max_brightness' => 66,
                       'max_advert' => 4506,
                       'min_advert' => 4506,
                       'brightness_jump' => 206,
                       'window_percent' => 96,
                       'test_brightness' => 46,
                       'frame_window' => 6
                     },
          'total_logo_frames' => 0,
          'num_frames' => 1,
          'audio_pid' => 407,
          'detection_method' => 9,
          'logo' => {
                      'max_gap' => 18,
                      'logo_window' => 58,
                      'logo_skip_frames' => 28,
                      'logo_fall_threshold' => 58,
                      'logo_rise_threshold' => 88,
                      'end_pad' => 3008,
                      'logo_edge_threshold' => 8,
                      'reduce_end' => 8,
                      'logo_ave_points' => 258,
                      'logo_checking_period' => 30008,
                      'min_program' => 7508,
                      'logo_num_checks' => 8,
                      'logo_ok_percent' => 88,
                      'logo_edge_radius' => 8,
                      'logo_edge_step' => 8,
                      'logo_max_percentage_of_screen' => 18,
                      'start_pad' => 3008,
                      'min_frames' => 8,
                      'reduce_min_gap' => 1508,
                      'max_advert' => 4508,
                      'min_advert' => 4508,
                      'window_percent' => 98,
                      'frame_window' => 8
                    },
          'audio' => {
                       'silence_threshold' => -87,
                       'max_gap' => 17,
                       'start_pad' => 3007,
                       'silence_window' => 107,
                       'min_frames' => 7,
                       'end_pad' => 3007,
                       'reduce_min_gap' => 1507,
                       'reduce_end' => 7,
                       'max_advert' => 4507,
                       'min_advert' => 4507,
                       'min_program' => 7507,
                       'scale' => 7,
                       'frame_window' => 7
                     },
          'total_black_frames' => 0,
          'pid' => 401
        };


	## read file
	my $results_href = detect_from_file('t/det/test-set.det', {}) ;
	print Data::Dumper->Dump(['DET settings', $results_href->{'settings'}]) ;
	is_deeply($results_href->{'settings'}, $expected_settings) ;



