#!perl

use strict;
use warnings;
use Test::More ;

use Linux::DVB::DVBT ;
use Linux::DVB::DVBT::Config ;

##$Linux::DVB::DVBT::Config::DEBUG = 15 ;

#[4107-4171]
#video = 600
#lcn = 1
#tsid = 4107
#name = BBC ONE
#ca = 0
#net = BBC
#audio = 601
#teletext = 0
#subtitle = 605
#type = 1
#pmt = 4171
#audio_details = eng:601 eng:602 fra:9999 deu:9900
#subtitle_details = eng:705 eng:706 fra:707 deu:708

my %demux = (
	'600'	=> {
        audio => 601,
        audio_details => 'eng:601 eng:602 fra:9999 deu:9900',
        ca => 0,
        lcn => 1,
        name => 'BBC ONE',
        net => 'BBC',
        pmt => 4171,
        pnr => 4171,
        subtitle => 605,
        subtitle_details => 'eng:605 eng:706 fra:707 deu:708',
        teletext => 0,
        tsid => 4107,
        type => 1,
        video => 600,
	},

) ;
my @tests = (
	{
		'out'	=> "avs",
		'lang'	=> "",
		'sub_lang'	=> "",
		'audio_pids'	=> 
			[ 601,  ],
		'out_pids'	=> 
			[
				{
					'pid' => 601,
					'pidtype' => 'audio',
					'demux_params' => $demux{600},
				},
				{
					'pid' => 600,
					'pidtype' => 'video',
					'demux_params' => $demux{600},
				},
				{
					'pid' => 605,
					'pidtype' => 'subtitle',
					'demux_params' => $demux{600},
				},
			],
	},
	{
		'out'	=> "av",
		'lang'	=> "+eng",
		'sub_lang'	=> "",
		'audio_pids'	=> 
			[ 601, 602,  ],
		'out_pids'	=> 
			[
				{
					'pid' => 601,
					'pidtype' => 'audio',
					'demux_params' => $demux{600},
				},
				{
					'pid' => 602,
					'pidtype' => 'audio',
					'demux_params' => $demux{600},
				},
				{
					'pid' => 600,
					'pidtype' => 'video',
					'demux_params' => $demux{600},
				},
			],
	},
	{
		'out'	=> "a",
		'lang'	=> "eng",
		'sub_lang'	=> "",
		'audio_pids'	=> 
			[ 602,  ],
		'out_pids'	=> 
			[
				{
					'pid' => 602,
					'pidtype' => 'audio',
					'demux_params' => $demux{600},
				},
			],
	},
	{
		'out'	=> "",
		'lang'	=> "fra",
		'sub_lang'	=> "",
		'audio_pids'	=> 
			[ 9999,  ],
		'out_pids'	=> 
			[
				{
					'pid' => 9999,
					'pidtype' => 'audio',
					'demux_params' => $demux{600},
				},
				{
					'pid' => 600,
					'pidtype' => 'video',
					'demux_params' => $demux{600},
				},
			],
	},
	{
		'out'	=> "a",
		'lang'	=> "eng eng",
		'sub_lang'	=> "",
		'error'	=> 1,
		'audio_pids'	=> 
			[ 602,  ],
		'out_pids'	=> 
			[
			],
	},
	{
		'out'	=> "",
		'lang'	=> "ita",
		'sub_lang'	=> "",
		'error'	=> 1,
		'audio_pids'	=> 
			[  ],
		'out_pids'	=> 
			[
			],
	},
	{
		'out'	=> "",
		'lang'	=> "fra eng",
		'sub_lang'	=> "",
		'error'	=> 1,
		'audio_pids'	=> 
			[ 9999,  ],
		'out_pids'	=> 
			[
			],
	},
	{
		'out'	=> "",
		'lang'	=> "fra eng deu",
		'sub_lang'	=> "",
		'error'	=> 1,
		'audio_pids'	=> 
			[ 9999, ],
		'out_pids'	=> 
			[
			],
	},

	{
		'out'	=> "avs",
		'lang'	=> "",
		'sub_lang'	=> "fra deu",
		'audio_pids'	=> 
			[ 601,  ],
		'out_pids'	=> 
			[
				{
					'pid' => 601,
					'pidtype' => 'audio',
					'demux_params' => $demux{600},
				},
				{
					'pid' => 600,
					'pidtype' => 'video',
					'demux_params' => $demux{600},
				},
				{
					'pid' => 707,
					'pidtype' => 'subtitle',
					'demux_params' => $demux{600},
				},
				{
					'pid' => 708,
					'pidtype' => 'subtitle',
					'demux_params' => $demux{600},
				},
			],
	},
);

plan tests => scalar(@tests) * 2 * 2 ;

	## Create object
	my $dvb = Linux::DVB::DVBT->new(
		'dvb' => 1,		# special case to allow for testing
		
		'adapter_num'	=> 1,
		'frontend_num'	=> 0,
		
		'frontend_name'	=> '/dev/dvb/adapter1/frontend0',
		'demux_name'	=> '/dev/dvb/adapter1/demux0',
		'dvr_name'	=> '/dev/dvb/adapter1/dvr0',
		
	) ;
	
	$dvb->config_path('./t/config-ox') ;
	my $tuning_href = $dvb->get_tuning_info() ;
	
	my $out  ;
	my $lang ;
	my $channel_name = "bbc1" ;

	# find channel
	my ($frontend_params_href, $demux_params_href) = Linux::DVB::DVBT::Config::find_channel($channel_name, $tuning_href) ;
	if (! $frontend_params_href)
	{
		die "unable to find $channel_name" ;
	}

	foreach my $href (@tests)
	{
		test_audio($demux_params_href, $href->{'lang'}, $href->{'audio_pids'}, $href->{'error'}||0) ;
		test_out($demux_params_href, $href->{'out'}, $href->{'lang'}, $href->{'sub_lang'}||"", $href->{'out_pids'}, $href->{'error'}||0) ;
	}
	exit 0 ;

#------------------------------------------------------------------------------------------------
sub test_audio
{
	my ($demux_params_href, $lang, $expected_aref, $expect_error) = @_ ;

	my @pids ;
	my $error ; 

	$error = Linux::DVB::DVBT::Config::audio_pids($demux_params_href, $lang, \@pids) ;
	is_deeply(\@pids, $expected_aref, "Audio pids lang=\"$lang\" ") ;
	is( $error?1:0, $expect_error, "Audio error lang=\"$lang\" ") ;

}
	
#------------------------------------------------------------------------------------------------
sub test_out
{
	my ($demux_params_href, $out, $lang, $sub_lang, $expected_aref, $expect_error) = @_ ;

	my @pids ;
	my $error ; 
	
	$error = Linux::DVB::DVBT::Config::out_pids($demux_params_href, $out, $lang, $sub_lang, \@pids) ;
	is_deeply(\@pids, $expected_aref, "Output spec pids lang=\"$lang\" out=\"$out\"") ;
	is( $error?1:0, $expect_error, "Output spec error lang=\"$lang\" out=\"$out\" ") ;
}
	
__END__
lang="" pids=
[ # ARRAY(0x849d394)
  601  # [0x259]
],
lang="" out="avs" pids=
[ # ARRAY(0x846e5fc)
  { # HASH(0x84f4e8c)
    demux_params => 
      { # HASH(0x84f4aec)
        audio => 601,
        audio_details => eng:601 eng:602 fra:9999 deu:9900,
        ca => 0,
        lcn => 1,
        name => BBC ONE,
        net => BBC,
        pmt => 4171,
        pnr => 4171,
        subtitle => 605,
        teletext => 0,
        tsid => 4107,
        type => 1,
        video => 600,
      },
    pid => 601,
    pidtype => audio,
  },
  { # HASH(0x84f4adc)
    demux_params => 
    # HASH(0x84f4aec) (Seen earlier)
    pid => 600,
    pidtype => video,
  },
  { # HASH(0x85502e4)
    demux_params => 
    # HASH(0x84f4aec) (Seen earlier)
    pid => 605,
    pidtype => subtitle,
  },
],
lang="+eng" pids=
[ # ARRAY(0x849d394)
  601  # [0x259]
  602  # [0x25a]
],
lang="+eng" out="av" pids=
[ # ARRAY(0x846e5fc)
  { # HASH(0x8555a54)
    demux_params => 
      { # HASH(0x84f4aec)
        audio => 601,
        audio_details => eng:601 eng:602 fra:9999 deu:9900,
        ca => 0,
        lcn => 1,
        name => BBC ONE,
        net => BBC,
        pmt => 4171,
        pnr => 4171,
        subtitle => 605,
        teletext => 0,
        tsid => 4107,
        type => 1,
        video => 600,
      },
    pid => 601,
    pidtype => audio,
  },
  { # HASH(0x85502e4)
    demux_params => 
    # HASH(0x84f4aec) (Seen earlier)
    pid => 602,
    pidtype => audio,
  },
  { # HASH(0x84f4adc)
    demux_params => 
    # HASH(0x84f4aec) (Seen earlier)
    pid => 600,
    pidtype => video,
  },
],
lang="eng" pids=
[ # ARRAY(0x849d394)
  602  # [0x25a]
],
lang="eng" out="a" pids=
[ # ARRAY(0x846e5fc)
  { # HASH(0x8550a44)
    demux_params => 
      { # HASH(0x84f4aec)
        audio => 601,
        audio_details => eng:601 eng:602 fra:9999 deu:9900,
        ca => 0,
        lcn => 1,
        name => BBC ONE,
        net => BBC,
        pmt => 4171,
        pnr => 4171,
        subtitle => 605,
        teletext => 0,
        tsid => 4107,
        type => 1,
        video => 600,
      },
    pid => 602,
    pidtype => audio,
  },
],
lang="fra" pids=
[ # ARRAY(0x849d394)
  9999  # [0x270f]
],
lang="fra" out="" pids=
[ # ARRAY(0x846e5fc)
  { # HASH(0x855af74)
    demux_params => 
      { # HASH(0x84f4aec)
        audio => 601,
        audio_details => eng:601 eng:602 fra:9999 deu:9900,
        ca => 0,
        lcn => 1,
        name => BBC ONE,
        net => BBC,
        pmt => 4171,
        pnr => 4171,
        subtitle => 605,
        teletext => 0,
        tsid => 4107,
        type => 1,
        video => 600,
      },
    pid => 9999,
    pidtype => audio,
  },
  { # HASH(0x855aac4)
    demux_params => 
    # HASH(0x84f4aec) (Seen earlier)
    pid => 600,
    pidtype => video,
  },
],
lang="eng eng" pids=
[ # ARRAY(0x849d394)
  602  # [0x25a]
],
lang="eng eng" out="a" pids=
[ # ARRAY(0x846e5fc)
],
lang="ita" pids=
[ # ARRAY(0x849d394)
],
lang="ita" out="" pids=
[ # ARRAY(0x846e5fc)
],
lang="fra eng" pids=
[ # ARRAY(0x849d394)
  9999  # [0x270f]
],
lang="fra eng" out="" pids=
[ # ARRAY(0x846e5fc)
],
lang="fra eng deu" pids=
[ # ARRAY(0x849d394)
  9999  # [0x270f]
],
lang="fra eng deu" out="" pids=
[ # ARRAY(0x846e5fc)
],
Test Audio: lang=""
Test Out: lang="" out="avs"
Test Audio: lang="+eng"
Test Out: lang="+eng" out="av"
Test Audio: lang="eng"
Test Out: lang="eng" out="a"
Test Audio: lang="fra"
Test Out: lang="fra" out=""
Test Audio: lang="eng eng"
Error: Error: could not find the languages: eng associated with program "4171"
Test Out: lang="eng eng" out="a"
Error: Error: could not find the languages: eng associated with program "4171"
Test Audio: lang="ita"
Error: Error: could not find the languages: ita associated with program "4171"
Test Out: lang="ita" out=""
Error: Error: could not find the languages: ita associated with program "4171"
Test Audio: lang="fra eng"
Error: Error: could not find the languages: eng associated with program "4171"
Test Out: lang="fra eng" out=""
Error: Error: could not find the languages: eng associated with program "4171"
Test Audio: lang="fra eng deu"
Error: Error: could not find the languages: eng, deu associated with program "4171"
Test Out: lang="fra eng deu" out=""
Error: Error: could not find the languages: eng, deu associated with program "4171"
