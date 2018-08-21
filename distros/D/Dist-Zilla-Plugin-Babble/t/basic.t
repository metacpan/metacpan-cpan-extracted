#! perl

use strict;
use warnings;

use Test::More 0.88;
use Test::DZil;
use Path::Tiny;

{
	my $tzil = Builder->from_config(
		{ dist_root => 'does-not-exist' },
		{
			add_files => {
				path(qw(source dist.ini)) => simple_ini(
					'GatherDir',
					[ Babble => {  } ],
				),
				path(qw(source lib Foo.pm)) => "package Foo;\nsub foo (\$bar) { } 1;\n",
			},
		}
	);

	$tzil->build;

	my $dir = path($tzil->tempdir)->child('build');

	my $file = $dir->child('lib', 'Foo.pm');
	ok -e $file;
	my $content = $file->slurp_utf8;

	like($content, qr/my \(\$bar\) = \@_;/, 'Signatures are transformed');
}

{
	my $tzil = Builder->from_config(
		{ dist_root => 'does-not-exist' },
		{
			add_files => {
				path(qw(source dist.ini)) => simple_ini(
					'GatherDir',
					[ Babble => { plugins => [ '::CoreSignatures' ] } ],
				),
				path(qw(source lib Foo.pm)) => "package Foo;\nsub foo (\$bar) { } 1;\n",
			},
		}
	);

	$tzil->build;

	my $dir = path($tzil->tempdir)->child('build');

	my $file = $dir->child('lib', 'Foo.pm');
	ok -e $file;
	my $content = $file->slurp_utf8;

	like($content, qr/my \(\$bar\) = \@_;/, 'Signatures are transformed');
}

done_testing;

# vim: ts=4 sts=4 sw=4 noet :
