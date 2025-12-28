#! perl
use strict;
use warnings;

use Path::Tiny;
use Test::More;
use Test::Fatal;
use Test::DZil;

my $tzil = Builder->from_config(
	{ dist_root => 't/does_not_exist' },
	{
		add_files => {
			'source/dist.ini' => simple_ini(
				'GatherDir',
				[ 'ExecDir' => { 'dir' => 'script' } ],
				'DistBuild',
			),
			'script/foo' => 'some extra file',
		},
	},
);

is(
	exception { $tzil->build },
	undef,
	'warning not issued when the dist sharedir',
);

my $base = path($tzil->built_in);
my $expected = <<'EOF';
load_extension('Dist::Build::Core');
script_dir('script');
EOF
is($base->child('planner/scriptdir.pl')->slurp, $expected, 'scriptdir.pl is exactly like expected');

done_testing;

# vim: set ts=4 sw=4 noet nolist :
