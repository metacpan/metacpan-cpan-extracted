#!/usr/local/bin/perl

use Module::Build;
my $build = Module::Build->new (
	module_name => 'HTML::Transmorgify',
	license  => 'perl',
	dist_abstract => 'Framework for compiling tranformations on HTML text',
	create_readme => 1,
	requires => {
		'Image::Size' => 0,
		'Test::Differences' => 0,
		'File::Slurp' => 0,
		'Object::Dependency' => 0,
		'HTML::Entities' => 0,
		'Digest::MD5' => 0,
		'URI::Escape' => 0,
		'YAML' => 0,
		'Scalar::Util' => 0,
		'List::Util' => 0,
		'Image::Size' => 0,
		'Module::Load' => 0,
	},
	build_requires => {
		'Parse::RecDescent' => 0,
		'Test::Differences' => 0,
	},
	meta_merge => {
		resources => {
			repository => 'https://github.com/muir/HTML-Transmorgify',
		},
	},
);
$build->create_build_script;

