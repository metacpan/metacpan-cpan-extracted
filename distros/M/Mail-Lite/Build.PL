#!/usr/bin/perl -w

use strict;
use Module::Build;

my $build = Module::Build->new(
    license             => 'perl',
    module_name         => 'Mail::Lite',
    requires            => {
        'perl'              => 5.006,
	'UNIVERSAL::require'=> 0,
	'Smart::Comments'   => 0,
	'MIME::Words'	    => 0,
	'Clone'		    => 0,
    },
    build_requires      => {
        'Test::More'        => 0,
	'YAML::Syck'	    => 0,
    },
    create_makefile_pl  => 'traditional',
    dist_abstract       => 'Mail::Lite -- Lite modules for mail messages parsing etc',
);

$build->create_build_script;
