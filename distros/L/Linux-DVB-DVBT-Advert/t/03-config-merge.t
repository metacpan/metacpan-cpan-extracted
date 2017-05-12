#!perl
use strict ;

use Data::Dumper ;

use Test::More tests => 3;

## Check module loads ok
use Linux::DVB::DVBT::Advert qw/:all/ ;
use Linux::DVB::DVBT::Advert::Config ;
#use Linux::DVB::DVBT::Advert::Constants ;

$Linux::DVB::DVBT::Advert::Config::DEBUG =1;


my $expected_cfg1 = {
          'BBC1' => {
                      'detection_method' => 0
                    },
          'Dave' => {
                      'reduce_end' => 900,
                      'reduce_min_gap' => 50
                    },
          'BBC2' => {
                      'detection_method' => 0
                    },
          $Linux::DVB::DVBT::Advert::Config::ADVERT_GLOBAL_SECTION => {
                                                          'max_advert' => 1111,
                                                          'min_advert' => 11111,
                                                          'logo' => {
                                                                      'frame_window' => 111111
                                                                    },
                                                          'min_program' => 111111
                                                        },
          'Virgin1' => {
                         'detection_method' => 0
                       }
        };

my $expected_cfg2 = {
          'BBC1' => {
                      'detection_method' => 0
                    },
          'Dave' => {
                      'reduce_end' => 2222,
                      'reduce_min_gap' => 50
                    },
          'BBC2' => {
                      'detection_method' => 0
                    },
          $Linux::DVB::DVBT::Advert::Config::ADVERT_GLOBAL_SECTION => {
                                                          'max_advert' => 222,
                                                          'frame' => {
                                                                       'frame_window' => 2222
                                                                     },
                                                          'frame_window' => 22222
                                                        },
          'ITV3' => {
                         'detection_method' => 0,
                       },
        };

my $expected_cfg1_2 = {
          'BBC1' => {
                      'detection_method' => 0
                    },
          'Dave' => {
                      'reduce_end' => 2222,
                      'reduce_min_gap' => 50
                    },
          'BBC2' => {
                      'detection_method' => 0
                    },
          $Linux::DVB::DVBT::Advert::Config::ADVERT_GLOBAL_SECTION => {
                                                          'max_advert' => 222,
                                                          'min_advert' => 11111,
                                                          'logo' => {
                                                                      'frame_window' => 111111
                                                                    },
                                                          'min_program' => 111111,
                                                          'frame' => {
                                                                       'frame_window' => 2222
                                                                     },
                                                          'frame_window' => 22222
                                                        },
          'Virgin1' => {
                         'detection_method' => 0,
                       },

          'ITV3' => {
                         'detection_method' => 0,
                       },
        };





## Check config read
my $ad_config_href ;

$ad_config_href = ad_config(['./t/cfg1']) ;
print Data::Dumper->Dump(['./t/cfg1', $ad_config_href]) ;
is_deeply($ad_config_href, $expected_cfg1) ;

$ad_config_href = ad_config(['./t/cfg2']) ;
print Data::Dumper->Dump(['./t/cfg2', $ad_config_href]) ;
is_deeply($ad_config_href, $expected_cfg2) ;

Linux::DVB::DVBT::Advert::ad_config_search( ['./t/cfg1', './t/cfg2'] ) ;
$ad_config_href = ad_config() ;
print Data::Dumper->Dump(['./t/cfg1&2', $ad_config_href]) ;
is_deeply($ad_config_href, $expected_cfg1_2) ;

#
#my %expected_chan = (
#	%{ $expected_full{$Linux::DVB::DVBT::Advert::Config::ADVERT_GLOBAL_SECTION} },
#	'total_black_frames' => 0,
#	'total_scene_frames' => 0,
#	'total_logo_frames' => 0,
#	'total_size_frames' => 0,
#	'num_frames' => 1,
#	'audio_pid' => -1,
#	'pid' => -1,
#
#	# not used
#	'increase_start' => 0,
#	'increase_min_gap' => 1500,
#	) ;
#	
#$expected_chan{'frame'}{'remove_logo'} = 0 ;
#$expected_chan{'audio'}{'silence_threshold'} = -80 ;
#$expected_chan{'audio'}{'scale'} = 1 ;
#$expected_chan{'logo'}{'logo_window'} = 50 ;
#
#my $chan_href = channel_settings({}, 'Dave', $ad_config_href) ;
#print Data::Dumper->Dump(['Chan settings', $chan_href]) ;
#is_deeply($chan_href, \%expected_chan) ;
#

