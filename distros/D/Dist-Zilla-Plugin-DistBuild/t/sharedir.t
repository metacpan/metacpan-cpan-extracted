use strict;
use warnings FATAL => 'all';

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
				[ 'ModuleShareDirs' => { 'Foo' => 'share/foo' } ],
				'DistBuild',
			),
			'source/share/foo' => 'some extra file',
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
load_module('Dist::Build::ShareDir');
module_sharedir('share/foo', 'Foo');
EOF
is($base->child('planner/sharedir.pl')->slurp, $expected, 'sharedir.pl is exactly like expected');

done_testing;

# vim: set ts=4 sw=4 noet nolist :
