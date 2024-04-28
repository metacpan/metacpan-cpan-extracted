#!perl
# vi:noet:sts=2:sw=2:ts=2
use strict;
use warnings;

use Test::More 0.88;

use Test::DZil;
use Path::Tiny;
use CPAN::Meta;

{
	my $tzil = Builder->from_config(
		{ dist_root => 'corpus/' },
		{
			add_files => {
				'source/dist.ini' => simple_ini(
					'GatherDir',
					'MetaJSON',
					[ 'DynamicPrereqs::Meta' => {
							condition => [ 'is_os linux' ],
							prereqs => [ 'Foo 1' ],
						}
					],
				),
			},
		},
	);

	$tzil->build;

	my $dir = path($tzil->tempdir, 'build');

  my $meta = CPAN::Meta->load_file($dir->child('META.json'));
	is_deeply $meta->custom('x_dynamic_prereqs'), {
		version => 1,
		expressions => [
			{
				condition => [
					'is_os', 'linux',
				],
				prereqs => {
					Foo => 1,
				},
			}
		]
	};
	diag 'got log messages: ', explain $tzil->log_messages
		if not Test::Builder->new->is_passing;
}

{
	my $tzil = Builder->from_config(
		{ dist_root => 'corpus/' },
		{
			add_files => {
				'source/dist.ini' => simple_ini(
					'GatherDir',
					'MetaJSON',
					[ 'DynamicPrereqs::Meta' => {
							condition => [ 'is_os linux' ],
							error => 'OS not supported'
						}
					],
				),
			},
		},
	);

	$tzil->build;

	my $dir = path($tzil->tempdir, 'build');

  my $meta = CPAN::Meta->load_file($dir->child('META.json'));
	is_deeply $meta->custom('x_dynamic_prereqs'), {
		version => 1,
		expressions => [
			{
				condition => [
					'is_os', 'linux',
				],
				error => 'OS not supported',
			}
		]
	};
	diag 'got log messages: ', explain $tzil->log_messages
		if not Test::Builder->new->is_passing;
}

{
	my $tzil = Builder->from_config(
		{ dist_root => 'corpus/' },
		{
			add_files => {
				'source/dist.ini' => simple_ini(
					'GatherDir',
					'MetaJSON',
					[ 'DynamicPrereqs::Meta' => {
							condition => [ 'is_os linux', 'has_perl 5.010' ],
							prereqs => [ 'Foo 1' ],
						}
					],
				),
			},
		},
	);

	$tzil->build;

	my $dir = path($tzil->tempdir, 'build');

  my $meta = CPAN::Meta->load_file($dir->child('META.json'));
	is_deeply $meta->custom('x_dynamic_prereqs'), {
		version => 1,
		expressions => [
			{
				condition => [
					'and' =>
						[ 'is_os', 'linux' ],
						[ 'has_perl', '5.010' ],
				],
				prereqs => {
					Foo => 1,
				},
			}
		]
	};
	diag 'got log messages: ', explain $tzil->log_messages
		if not Test::Builder->new->is_passing;
}

done_testing;
