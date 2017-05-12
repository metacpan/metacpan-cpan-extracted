#! /usr/bin/perl

use strict;
use warnings;
use Test::More;
use Log::Any::Adapter::Util ':levels';
use Log::Any '$log';
$SIG{__DIE__}= $SIG{__WARN__}= sub { diag @_; };

use_ok( 'Log::Any::Adapter', 'Daemontools' ) || BAIL_OUT;

my $cfg= Log::Any::Adapter::Daemontools->new_config;

subtest gnu_style => sub {
	my @tests= (
		[  0, '-a -b -c'    ],
		[  1, '--verbose'   ],
		[  1, '-v'          ],
		[ -1, '--quiet'     ],
		[ -1, '-q'          ],
		[  0, '-q -v'       ],
		[  3, '-v -v -v'    ],
		[  2, '-vv'         ],
		[  1, '-vv --quiet' ],
		[  0, '-vqavq'      ],
		[  0, '--', '-v'    ],
		[ -1, '-q', '--', '--quiet' ],
	);
	my %gnu_cfg= (
		verbose => [ '--verbose', '-v' ],
		quiet   => [ '--quiet', '-q' ],
		stop    => '--',
		bundle  => 1,
	);
	for (@tests) {
		my ($val, $opts)= @$_;
		my @array= split /\s/, $opts;
		is( $cfg->parse_log_level_opts(array => \@array, %gnu_cfg), $val, $opts );
		is( join(' ',@array), $opts, 'unchanged' );
	}
};

subtest extract => sub {
	my @tests= (
		[  0, '-a -b -c'   , '-a -b -c'    ],
		[  1, '--verbose'  , ''            ],
		[  1, '-v'         , ''            ],
		[ -1, '--quiet'    , ''            ],
		[ -1, '-q'         , ''            ],
		[  0, '-q -v'      , ''            ],
		[  2, '-v -v -n'   , '-n'          ],
		[  2, '-vv'        , ''            ],
		[  1, '-vv --quiet', ''            ],
		[  0, '-vqavq'     , '-a'          ],
	);
	my %argv_cfg= (
		verbose => [ '--verbose', '-v' ],
		quiet   => [ '--quiet', '-q' ],
		stop    => '--',
		bundle  => 1,
		remove  => 1
	);
	for (@tests) {
		my ($val, $opts, $new_opts)= @$_;
		my @array= split /\s/, $opts;
		is( $cfg->parse_log_level_opts(array => \@array, %argv_cfg), $val, "$opts => $new_opts" );
		is( join(' ',@array), $new_opts, 'correctly removed' );
	}
};

subtest argv => sub {
	my @tests= (
		[  INFO,   '-a -b -c'   , '-a -b -c'    ],
		[  DEBUG,  '--verbose'  , ''            ],
		[  NOTICE, '-q'         , ''            ],
		[  INFO,   '-vv'        , '-vv'         ],
		[  NOTICE, '-vv --quiet', '-vv'         ],
		[  INFO,   '-vqavq'     , '-vqavq'      ],
	);
	my %argv_cfg= (
		verbose => [ '--verbose', '-v' ],
		quiet   => [ '--quiet', '-q' ],
		remove  => 1,
	);
	for (@tests) {
		my ($val, $opts, $new_opts)= @$_;
		local @ARGV= split /\s/, $opts;
		$cfg->log_level('info');
		$cfg->process_argv(%argv_cfg);
		is($cfg->log_level_num, $val, "$opts => $new_opts" );
		is( join(' ',@ARGV), $new_opts, 'correctly removed' );
	}
};

done_testing;
