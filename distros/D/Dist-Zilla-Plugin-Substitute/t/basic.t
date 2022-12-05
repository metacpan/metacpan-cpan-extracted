use strict;
use warnings;

use Test::More 0.88;
use Test::DZil;
use Path::Tiny;

subtest 'First case' => sub {
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

};

subtest 'Second case' => sub {
	my $tzil = Builder->from_config(
		{ dist_root => 'does-not-exist' },
		{
			add_files => {
				path(qw(source dist.ini)) => simple_ini(
					'GatherDir',
					[ Substitute => { code => 's/2.*4\n//sg', mode => 'whole' } ],
				),
				path(qw(source lib Foo.pm)) => "1\n2\n3\n4\n5\n",
			},
		}
	);

	$tzil->build;

	my $dir = path($tzil->tempdir)->child('build');

	my $file = $dir->child('lib', 'Foo.pm');
	ok -e $file;
	my $content = $file->slurp_utf8;

	is($content, "1\n5\n", 'file contents were transformed');
};

done_testing;

# vim: ts=4 sts=4 sw=4 noet :
