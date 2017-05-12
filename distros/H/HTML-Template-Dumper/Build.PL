#!/usr/bin/perl
use strict;
use warnings;
use Module::Build;

my $build = Module::Build->new(
	module_name         => 'HTML::Template::Dumper', 
	license             => 'perl', 
	create_makefile_pl  => 'passthrough', 
	requires            => {
		'HTML::Template'   => 2.6, 
		'Data::Dumper'     => 0, 
	}, 
	build_requires      => {
		'Struct::Compare'  => 0, 
		'IO::Scalar'       => 0, 
	}, 
	recommends          => {
		'YAML'             => 0, 
	}, 
);
$build->create_build_script;

