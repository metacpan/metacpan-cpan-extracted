#!perl
use strict ;

use Data::Dumper ;

use Test::More tests => 10;

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

#print STDERR Data::Dumper->Dump(['lf [2]', $filter_aref->[2]]) ;
#exit 0 ;

	## ADA array
	is(scalar(@$frames_adata_aref), 100, 'Correct array size') ;

	# FETCH - ok
	# POP - no
	# PUSH - no
	# UNSHIFT - no
	# STORE - no
	# SPLICE - no
	# FETCHSIZE - OK
	# CLEAR - no
	# EXTEND - OK


	# PUSH
	eval {
		push @$frames_adata_aref, {} ;
	};
	ok($@, 'Unimplemented PUSH') ;



#print STDERR Data::Dumper->Dump(['frames [2]', $frames_adata_aref->[2]]) ;
	# *FETCH
	is_deeply($frames_adata_aref->[2], {
		%$expected2,

		'frame'	=> 2,
		'frame_end' => 2,
		
	}, 'FETCH [2]') ;


	# STORE
	eval {
		$frames_adata_aref->[2] = {} ;
	};

	# POP
	eval {
		pop @$frames_adata_aref ;
	};
	ok($@, 'Unimplemented POP') ;

	# UNSHIFT
	eval {
		unshift @$frames_adata_aref, {} ;
	};
	ok($@, 'Unimplemented UNSHIFT') ;

	
	# SPLICE
	eval {
		splice @$frames_adata_aref, 5 ;
	};
	ok($@, 'Unimplemented SPLICE') ;

	# EXISTS
	ok(exists($frames_adata_aref->[9]), 'frames array [9] exists') ;
	ok(!exists($frames_adata_aref->[100]), 'frames array [100] not exists') ;
	is($frames_adata_aref->[100], undef, 'FETCH [100]') ;
	
	# CLEAR
	eval {
		@$frames_adata_aref = () ;
	};
	ok($@, 'Unimplemented CLEAR') ;

	# EXTEND
	
	
__END__

