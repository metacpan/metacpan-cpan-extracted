#!perl

use strict;
use warnings;
use Test::More ;


use Linux::DVB::DVBT ;
use Linux::DVB::DVBT::Config ;

	## Create object
	my $dvb = Linux::DVB::DVBT->new(
		'dvb' => 1,		# special case to allow for testing
		
		'adapter_num'	=> 1,
		'frontend_num'	=> 0,
		
		'frontend_name'	=> '/dev/dvb/adapter1/frontend0',
		'demux_name'	=> '/dev/dvb/adapter1/demux0',
		'dvr_name'	=> '/dev/dvb/adapter1/dvr0',
		
		'errmode' => 'message',
	) ;
	
	$dvb->config_path('./t/config-ox') ;

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
#pnr = 4171
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
#pnr = 14272
#audio_details = eng:6274 fra:9999

	
my @tests = (
	{
		'args'	=> [ 'file=nmnmnm', 'chan=bbc1', 'duration=0:30', 'offset=0:10', 'lang=eng', 'out=audio,video', ],
		'chan_spec'	=> [
			{
				'chans' => [
			        { # HASH(0x84be324)
			          chan => 'bbc1',
			          lang => 'eng',
			          out => 'audio,video',
			        },
				],
				'file' => 'nmnmnm',
				'duration' => '0:30',
				'pids' => [
				],
				'offset' => '0:10',
			},
		],
	},
	{
		'args'	=> [ 'f=nmnmnm', 'ch=bbc1', 'len=1:30', 'off=0:10', 'output=avs', 'ch=itv1', 'len=0:30', 'off=0:30', ],
		'chan_spec'	=> [
			{
				'chans' => [
			        { # HASH(0x85110f4)
			          chan => 'bbc1',
			          out => 'avs',
			        },
			        { # HASH(0x84fab14)
			          chan => 'itv1',
			        },
				],
				'file' => 'nmnmnm',
				'duration' => '0:30',
				'pids' => [
				],
				'offset' => '0:30',
			},
		],
	},
	{
		'args'	=> [ 'f=nmnmnm', 'ch=bbc1', 'len=1:30', 'off=0:10', 'output=avs', 'file=yyyyyy', 'pid=6273', 'pid=6274', 'len=0:30', 'off=0:30', ],
		'chan_spec'	=> [
			{
				'chans' => [
			        { # HASH(0x84be384)
			          chan => 'bbc1',
			          out => 'avs',
			        },
				],
				'file' => 'nmnmnm',
				'duration' => '1:30',
				'pids' => [
				],
				'offset' => '0:10',
			},
			{
				'chans' => [
				],
				'file' => 'yyyyyy',
				'duration' => '0:30',
				'pids' => [
					'6273',
					'6274',
				],
				'offset' => '0:30',
			},
		],
	},
	{
		'args'	=> [ 'f=nmnmnm', 'pid=6273', 'pid=6274', 'len=1:00', 'off=0:0', 'file=yyyyyy', 'len=0:30', 'off=1:00', 'pid=600', 'pid=605', ],
		'chan_spec'	=> [
			{
				'chans' => [
				],
				'file' => 'nmnmnm',
				'duration' => '1:00',
				'pids' => [
					'6273',
					'6274',
				],
				'offset' => '0:0',
			},
			{
				'chans' => [
				],
				'file' => 'yyyyyy',
				'duration' => '0:30',
				'pids' => [
					'600',
					'605',
				],
				'offset' => '1:00',
			},
		],
	},

	## should cause errors
	{
		# no file
		'args'	=> [ 'chan=bbc1', 'duration=0:30', 'offset=0:10', 'lang=eng', 'out=audio,video', ],
		'error' => "defined before specifying the filename",
		'chan_spec'	=> [
		],
	},
	{
		# no duration
		'args'	=> [ 'file=nmnmnm', 'chan=bbc1', 'offset=0:10', 'lang=eng', 'out=audio,video', ],
		'error' => "no duration specified",
		'chan_spec'	=> [
			{
				'chans' => [
			        { # HASH(0x84be384)
			          chan => 'bbc1',
			          lang => 'eng',
			          out => 'audio,video',
			        },
				],
				'file' => 'nmnmnm',
				'pids' => [
				],
				'offset' => '0:10',
			},
		],
	},
	{
		# len before chan
		'args'	=> [ 'f=nmnmnm', 'len=1:00', 'off=0:0', 'lang=eng', 'chan=bbc1', 'out=audio,video', ],
		'error' => "\"lang = eng\" defined before specifying the channel",
		'chan_spec'	=> [
			{
				'chans' => [
				],
				'file' => 'nmnmnm',
				'duration' => '1:00',
				'pids' => [
				],
				'offset' => '0:0',
			},
		],
	},
	{
		'args'	=> [ 'f=nmnmnm', 'pid=6273', 'pid=6274', 'len=1:00', 'off=0:0', 'file=yyyyyy', 'len=0:30', 'off=1:00', 'pid=600', 'pid=605', 'xxx=yyy', ],
		'error' => "Unexpected variable \"xxx = yyy\"",
		'chan_spec'	=> [
			{
				'chans' => [
				],
				'file' => 'nmnmnm',
				'duration' => '1:00',
				'pids' => [
					'6273',
					'6274',
				],
				'offset' => '0:0',
			},
			{
				'chans' => [
				],
				'file' => 'yyyyyy',
				'duration' => '0:30',
				'pids' => [
					'600',
					'605',
				],
				'offset' => '1:00',
			},
		],
	},
	{
		'args'	=> [ 'f=nmnmnm', 'pid=6273', 'pid=6274', 'len=1:00', 'off=0:0', 'file=yyyyyy', 'len=0:30', 'off=1:00', 'pid=600', 'pid=605', 'xxx', ],
		'error' => "Unexpected arg \"xxx\"",
		'chan_spec'	=> [
			{
				'chans' => [
				],
				'file' => 'nmnmnm',
				'duration' => '1:00',
				'pids' => [
					'6273',
					'6274',
				],
				'offset' => '0:0',
			},
			{
				'chans' => [
				],
				'file' => 'yyyyyy',
				'duration' => '0:30',
				'pids' => [
					'600',
					'605',
				],
				'offset' => '1:00',
			},
		],
	},
	{
		'args'	=> [ 'f=nmnmnm', 'len=1:00', 'off=0:0'],
		'error' => "has no channels/pids specified",
		'chan_spec'	=> [
			{
				'chans' => [
				],
				'file' => 'nmnmnm',
				'duration' => '1:00',
				'pids' => [
				],
				'offset' => '0:0',
			},
		],
	},
#	{
#		'args'	=> [ 'f=nmnmnm', 'ch=bbc1', 'len=1:30', 'off=0:10', 'output=avs', 'file=yyyyyy', 'pid=6273', 'pid=6274', 'ch=itv1', 'len=0:30', 'off=0:30', ],
#		'error' => "has both channels and pids specified at the same time",
#		'chan_spec'	=> [
#			{
#				'chans' => [
#			        { # HASH(0x84be384)
#			          chan => 'bbc1',
#			          out => 'avs',
#			        },
#				],
#				'file' => 'nmnmnm',
#				'duration' => '1:30',
#				'pids' => [
#				],
#				'offset' => '0:10',
#			},
#			{
#				'chans' => [
#			        { # HASH(0x84be784)
#			          chan => 'itv1',
#			        },
#				],
#				'file' => 'yyyyyy',
#				'duration' => '0:30',
#				'pids' => [
#					'6273',
#					'6274',
#				],
#				'offset' => '0:30',
#			},
#		],
#	},
	
);

plan tests => scalar(@tests) * 2 ;

	foreach my $test_href (@tests)
	{
		## add beta params
		foreach my $href (@{$test_href->{'chan_spec'}})
		{
			$href->{'event_id'} = -1 ;
			$href->{'timeslip'} = 'off' ;
			$href->{'max_timeslip'} = 0 ;
		}
		
		
		test_parse($dvb, $test_href->{'args'}, $test_href->{'chan_spec'}, $test_href->{'error'},) ;
	}

	
	exit 0 ;

#------------------------------------------------------------------------------------------------
sub test_parse
{
	my ($dvb, $args_aref, $expected_aref, $exp_error) = @_ ;

	my @chan_spec ;
	my $error = $dvb->multiplex_parse(\@chan_spec, @$args_aref) ;

#	print "\n===========================\n" ;
#	Linux::DVB::DVBT::prt_data("args=", $args_aref) ;
#	print "ERROR: $error\n" if $error ;
#	Linux::DVB::DVBT::prt_data("chan spec=", \@chan_spec) ;

	if ($exp_error)
	{
		like($error, qr/$exp_error/, "Expected error") ;
	}
	else
	{
		is($error, 0, "Unexpected error") ;
	}
	
	is_deeply(\@chan_spec, $expected_aref, "Expected channel spec") ;

}
	
	
__END__

