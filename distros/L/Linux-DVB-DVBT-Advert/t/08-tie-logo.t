#!perl
use strict ;

use Data::Dumper ;

use Test::More tests => 14;

use Linux::DVB::DVBT::Advert ;


#$Linux::DVB::DVBT::Advert::DEBUG = 10 ;

my $expected2 = {
          'scene_frame' => 0,
          'max_volume' => 5280,
          'volume_dB' => -34,
          'frame' => 2,
          'black_frame' => 0,
          'sceneChangePercent' => 23,
          'size_change' => 0,
          'silent_frame' => 0,
          'ave_percent' => 0,
          'audio_framenum' => 25,
          'sample_rate' => 48000,
          'screen_height' => 576,
          'channels' => 2,
          'volume' => 1362,
          'samples_per_frame' => 2304,
          'end_pkt' => 677,
          'dimCount' => 4,
          'logo_frame' => 0,
          'samples' => 2304,
          'gop_pkt' => 305,
          'frame_end' => 2,
          'brightness' => 46,
          'uniform' => 4010,
          'start_pkt' => 583,
          'match_percent' => 61,
          'framesize' => 1152,
          'screen_width' => 720,
          'pts' => {
                     'ts' => '0',
                     'secs' => 0,
                     'usecs' => 0
                   },
        };


	## read file
	my $results_href = detect_from_file('t/det/test-set.det', {}) ;

	my $frames_adata_aref = $results_href->{'frames'} ;

	my $filter_aref = Linux::DVB::DVBT::Advert::frames_list($results_href, '') ;
	my $csv_aref = Linux::DVB::DVBT::Advert::new_csv_frames($results_href) ;

	## Logo array
	my @lf ;
	my $thing = tied @$frames_adata_aref ;
	tie @lf, 'Linux::DVB::DVBT::Advert', 'LOGO', [$thing] ;
	my $logo_frames_adl_aref = \@lf ;

	# PUSH
	for (my $f=0; $f<10; ++$f)
	{
		push @$logo_frames_adl_aref, {'frame'=>$f, 'match_percent'=>$f*10, 'ave_percent'=>100-$f*10} ;
	}
	is(scalar(@$logo_frames_adl_aref), 10, 'PUSH') ;

	# FETCH
	is_deeply($lf[2], {
		%$expected2,

		'frame'	=> 2,
		'gap'	=> 0,
		'frame_end' => 0,
		'match_percent' => 20,
		'ave_percent' => 80,
		
	}, 'FETCH [2]') ;
#print STDERR Data::Dumper->Dump(['lf [2]', $lf[2]]) ;

	is($lf[10], undef, 'FETCH [10]') ;

	# STORE
	my $new = {
		'frame'	=> 2,
		'gap'	=> 0,
		'frame_end' => 888,
		'match_percent' => 23,
		'ave_percent' => 76,
		
	};
	$lf[2] = $new ;
	is_deeply($lf[2], {
		%$expected2,
		%$new,
	}, 'STORE [2]') ;


	# UNSHIFT
	unshift @$logo_frames_adl_aref, {'frame'=>99, 'match_percent'=>100, 'ave_percent'=>100} ;
	unshift @$logo_frames_adl_aref, {'frame'=>99, 'match_percent'=>100, 'ave_percent'=>100} ;
	unshift @$logo_frames_adl_aref, {'frame'=>99, 'match_percent'=>100, 'ave_percent'=>100} ;
	is(scalar(@$logo_frames_adl_aref), 13, 'UNSHIFT') ;

	# POP
	for (my $f=0; $f<10; ++$f)
	{
		pop @$logo_frames_adl_aref ;
	}
	is(scalar(@$logo_frames_adl_aref), 3) ;

	for (my $f=0; $f<3; ++$f)
	{
		pop @$logo_frames_adl_aref ;
	}
	is(scalar(@$logo_frames_adl_aref), 0) ;
	
	for (my $f=0; $f<10; ++$f)
	{
		pop @$logo_frames_adl_aref ;
	}
	is(scalar(@$logo_frames_adl_aref), 0, 'POP from empty array') ;

	# SPLICE
	splice @$logo_frames_adl_aref, 10 ;
	is(scalar(@$logo_frames_adl_aref), 0, 'SPLICE from empty array') ;

	for (my $f=0; $f<20; ++$f)
	{
		push @$logo_frames_adl_aref, {'frame'=>$f, 'match_percent'=>100, 'ave_percent'=>100} ;
	}
	splice @$logo_frames_adl_aref, 10 ;
	is(scalar(@$logo_frames_adl_aref), 10, 'SPLICE') ;
	
	# EXISTS
	ok(exists($lf[9]), 'logo array [9] exists') ;
	ok(!exists($lf[10]), 'logo array [10] not exists') ;
	
	# CLEAR
	@lf = () ;
	is(scalar(@$logo_frames_adl_aref), 0, 'CLEAR') ;

	# EXTEND
	for (my $f=0; $f<10; ++$f)
	{
		push @$logo_frames_adl_aref, {'frame'=>$f, 'match_percent'=>100, 'ave_percent'=>100} ;
	}
	is(scalar(@$logo_frames_adl_aref), 10, 'EXTEND') ;
	
	
	
		
