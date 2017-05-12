use strict;
use warnings;

use Test::More 0.88;
use Test::DZil;
use Path::Tiny;

my $tzil = Builder->from_config(
	{ dist_root => 'does-not-exist' },
	{
		add_files => {
			path(qw(source dist.ini)) => simple_ini(
				'GatherDir',
				[ Substitute => { code => 's/Foo/Bar/g' } ],
			),
			path(qw(source lib Foo.pm)) => "package Foo;\n1;\n",
		},
	}
);

$tzil->build;

my $dir = path($tzil->tempdir)->child('build');

my $file = $dir->child('lib', 'Foo.pm');
ok -e $file;
my $content = $file->slurp_utf8;

is($content, "package Bar;\n1;\n", 'file contents were transformed');

done_testing;

# vim: ts=2 sts=2 sw=2 noet :
