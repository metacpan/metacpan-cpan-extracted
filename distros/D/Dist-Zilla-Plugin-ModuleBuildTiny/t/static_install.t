use strict;
use warnings;

use Test::More;
use Test::DZil;
use Test::Deep;
use Path::Tiny;

my @tests = (
	{
		test_name => '.PL file present',
		zilla_files => [
			path(qw(source lib Foo.PL)) => qq{#!/usr/bin/perl\nexit 0;\n},
		],
		x_static_install => 0,
	},
	{
		test_name => '.xs file present',
		zilla_files => [
			path(qw(source lib Foo.xs)) => qq{#include "perl.h"\n},
		],
		x_static_install => 0,
	},
	{
		test_name => 'static install',
		x_static_install => 1,
	},

);

subtest $_->{test_name} => sub
{
	my $config = $_;

	my $tzil = Builder->from_config(
		{ dist_root => 't/does_not_exist' },
		{
			add_files => {
				'source/dist.ini' => simple_ini(
					[ ModuleBuildTiny => {
							static => 'auto',
						}
					],
					'MetaJSON',
				),
				path(qw(source lib Foo.pm)) => "package Foo;\n1;\n",
				@{ $config->{zilla_files} || [] },
			},
		},
	);
	$tzil->build;

	cmp_deeply(
		$tzil->distmeta,
		superhashof({
			x_static_install => 1,
		}),
		"metadata contains auto-computed value for x_static_install($config->{x_static_install})",
	) or diag 'got distmeta: ', explain $tzil->distmeta;
}
foreach @tests;

done_testing;

# vim: set sts=4 ts=4 sw=4 noet nolist :
