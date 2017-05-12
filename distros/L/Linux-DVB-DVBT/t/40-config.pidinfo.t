#!perl

use strict;
use warnings;
use Test::More ;

use Linux::DVB::DVBT ;
use Linux::DVB::DVBT::Config ;

my $DEBUG=0 ;
$Linux::DVB::DVBT::Config::DEBUG = $DEBUG ;

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

Linux::DVB::DVBT::prt_data("Tuning = ", $tuning_href) if $DEBUG>=10 ;
	
	my $pid ;

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
#audio_details = eng:601 eng:602 fra:9999
#
#[12290-14272]
#video = 6273
#tsid = 12290
#lcn = 23
#name = bid tv
#ca = 0
#net = Sit-Up Ltd
#audio = 6274
#teletext = 8888
#subtitle = 0
#type = 1
#pmt = 14272
#audio_details = eng:6274 fra:9999 deu:9900

my %demux = (
	'ITV2+1'	=> {
				'video'	=> '600',
				'tsid'	=> '8199',
				'lcn'	=> '33',
				'name'	=> 'ITV2 +1',
				'ca'	=> '0',
				'net'	=> 'ITV',
				'audio'	=> '601',
				'teletext'	=> '0',
				'subtitle'	=> '603',
				'type'	=> 'video',
				'pnr'	=> '8362',
				'pmt'	=> '290',
				'type'	=> '1',
				'audio_details'	=> 'eng:601 eng:602',
	},
	'BBC ONE'	=> {
				'video'	=> '600',
				'tsid'	=> '4107',
				'lcn'	=> '1',
				'name'	=> 'BBC ONE',
				'ca'	=> '0',
				'net'	=> 'BBC',
				'audio'	=> '601',
				'teletext'	=> '0',
				'subtitle'	=> '605',
				'type'	=> 'video',
				'pnr'	=> '4171',
				'pmt'	=> '4171',
				'type'	=> '1',
				'audio_details'	=> 'eng:601 eng:602 fra:9999 deu:9900',
				'subtitle_details' => 'eng:605 eng:706 fra:707 deu:708',
	},
	'ITV4'		=> {
				'video'	=> '601',
				'tsid'	=> '24576',
				'lcn'	=> '24',
				'name'	=> 'ITV4',
				'ca'	=> '0',
				'net'	=> 'ITV',
				'audio'	=> '602',
				'teletext'	=> '0',
				'subtitle'	=> '603',
				'type'	=> 'video',
				'pnr'	=> '28032',
				'pmt'	=> '1037',
				'type'	=> '1',
				'audio_details'	=> 'eng:602 eng:604',
	},
	'CBeebies'	=> {
				'video'	=> '201',
				'tsid'	=> '16384',
				'lcn'	=> '71',
				'name'	=> 'CBeebies',
				'ca'	=> '0',
				'net'	=> 'BBC',
				'audio'	=> '401',
				'teletext'	=> '0',
				'subtitle'	=> '601',
				'type'	=> 'subtitle',
				'pnr'	=> '16960',
				'pmt'	=> '703',
				'type'	=> '1',
				'audio_details'	=> 'eng:401 eng:402',
	},
	'BBC Parliament'	=> {
				'video'	=> '205',
				'tsid'	=> '16384',
				'lcn'	=> '81',
				'name'	=> 'BBC Parliament',
				'ca'	=> '0',
				'net'	=> 'BBC',
				'audio'	=> '421',
				'teletext'	=> '0',
				'subtitle'	=> '605',
				'type'	=> 'subtitle',
				'pnr'	=> '17024',
				'pmt'	=> '714',
				'type'	=> '1',
				'audio_details'	=> 'eng:421',
	},
	'Community'	=> {
				'video'	=> '204',
				'tsid'	=> '16384',
				'lcn'	=> '87',
				'name'	=> 'Community',
				'ca'	=> '0',
				'net'	=> 'BBC',
				'audio'	=> '411',
				'teletext'	=> '0',
				'subtitle'	=> '602',
				'type'	=> 'subtitle',
				'pnr'	=> '19968',
				'pmt'	=> '713',
				'type'	=> '1',
				'audio_details'	=> 'eng:411 eng:415',
	},
	'bid tv'	=> {
				'video'	=> '6273',
				'tsid'	=> '12290',
				'lcn'	=> '23',
				'name'	=> 'bid tv',
				'ca'	=> '0',
				'net'	=> 'Sit-Up Ltd',
				'audio'	=> '6274',
				'teletext'	=> '8888',
				'subtitle'	=> '0',
				'type'	=> 'video',
				'pnr'	=> '14272',
				'pmt'	=> '261',
				'type'	=> '1',
				'audio_details'	=> 'eng:6274 fra:9999',
	},
);

my @tests = (
	{
		'pid'	=> 600,
		'pids'	=> [
			{
				%{$demux{'ITV2+1'}},
				'pidtype' => 'video',
				'demux_params'	=> $demux{'ITV2+1'},
			},
			{
				%{$demux{'BBC ONE'}},
				'pidtype' => 'video',
				'demux_params'	=> $demux{'BBC ONE'},
			},
		],
	},
	{
		'pid'	=> 601,
		'pids'	=> [
			{
				%{$demux{'ITV4'}},
				'pidtype' => 'video',
				'demux_params'	=> $demux{'ITV4'},
			},
			{
				%{$demux{'CBeebies'}},
				'pidtype' => 'subtitle',
				'demux_params'	=> $demux{'CBeebies'},
			},
			{
				%{$demux{'ITV2+1'}},
				'pidtype' => 'audio',
				'demux_params'	=> $demux{'ITV2+1'},
			},
			{
				%{$demux{'BBC ONE'}},
				'pidtype' => 'audio',
				'demux_params'	=> $demux{'BBC ONE'},
			},
		],
	},
	{
		'pid'	=> 605,
		'pids'	=> [
			{
				%{$demux{'BBC ONE'}},
				'pidtype' => 'subtitle',
				'demux_params'	=> $demux{'BBC ONE'},
			},
			{
				%{$demux{'BBC Parliament'}},
				'pidtype' => 'subtitle',
				'demux_params'	=> $demux{'BBC Parliament'},
			},
		],
	},
	{
		'pid'	=> 602,
		'pids'	=> [
			{
				%{$demux{'ITV4'}},
				'pidtype' => 'audio',
				'demux_params'	=> $demux{'ITV4'},
			},
			{
				%{$demux{'Community'}},
				'pidtype' => 'subtitle',
				'demux_params'	=> $demux{'Community'},
			},
			{
				%{$demux{'ITV2+1'}},
				'pidtype' => 'audio',
				'demux_params'	=> $demux{'ITV2+1'},
			},
			{
				%{$demux{'BBC ONE'}},
				'pidtype' => 'audio',
				'demux_params'	=> $demux{'BBC ONE'},
			},
		],
	},
	{
		'pid'	=> 6273,
		'pids'	=> [
			{
				%{$demux{'bid tv'}},
				'pidtype' => 'video',
				'demux_params'	=> $demux{'bid tv'},
			},
		],
	},
	{
		'pid'	=> 8888,
		'pids'	=> [
			{
				%{$demux{'bid tv'}},
				'pidtype' => 'teletext',
				'demux_params'	=> $demux{'bid tv'},
			},
		],
	},
	{
		'pid'	=> 9999,
		'pids'	=> [
			{
				%{$demux{'bid tv'}},
				'pidtype' => 'audio',
				'demux_params'	=> $demux{'bid tv'},
			},
			{
				%{$demux{'BBC ONE'}},
				'pidtype' => 'audio',
				'demux_params'	=> $demux{'BBC ONE'},
			},
		],
	},
);

plan tests => scalar(@tests) ;
	
	foreach my $test_href (@tests)
	{
		test_pid($tuning_href, $test_href->{'pid'}, $test_href->{'pids'}) ;
	}

	exit 0 ;

#------------------------------------------------------------------------------------------------
sub test_pid
{
	my ($tuning_href, $pid, $expected_aref) = @_ ;

	my @pid_info = Linux::DVB::DVBT::Config::pid_info($pid, $tuning_href) ;
	
#	is_deeply(\@pid_info, $expected_aref, "PID $pid info") ;

#Linux::DVB::DVBT::prt_data("------------\nPID = ", $pid) ;
#Linux::DVB::DVBT::prt_data("expected_aref = ", $expected_aref) ;
#Linux::DVB::DVBT::prt_data("pid_info = ", \@pid_info) ;

	## Have to manually work through the results after the HASH randomisation of Perl 5.18
	foreach my $href (@$expected_aref)
	{
		my $name = $href->{'name'} ;
		
		# Find it in the results
		my $pid_href ;
		foreach my $phref (@pid_info)
		{
			if ($phref->{'name'} eq $name)
			{
				$pid_href = $phref ;
				last ;
			}
		}
		
		if (!defined($pid_href))
		{
			fail("pid$pid") ;
			return ;
		}
		
		if ($href->{'pidtype'} ne $pid_href->{'pidtype'})
		{
			fail("pid$pid") ;
			return ;
		}
		
		foreach my $param (keys %{$href->{'demux_params'}})
		{
			if ($href->{'demux_params'}{$param} ne $pid_href->{'demux_params'}{$param})
			{
				fail("pid$pid") ;
				return ;
			}
		}
	}

	pass("pid$pid") ;

}
	
	
__END__

my @tests = (
	{
		'pid'	=> 600,
		'pids'	=> [
			{
				'pidtype'	=> 'video',
				'video'	=> '600',
				'demux_params'	=> 'HASH(0x8554e74)',
{ # HASH(0x8554e74)
  audio => 601,
  audio_details => eng:601 eng:602,
  ca => 0,
  lcn => 33,
  name => ITV2 +1,
  net => ITV,
  pmt => 290,
  pnr => 8362,
  subtitle => 603,
  teletext => 0,
  tsid => 8199,
  type => 1,
  video => 600,
},
				'tsid'	=> '8199',
				'lcn'	=> '33',
				'pmt'	=> '290',
				'name'	=> 'ITV2 +1',
				'ca'	=> '0',
				'net'	=> 'ITV',
				'audio'	=> '601',
				'subtitle'	=> '603',
				'teletext'	=> '0',
				'type'	=> '1',
				'pnr'	=> '8362',
				'audio_details'	=> 'eng:601 eng:602',
			},
			{
				'pidtype'	=> 'video',
				'video'	=> '600',
				'demux_params'	=> 'HASH(0x84f41dc)',
{ # HASH(0x84f41dc)
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
				'tsid'	=> '4107',
				'lcn'	=> '1',
				'name'	=> 'BBC ONE',
				'pmt'	=> '4171',
				'ca'	=> '0',
				'net'	=> 'BBC',
				'audio'	=> '601',
				'subtitle'	=> '605',
				'teletext'	=> '0',
				'type'	=> '1',
				'pnr'	=> '4171',
				'audio_details'	=> 'eng:601 eng:602 fra:9999 deu:9900',
			},
		],
	},
	{
		'pid'	=> 601,
		'pids'	=> [
			{
				'pidtype'	=> 'video',
				'video'	=> '601',
				'demux_params'	=> 'HASH(0x84f467c)',
{ # HASH(0x84f467c)
  audio => 602,
  audio_details => eng:602 eng:604,
  ca => 0,
  lcn => 24,
  name => ITV4,
  net => ITV,
  pmt => 1037,
  pnr => 28032,
  subtitle => 603,
  teletext => 0,
  tsid => 24576,
  type => 1,
  video => 601,
},
				'tsid'	=> '24576',
				'lcn'	=> '24',
				'pmt'	=> '1037',
				'name'	=> 'ITV4',
				'ca'	=> '0',
				'net'	=> 'ITV',
				'audio'	=> '602',
				'subtitle'	=> '603',
				'teletext'	=> '0',
				'type'	=> '1',
				'pnr'	=> '28032',
				'audio_details'	=> 'eng:602 eng:604',
			},
			{
				'pidtype'	=> 'subtitle',
				'video'	=> '201',
				'demux_params'	=> 'HASH(0x854ee64)',
{ # HASH(0x854ee64)
  audio => 401,
  audio_details => eng:401 eng:402,
  ca => 0,
  lcn => 71,
  name => CBeebies,
  net => BBC,
  pmt => 703,
  pnr => 16960,
  subtitle => 601,
  teletext => 0,
  tsid => 16384,
  type => 1,
  video => 201,
},
				'tsid'	=> '16384',
				'lcn'	=> '71',
				'pmt'	=> '703',
				'name'	=> 'CBeebies',
				'ca'	=> '0',
				'net'	=> 'BBC',
				'audio'	=> '401',
				'subtitle'	=> '601',
				'teletext'	=> '0',
				'type'	=> '1',
				'pnr'	=> '16960',
				'audio_details'	=> 'eng:401 eng:402',
			},
			{
				'pidtype'	=> 'audio',
				'video'	=> '600',
				'demux_params'	=> 'HASH(0x8554e74)',
{ # HASH(0x8554e74)
  audio => 601,
  audio_details => eng:601 eng:602,
  ca => 0,
  lcn => 33,
  name => ITV2 +1,
  net => ITV,
  pmt => 290,
  pnr => 8362,
  subtitle => 603,
  teletext => 0,
  tsid => 8199,
  type => 1,
  video => 600,
},
				'tsid'	=> '8199',
				'lcn'	=> '33',
				'pmt'	=> '290',
				'name'	=> 'ITV2 +1',
				'ca'	=> '0',
				'net'	=> 'ITV',
				'audio'	=> '601',
				'subtitle'	=> '603',
				'teletext'	=> '0',
				'type'	=> '1',
				'pnr'	=> '8362',
				'audio_details'	=> 'eng:601 eng:602',
			},
			{
				'pidtype'	=> 'audio',
				'video'	=> '600',
				'demux_params'	=> 'HASH(0x84f41dc)',
{ # HASH(0x84f41dc)
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
				'tsid'	=> '4107',
				'lcn'	=> '1',
				'name'	=> 'BBC ONE',
				'pmt'	=> '4171',
				'ca'	=> '0',
				'net'	=> 'BBC',
				'audio'	=> '601',
				'subtitle'	=> '605',
				'teletext'	=> '0',
				'type'	=> '1',
				'pnr'	=> '4171',
				'audio_details'	=> 'eng:601 eng:602 fra:9999 deu:9900',
			},
		],
	},
	{
		'pid'	=> 605,
		'pids'	=> [
			{
				'pidtype'	=> 'subtitle',
				'video'	=> '600',
				'demux_params'	=> 'HASH(0x84f41dc)',
{ # HASH(0x84f41dc)
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
				'tsid'	=> '4107',
				'lcn'	=> '1',
				'name'	=> 'BBC ONE',
				'pmt'	=> '4171',
				'ca'	=> '0',
				'net'	=> 'BBC',
				'audio'	=> '601',
				'subtitle'	=> '605',
				'teletext'	=> '0',
				'type'	=> '1',
				'pnr'	=> '4171',
				'audio_details'	=> 'eng:601 eng:602 fra:9999 deu:9900',
			},
			{
				'pidtype'	=> 'subtitle',
				'video'	=> '205',
				'demux_params'	=> 'HASH(0x8555994)',
{ # HASH(0x8555994)
  audio => 421,
  audio_details => eng:421,
  ca => 0,
  lcn => 81,
  name => BBC Parliament,
  net => BBC,
  pmt => 714,
  pnr => 17024,
  subtitle => 605,
  teletext => 0,
  tsid => 16384,
  type => 1,
  video => 205,
},
				'tsid'	=> '16384',
				'lcn'	=> '81',
				'pmt'	=> '714',
				'name'	=> 'BBC Parliament',
				'ca'	=> '0',
				'net'	=> 'BBC',
				'audio'	=> '421',
				'subtitle'	=> '605',
				'teletext'	=> '0',
				'type'	=> '1',
				'pnr'	=> '17024',
				'audio_details'	=> 'eng:421',
			},
		],
	},
	{
		'pid'	=> 602,
		'pids'	=> [
			{
				'pidtype'	=> 'audio',
				'video'	=> '601',
				'demux_params'	=> 'HASH(0x84f467c)',
{ # HASH(0x84f467c)
  audio => 602,
  audio_details => eng:602 eng:604,
  ca => 0,
  lcn => 24,
  name => ITV4,
  net => ITV,
  pmt => 1037,
  pnr => 28032,
  subtitle => 603,
  teletext => 0,
  tsid => 24576,
  type => 1,
  video => 601,
},
				'tsid'	=> '24576',
				'lcn'	=> '24',
				'pmt'	=> '1037',
				'name'	=> 'ITV4',
				'ca'	=> '0',
				'net'	=> 'ITV',
				'audio'	=> '602',
				'subtitle'	=> '603',
				'teletext'	=> '0',
				'type'	=> '1',
				'pnr'	=> '28032',
				'audio_details'	=> 'eng:602 eng:604',
			},
			{
				'pidtype'	=> 'subtitle',
				'video'	=> '204',
				'demux_params'	=> 'HASH(0x854f5c4)',
{ # HASH(0x854f5c4)
  audio => 411,
  audio_details => eng:411 eng:415,
  ca => 0,
  lcn => 87,
  name => Community,
  net => BBC,
  pmt => 713,
  pnr => 19968,
  subtitle => 602,
  teletext => 0,
  tsid => 16384,
  type => 1,
  video => 204,
},
				'tsid'	=> '16384',
				'lcn'	=> '87',
				'pmt'	=> '713',
				'name'	=> 'Community',
				'ca'	=> '0',
				'net'	=> 'BBC',
				'audio'	=> '411',
				'subtitle'	=> '602',
				'teletext'	=> '0',
				'type'	=> '1',
				'pnr'	=> '19968',
				'audio_details'	=> 'eng:411 eng:415',
			},
			{
				'pidtype'	=> 'audio',
				'video'	=> '600',
				'demux_params'	=> 'HASH(0x8554e74)',
{ # HASH(0x8554e74)
  audio => 601,
  audio_details => eng:601 eng:602,
  ca => 0,
  lcn => 33,
  name => ITV2 +1,
  net => ITV,
  pmt => 290,
  pnr => 8362,
  subtitle => 603,
  teletext => 0,
  tsid => 8199,
  type => 1,
  video => 600,
},
				'tsid'	=> '8199',
				'lcn'	=> '33',
				'pmt'	=> '290',
				'name'	=> 'ITV2 +1',
				'ca'	=> '0',
				'net'	=> 'ITV',
				'audio'	=> '601',
				'subtitle'	=> '603',
				'teletext'	=> '0',
				'type'	=> '1',
				'pnr'	=> '8362',
				'audio_details'	=> 'eng:601 eng:602',
			},
			{
				'pidtype'	=> 'audio',
				'video'	=> '600',
				'demux_params'	=> 'HASH(0x84f41dc)',
{ # HASH(0x84f41dc)
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
				'tsid'	=> '4107',
				'lcn'	=> '1',
				'name'	=> 'BBC ONE',
				'pmt'	=> '4171',
				'ca'	=> '0',
				'net'	=> 'BBC',
				'audio'	=> '601',
				'subtitle'	=> '605',
				'teletext'	=> '0',
				'type'	=> '1',
				'pnr'	=> '4171',
				'audio_details'	=> 'eng:601 eng:602 fra:9999 deu:9900',
			},
		],
	},
	{
		'pid'	=> 6273,
		'pids'	=> [
			{
				'pidtype'	=> 'video',
				'video'	=> '6273',
				'demux_params'	=> 'HASH(0x84f43bc)',
{ # HASH(0x84f43bc)
  audio => 6274,
  audio_details => eng:6274 fra:9999,
  ca => 0,
  lcn => 23,
  name => bid tv,
  net => Sit-Up Ltd,
  pmt => 261,
  pnr => 14272,
  subtitle => 0,
  teletext => 8888,
  tsid => 12290,
  type => 1,
  video => 6273,
},
				'tsid'	=> '12290',
				'lcn'	=> '23',
				'pmt'	=> '261',
				'name'	=> 'bid tv',
				'ca'	=> '0',
				'net'	=> 'Sit-Up Ltd',
				'audio'	=> '6274',
				'subtitle'	=> '0',
				'teletext'	=> '8888',
				'type'	=> '1',
				'pnr'	=> '14272',
				'audio_details'	=> 'eng:6274 fra:9999',
			},
		],
	},
	{
		'pid'	=> 8888,
		'pids'	=> [
			{
				'pidtype'	=> 'teletext',
				'video'	=> '6273',
				'demux_params'	=> 'HASH(0x84f43bc)',
{ # HASH(0x84f43bc)
  audio => 6274,
  audio_details => eng:6274 fra:9999,
  ca => 0,
  lcn => 23,
  name => bid tv,
  net => Sit-Up Ltd,
  pmt => 261,
  pnr => 14272,
  subtitle => 0,
  teletext => 8888,
  tsid => 12290,
  type => 1,
  video => 6273,
},
				'tsid'	=> '12290',
				'lcn'	=> '23',
				'pmt'	=> '261',
				'name'	=> 'bid tv',
				'ca'	=> '0',
				'net'	=> 'Sit-Up Ltd',
				'audio'	=> '6274',
				'subtitle'	=> '0',
				'teletext'	=> '8888',
				'type'	=> '1',
				'pnr'	=> '14272',
				'audio_details'	=> 'eng:6274 fra:9999',
			},
		],
	},
	{
		'pid'	=> 9999,
		'pids'	=> [
			{
				'pidtype'	=> 'audio',
				'video'	=> '6273',
				'demux_params'	=> 'HASH(0x84f43bc)',
{ # HASH(0x84f43bc)
  audio => 6274,
  audio_details => eng:6274 fra:9999,
  ca => 0,
  lcn => 23,
  name => bid tv,
  net => Sit-Up Ltd,
  pmt => 261,
  pnr => 14272,
  subtitle => 0,
  teletext => 8888,
  tsid => 12290,
  type => 1,
  video => 6273,
},
				'tsid'	=> '12290',
				'lcn'	=> '23',
				'pmt'	=> '261',
				'name'	=> 'bid tv',
				'ca'	=> '0',
				'net'	=> 'Sit-Up Ltd',
				'audio'	=> '6274',
				'subtitle'	=> '0',
				'teletext'	=> '8888',
				'type'	=> '1',
				'pnr'	=> '14272',
				'audio_details'	=> 'eng:6274 fra:9999',
			},
			{
				'pidtype'	=> 'audio',
				'video'	=> '600',
				'demux_params'	=> 'HASH(0x84f41dc)',
{ # HASH(0x84f41dc)
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
				'tsid'	=> '4107',
				'lcn'	=> '1',
				'name'	=> 'BBC ONE',
				'pmt'	=> '4171',
				'ca'	=> '0',
				'net'	=> 'BBC',
				'audio'	=> '601',
				'subtitle'	=> '605',
				'teletext'	=> '0',
				'type'	=> '1',
				'pnr'	=> '4171',
				'audio_details'	=> 'eng:601 eng:602 fra:9999 deu:9900',
			},
		],
	},
);
