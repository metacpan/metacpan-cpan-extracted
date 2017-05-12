#!perl
use strict ;

use Data::Dumper ;

use Test::More tests => 13;

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

#print STDERR Data::Dumper->Dump(['lf [2]', $filter_aref->[2]]) ;
#exit 0 ;

	## Filter array
	is(scalar(@$filter_aref), 100) ;

	# PUSH
	eval {
		push @$filter_aref, {} ;
	};
	ok($@, 'Unimplemented PUSH') ;
	
	# *FETCH
	is_deeply($filter_aref->[2], {
		%$expected2,

		'frame'	=> 2,
		'gap'	=> 0,
		'frame_end' => 2,
		
	}, 'FETCH [2]') ;
#print STDERR Data::Dumper->Dump(['lf [2]', $lf[2]]) ;


	# STORE
	eval {
		$filter_aref->[5] = {} ;
	};
	ok($@, 'Unimplemented STORE') ;

	# *POP
	for (my $f=0; $f<90; ++$f)
	{
		pop @$filter_aref ;
	}
	is(scalar(@$filter_aref), 10) ;

	# UNSHIFT
	eval {
		unshift @$filter_aref, {} ;
	};
	ok($@, 'Unimplemented UNSHIFT') ;

	
	# SPLICE
	eval {
		splice @$filter_aref, 5 ;
	};
	ok($@, 'Unimplemented SPLICE') ;

	# EXISTS
	ok(exists($filter_aref->[9]), 'filter array [9] exists') ;
	ok(!exists($filter_aref->[10]), 'filter array [10] not exists') ;
	is($filter_aref->[10], undef, 'FETCH [10]') ;
	
	for (my $f=0; $f<10; ++$f)
	{
		pop @$filter_aref ;
	}
	is(scalar(@$filter_aref), 0) ;
	
	for (my $f=0; $f<3; ++$f)
	{
		pop @$filter_aref ;
	}
	is(scalar(@$filter_aref), 0, 'POP from empty array') ;

	# CLEAR
	@$filter_aref = () ;
	is(scalar(@$filter_aref), 0, 'CLEAR') ;

	# EXTEND
	
	
__END__

