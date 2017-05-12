use strict;
use warnings;

use Test::More 0.88;
use Test::DZil;
use Path::Tiny;

my $tzil = Builder->from_config(
	{ dist_root => 'does-not-exist' },
	{
		add_files => {
			'source/dist.ini' => simple_ini(
				'GatherDir',
				[ Substitute => {
						file => 'lib/Foo/Bar.pm',
						code => 's/Bar/Baz/g',
					}
				],
			),
			path(qw(source lib Foo Bar.pm)) => "package Foo::Bar;\n1;\n",
		},
	}
);

$tzil->build;

my $dir = path($tzil->tempdir)->child('build');

my $file = $dir->child('lib', 'Foo', 'Bar.pm');
ok -e $file;
my $content = $file->slurp_utf8;

is($content, "package Foo::Baz;\n1;\n", 'file contents were transformed');

done_testing;

# vim: ts=2 sts=2 sw=2 noet :
