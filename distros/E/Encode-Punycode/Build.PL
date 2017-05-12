#!/usr/bin/perl

use strict;
use utf8;
use warnings;

use Module::Build;

my $b = Module::Build->new(
	'module_name'	=> 'Encode::Punycode',
	'dist_abstract'	=> 'Encode plugin for Punycode (RFC 3492)',
	'dist_author'	=> 'Claus Färber <CFAERBER@cpan.org>',
	'license'	=> 'perl',
	
	'sign'		=> 1,
	'create_license' => 1,
	'create_makefile_pl' => 'traditional',

	'requires'	=> {
		'perl'	=> '5.8.5',
		'Net::IDN::Punycode' => 1,
    		'Encode' => 1,
	},
	'build_requires' => {
		'Test::More' => 0,
		'Test::NoWarnings' => 0,
	},
	'no_index' => {
		'directory' => ['eg']
	},
	'meta_merge' => {
		'resources' => {
			'homepage' => 'http://search.cpan.org/dist/Encode-Punycode',
			'repository' => 'http://github.com/cfaerber/Net-IDN-Encode/tree/Encode-Punycode',
		},
	},
);

$b->create_build_script;
