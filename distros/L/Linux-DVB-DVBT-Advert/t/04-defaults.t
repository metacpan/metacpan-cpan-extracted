#!perl
use strict ;

use Data::Dumper ;

use Test::More tests => 2;

use Linux::DVB::DVBT::Advert ;


my $expected_defaults = {
          'total_scene_frames' => 0,
          'total_size_frames' => 0,

#define DEF_max_advert			(3*60*FPS)
#define DEF_min_advert			(3*60*FPS)
#define DEF_min_program			(5*60*FPS)
#define DEF_start_pad			(2*60*FPS)
#define DEF_end_pad				(2*60*FPS)
#define DEF_min_frames 	 		2
#define DEF_frame_window 	 	4
#define DEF_max_gap 		 	10
#define DEF_reduce_end			0
#define DEF_reduce_min_gap	 	60*FPS
          'max_advert' => 4500,
          'min_advert' => 4500,
          'min_program' => 7500,
          'start_pad' => 3000,
          'end_pad' => 3000,
          'min_frames' => 2,
          'frame_window' => 4,
          'max_gap' => 10,
          'reduce_end' => 0,
          'reduce_min_gap' => 1500,


#define FRAME_max_advert			(3*60*FPS) 4500
#define FRAME_min_advert			(3*60*FPS)
#define FRAME_min_program			(5*60*FPS) 7500
#define FRAME_start_pad				(2*60*FPS) 3000
#define FRAME_end_pad				(2*60*FPS)
#define FRAME_min_frames 	 		2
#define FRAME_frame_window 	 		(4*60*FPS) 6000
#define FRAME_max_gap 		 		(10*FPS)
#define FRAME_reduce_end			0
#define FRAME_reduce_min_gap	 	0
          'frame' => {
                       'max_gap' => 250,
                       'schange_jump' => 30,
                       'end_pad' => 3000,
                       'reduce_end' => 0,
                       'max_black' => 48,
                       'min_program' => 7500,
                       'noise_level' => 5,
                       'remove_logo' => 0,
                       'start_pad' => 3000,
                       'schange_cutlevel' => 85,
                       'min_frames' => 2,
                       'reduce_min_gap' => 0,
                       'max_brightness' => 60,
                       'max_advert' => 4500,
                       'min_advert' => 4500,
                       'brightness_jump' => 200,
                       'window_percent' => 95,
                       'test_brightness' => 40,
                       'frame_window' => 6000
                     },
                     
          'total_logo_frames' => 0,
          'num_frames' => 1,
          'audio_pid' => -1,
          'detection_method' => 7,


#define LOGO_max_advert			(3*60*FPS)
#define LOGO_min_advert			(3*60*FPS)
#define LOGO_min_program		(5*60*FPS)
#define LOGO_start_pad			(2*60*FPS)
#define LOGO_end_pad			(2*60*FPS)
#define LOGO_min_frames 	 	FPS
#define LOGO_frame_window 	 	20
#define LOGO_max_gap 		 	(10*FPS)
#define LOGO_reduce_end			0
#define LOGO_reduce_min_gap	 	(10*FPS)
          'logo' => {
                      'max_gap' => 250,
                      'logo_window' => 50,
                      'logo_skip_frames' => 25,
                      'logo_fall_threshold' => 50,
                      'logo_rise_threshold' => 80,
                      'end_pad' => 3000,
                      'logo_edge_threshold' => 5,
                      'reduce_end' => 0,
                      'logo_ave_points' => 250,
                      'logo_checking_period' => 30000,
                      'min_program' => 7500,
                      'logo_num_checks' => 5,
                      'logo_ok_percent' => 80,
                      'logo_edge_radius' => 2,
                      'logo_edge_step' => 1,
                      'logo_max_percentage_of_screen' => 10,
                      'start_pad' => 3000,
                      'min_frames' => 25,
                      'reduce_min_gap' => 250,
                      'max_advert' => 4500,
                      'min_advert' => 4500,
                      'window_percent' => 95,
                      'frame_window' => 20
                    },
                    
                    
#define AUDIO_max_advert			(4*60*FPS)
#define AUDIO_min_advert			(2*60*FPS)
#define AUDIO_min_program			(5*60*FPS)
#define AUDIO_start_pad				(2*60*FPS)
#define AUDIO_end_pad				(2*60*FPS)
#define AUDIO_min_frames 	 		2
#define AUDIO_frame_window 	 		(4*60*FPS)
#define AUDIO_max_gap 		 		(10*FPS)
#define AUDIO_reduce_end			0
#define AUDIO_reduce_min_gap	 	0
          'audio' => {
                       'silence_threshold' => -80,
                       'max_gap' => 250,
                       'start_pad' => 3000,
                       'silence_window' => 100,
                       'min_frames' => 2,
                       'end_pad' => 3000,
                       'reduce_min_gap' => 0,
                       'reduce_end' => 0,
                       'max_advert' => 6000,
                       'min_advert' => 3000,
                       'min_program' => 7500,
                       'scale' => 1,
                       'frame_window' => 6000
                     },
                     
                     
          'total_black_frames' => 0,
          'pid' => -1
        };

my $new_defaults = {
          'total_scene_frames' => 1,
          'total_size_frames' => 1,
          'max_advert' => 4504,
          'min_advert' => 4504,
          'min_program' => 7504,
          'start_pad' => 3004,
          'end_pad' => 3004,
          'min_frames' => 4,
          'frame_window' => 6004,
          'max_gap' => 14,
          'reduce_end' => 4,
          'reduce_min_gap' => 4,
          'frame' => {
                       'max_gap' => 11,
                       'schange_jump' => 31,
                       'end_pad' => 3001,
                       'reduce_end' => 1,
                       'max_black' => 49,
                       'min_program' => 7501,
                       'noise_level' => 6,
                       'remove_logo' => 1,
                       'start_pad' => 3001,
                       'schange_cutlevel' => 86,
                       'min_frames' => 3,
                       'reduce_min_gap' => 1501,
                       'max_brightness' => 61,
                       'max_advert' => 4501,
                       'min_advert' => 4502,
                       'brightness_jump' => 201,
                       'window_percent' => 96,
                       'test_brightness' => 41,
                       'frame_window' => 5
                     },
          'total_logo_frames' => 1,
          'num_frames' => 2,
          'audio_pid' => 202,
          'detection_method' => 8,
          'logo' => {
                      'max_gap' => 12,
                      'logo_window' => 52,
                      'logo_skip_frames' => 27,
                      'logo_fall_threshold' => 52,
                      'logo_rise_threshold' => 82,
                      'end_pad' => 3002,
                      'logo_edge_threshold' => 7,
                      'reduce_end' => 2,
                      'logo_ave_points' => 252,
                      'logo_checking_period' => 30002,
                      'min_program' => 7502,
                      'logo_num_checks' => 7,
                      'logo_ok_percent' => 82,
                      'logo_edge_radius' => 4,
                      'logo_edge_step' => 3,
                      'logo_max_percentage_of_screen' => 12,
                      'start_pad' => 3002,
                      'min_frames' => 4,
                      'reduce_min_gap' => 1502,
                      'max_advert' => 4502,
                      'min_advert' => 4502,
                      'window_percent' => 97,
                      'frame_window' => 6
                    },
          'audio' => {
                       'silence_threshold' => -83,
                       'max_gap' => 13,
                       'start_pad' => 3003,
                       'silence_window' => 103,
                       'min_frames' => 5,
                       'end_pad' => 3003,
                       'reduce_min_gap' => 1503,
                       'reduce_end' => 3,
                       'max_advert' => 4503,
                       'min_advert' => 4503,
                       'min_program' => 7503,
                       'scale' => 4,
                       'frame_window' => 7
                     },
          'total_black_frames' => 1,
          'pid' => 201
        };

my $new_expected_defaults = {
		%$new_defaults,
	
          'total_scene_frames' => 0,
          'total_size_frames' => 0,
          'total_logo_frames' => 0,
          'num_frames' => 1,
          'total_black_frames' => 0,
        };

	## Get defaults
	my $default_settings_href = Linux::DVB::DVBT::Advert::dvb_advert_def_settings() ;
	print  Data::Dumper->Dump(['Default settings', $default_settings_href]) ;
	is_deeply($default_settings_href, $expected_defaults) ;

	## Get defaults2
	my $default_settings_href2 = Linux::DVB::DVBT::Advert::dvb_advert_def_settings($new_defaults) ;
	print  Data::Dumper->Dump(['Default settings2', $default_settings_href2]) ;
	is_deeply($default_settings_href2, $new_expected_defaults) ;



