#!/usr/bin/env perl

use strict;
use warnings;

use Module::Build;

my $builder = Module::Build->new(
	module_name => 'Facebook::Messenger::Client',

	dist_author => 'Tudor Marghidanu',
	dist_abstract => 'Facebook Messenger Send API',

	meta_merge => {
		resources => {
			repository => 'https://github.com/marghidanu/facebook-messenger-client'
		},

		x_contributors => [
			'Tudor Marghidanu <tudor@marghidanu.com>',
		],
	},

	license => 'artistic_2',

	# NOTE: Keep list sorted!
	requires => {
		'Mojolicious' => undef,
		'Moose' => undef,
		'MooseX::AbstractFactory' => undef,
		'MooseX::AbstractMethod' => undef,
		'MooseX::Storage' => undef,
		'Test::More' => undef,
		'Test::Pod::Coverage' => undef,
		'Test::Pod' => undef,
	},
);

$builder->create_build_script();
