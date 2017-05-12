#!/usr/bin/perl

use warnings;
use strict;
use Module::Build;

Module::Build->new(
	module_name        => 'Finance::Bank::Bundesschatz',
	license            => 'perl',
	create_makefile_pl => 'traditional',
	requires           => {
		'perl'                => '5.6.1',
		'WWW::Mechanize'      => 0.57,
		'HTML::TokeParser'    => 2.24,
		'Class::MethodMaker'  => 1.06,
	},
	recommends         => {
		'IO::Socket::SSL'     => 0.92,
	}
)->create_build_script;
