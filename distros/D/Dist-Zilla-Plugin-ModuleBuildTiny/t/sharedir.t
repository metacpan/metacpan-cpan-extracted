use strict;
use warnings FATAL => 'all';

use Test::More;
use Test::Fatal;
use Test::DZil;

{
	my $tzil = Builder->from_config(
		{ dist_root => 't/does_not_exist' },
		{
			add_files => {
				'source/dist.ini' => simple_ini(
					'GatherDir',
					[ 'ModuleShareDirs' => { 'Foo' => 'share/foo' } ],
					'ModuleBuildTiny',
				),
				'source/share/foo' => 'some extra file',
			},
		},
	);

	like(
		exception { $tzil->build },
		qr/\[ModuleBuildTiny\] Sharedir location for module Foo sharedir should be 'module-share\/Foo'/,
		'warning issued when there is a module sharedir in use',
	);
}

{
	my $tzil = Builder->from_config(
		{ dist_root => 't/does_not_exist' },
		{
			add_files => {
				'source/dist.ini' => simple_ini(
					'GatherDir',
					[ 'ShareDir' => { dir => 'another_share_dir' } ],
					'ModuleBuildTiny',
				),
				'source/another_share_dir/foo' => 'some extra file',
			},
		},
	);

	like(
		exception { $tzil->build },
		qr{\[ModuleBuildTiny\] Sharedir location must be share/},
		'warning issued when the dist sharedir is not share/',
	);
}

done_testing;

# vim: set ts=4 sw=4 noet nolist :
