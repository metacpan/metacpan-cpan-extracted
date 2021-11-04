#!perl
# vi:noet:sts=2:sw=2:ts=2
use strict;
use warnings;

use Test::More 0.88;

use Test::DZil;
use Path::Tiny;

{
	my $tzil = Builder->from_config(
		{ dist_root => 'corpus/' },
		{
			add_files => {
				'source/dist.ini' => simple_ini(
					'GatherDir',
					'PPPort',
					[ Prereqs => { perl => '5.008' } ],
				),
				'source/foo.h' => '#!include <stdio.h>',
			},
		},
	);

	$tzil->build;

	my $dir = path($tzil->tempdir, 'build');

	ok -e $dir->child('ppport.h');
	ok -s $dir->child('ppport.h');
	diag 'got log messages: ', explain $tzil->log_messages
		if not Test::Builder->new->is_passing;
}

{
	my $tzil = Builder->from_config(
		{
			dist_root => 'corpus/',
		},
		{
			add_files => {
				'source/dist.ini' => simple_ini(
					{ name => 'Foo-Bar' },
					'GatherDir',
					[ PPPort => { style => 'ModuleBuild' } ],
				),
				'source/foo.h' => '#!include <stdio.h>',
			},
		},
	);

	$tzil->build;

	my $dir = path($tzil->tempdir, 'build');

	ok -e $dir->child('lib/Foo/ppport.h');
	ok -s $dir->child('lib/Foo/ppport.h');

	diag 'got log messages: ', explain $tzil->log_messages
		if not Test::Builder->new->is_passing;
}

done_testing;
