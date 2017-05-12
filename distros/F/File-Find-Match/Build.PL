#!/usr/bin/perl
use Module::Build;
require 0.008;
my $build = Module::Build->new(
	module_name        => 'File::Find::Match',
	dist_version_from  => 'lib/File/Find/Match.pm',
	dist_author        => 'Dylan William Hardison <dhardison@cpan.org>',
	license            => 'perl',
	requires           => {
		'perl' => '5.8.0',
	},
	build_requires     => {
		'Test::More' => 0,
	},	
	create_makefile_pl => 'passthrough',
    sign => 1,
);

$build->create_build_script;

