#!perl

use strict;
use warnings;
use Test::More ;

use Linux::DVB::DVBT ;
use Linux::DVB::DVBT::Ffmpeg ;

my @args = (
		## should be fine
# INPUT: dest, 			out, 		lang		EXPECTED: 	dest, 		out,		warnings?	errors?						
		['t', 			'',			'',						'./t.mpeg',	'va',		0,			0,			],
		['t.mpeg', 		'',			'',						'./t.mpeg',	'va',		0,			0,			],
		['t.mpeg', 		'av',		'',						'./t.mpeg',	'va',		0,			0,			],
		['t.mpeg', 		'avs',		'',						'./t.mpeg',	'vas',		0,			0,			],
		['t.mpg', 		'',			'',						'./t.mpg',	'va',		0,			0,			],
		['t.mpg', 		'av',		'',						'./t.mpg',	'va',		0,			0,			],
		['t.mpg', 		'avs',		'',						'./t.mpg',	'vas',		0,			0,			],
		['t', 			'',			'+eng eng',				'./t.mpeg',	'vaaa',		0,			0,			],
		['t.mpeg', 		'',			'eng eng eng eng',		'./t.mpeg',	'vaaaa',	0,			0,			],
		['t.mpeg', 		'av',		'+eng eng',				'./t.mpeg',	'vaaa',		0,			0,			],
		['t.mpeg', 		'avs',		'+eng eng',				'./t.mpeg',	'vaaas',	0,			0,			],
		['t.mpg', 		'',			'eng eng eng eng',		'./t.mpg',	'vaaaa',	0,			0,			],
		['t.mpg', 		'av',		'+eng eng',				'./t.mpg',	'vaaa',		0,			0,			],
		['t.mpg', 		'avs',		'+eng eng',				'./t.mpg',	'vaaas',	0,			0,			],

		['t.ts', 		'',			'',						'./t.ts',	'va',		0,			0,			],
		['t.ts', 		'av',		'',						'./t.ts',	'va',		0,			0,			],
		['t.ts', 		'avs',		'',						'./t.ts',	'vas',		0,			0,			],
		['t.ts', 		'',			'eng eng eng eng',		'./t.ts',	'vaaaa',	0,			0,			],
		['t.ts', 		'av',		'+eng eng',				'./t.ts',	'vaaa',		0,			0,			],
		['t.ts', 		'avs',		'+eng eng',				'./t.ts',	'vaaas',	0,			0,			],
		['t.ts', 		'a',		'+eng eng',				'./t.ts',	'aaa',		0,			0,			],
		['t.ts', 		'a',		'',						'./t.ts',	'a',		0,			0,			],

		['t.mp4', 		'',			'',						'./t.mp4',	'va',		0,			0,			],
		['t.mp4', 		'av',		'',						'./t.mp4',	'va',		0,			0,			],
		['t.mp4', 		'avs',		'',						'./t.mp4',	'vas',		0,			0,			],
		['t.mp4', 		'',			'eng eng eng eng',		'./t.mp4',	'vaaaa',	0,			0,			],
		['t.mp4', 		'av',		'+eng eng',				'./t.mp4',	'vaaa',		0,			0,			],
		['t.mp4', 		'avs',		'+eng eng',				'./t.mp4',	'vaaas',	0,			0,			],
		
		['t', 			'a',		'',						'./t.mp2',	'a',		0,			0,			],
		['t.mp2',		'',			'',						'./t.mp2',	'a',		0,			0,			],
		['t.mp3',		'',			'',						'./t.mp3',	'a',		0,			0,			],
		['t', 			'a',		'eng',					'./t.mp2',	'a',		0,			0,			],
		['t.mp2',		'',			'eng',					'./t.mp2',	'a',		0,			0,			],
		['t.mp3',		'',			'eng',					'./t.mp3',	'a',		0,			0,			],
		
		['t', 			'v',		'',						'./t.m2v',	'v',		0,			0,			],
		['t.m2v',		'',			'',						'./t.m2v',	'v',		0,			0,			],
		['t', 			'a',		'+eng',					'./t.mpeg',	'aa',		0,			0,			],
		
		## should cause problems - warnings
		['t.mp2',		'v',		'',						'./t.m2v',	'v',		1,			0,			],
		['t.mp3',		'v',		'',						'./t.m2v',	'v',		1,			0,			],
		['t.m2v',		'a',		'',						'./t.mp2',	'a',		1,			0,			],
		
		['t.mp2',		'',			'eng eng',				'./t.mpeg',	'aa',		1,			0,			],
		['t.mp3',		'',			'eng eng eng',			'./t.mpeg',	'aaa',		1,			0,			],

		['t', 			'v',		'eng',					'./t.m2v',	'v',		1,			0,			],	# lang ignored, no audio (in out)
		['t.m2v',		'',			'+eng',					'./t.m2v',	'v',		1,			0,			],	# lang ignored, no audio (in dest)
		
		['t.mp2',		'v',		'eng',					'./t.m2v',	'v',		1,			0,			],	# lang ignored, no audio (in out), dest modified 
		['t.mp3',		'v',		'eng',					'./t.m2v',	'v',		1,			0,			],	# lang ignored, no audio (in out), dest modified 
		['t.m2v',		'a',		'eng',					'./t.mp2',	'a',		1,			0,			],
		['t.m2v',		'a',		'+eng',					'./t.mpeg',	'aa',		1,			0,			],
		['t.mp2',		'v',		'+eng',					'./t.m2v',	'v',		1,			0,			],	# lang ignored, no audio (in out)
		['t.mp3',		'v',		'+eng',					'./t.m2v',	'v',		1,			0,			],	# lang ignored, no audio (in out)
		['t.m2v',		'a',		'+eng',					'./t.mpeg',	'aa',		1,			0,			],

		['t.mpeg6',		'v',		'',						'./t.m2v',	'v',		1,			0,			],	# output format ignored
		['t.mpeg6',		'',			'',						'./t.mpeg',	'va',		1,			0,			],	# output format ignored, default to mpeg

		## should cause problems - errors
		
	) ;

my $checks_per_test = 4 ;

	plan tests => scalar(@args) * $checks_per_test ;
	

	my $test_num=1 ;
	foreach my $args_aref (@args)
	{
		test_sanity($test_num++, $args_aref) ;
	}
	exit 0 ;

#------------------------------------------------------------------------------------------------
sub test_sanity
{
	my ($test_num, $args_aref) = @_ ;

	print "\n\n---- TEST $test_num ----------------------------------\n" ;

	my $dest = $args_aref->[0] ;
	my $out = $args_aref->[1] ;
	my $lang = $args_aref->[2] ;
	my $exp_dest = $args_aref->[3] ;
	my $exp_out = $args_aref->[4] ;
	my $exp_warnings = $args_aref->[5] ;
	my $exp_errors = $args_aref->[6] ;
	
	my $sig = "(TEST $test_num) [IN: dest=$dest  out=\"$out\"  lang=\"$lang\"  OUT: dest=$exp_dest  out=\"$exp_out\"  warn=$exp_warnings  err=$exp_errors ]" ;
	
	my @errors ;
	my @warnings ;

	print "# INPUT: dest=$dest  out=\"$out\"  lang=\"$lang\"\n" ;
	my $error = Linux::DVB::DVBT::Ffmpeg::sanitise_options(\$dest, \$out, \$lang,  \@errors, \@warnings) ;
	print "# OUTPUT: status=$error  dest=$dest  out=\"$out\"  lang=\"$lang\"\n" ;

	if ($error)
	{
		print "ERROR: $error\n" ;
	}
	foreach (@errors)
	{
		print "ERR: $_\n" ;
	}
	foreach (@warnings)
	{
		print "WARN: $_\n" ;
	}
	
	is($dest, $exp_dest, "Output file mismatch") ;
	is($out, $exp_out, "Output spec mismatch") ;

	print "warn check: exp=$exp_warnings  \@=".scalar(@warnings)."\n" ;
	if ($exp_warnings)
	{
		ok(scalar(@warnings), "Expected warnings but got none") ;
	}
	else
	{
		ok(scalar(@warnings)==0, "Not expecting warnings but got some") ;
	}
	

	print "err check: exp=$exp_errors  \@=".scalar(@errors)."\n" ;
	if ($exp_errors)
	{
		ok(scalar(@errors), "Expected errors but got none") ;
	}
	else
	{
		ok(scalar(@errors)==0, "Not expecting errors but got some") ;
	}
}
	
	
__END__

