#!/usr/bin/perl -w

use Module::Build;
my $build = Module::Build->new(
	module_name => 'HTTP::Recorder::Httperf',
	license => 'perl',
	requires => {
		'HTTP::Recorder' => '0.03', 
		'File::Temp' => 0,
		'HTTP::Proxy' => '0.13',
		},
	create_makefile_pl => 'traditional',
	create_readme => 1,
	);
$build->create_build_script();
