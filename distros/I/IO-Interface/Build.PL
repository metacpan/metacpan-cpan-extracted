#!/usr/bin/perl

use strict;
use Module::Build;

my $build = Module::Build->new(
    module_name        => 'IO::Interface',
    dist_version_from  => 'lib/IO/Interface.pm',
    dist_author        => 'Lincoln Stein <lincoln.stein@gmail.com>',
    dist_abstract      => 'Access and modify network interface card configuration',
    license            => 'perl',
    build_requires => {
	'ExtUtils::CBuilder' => 0,
    },
    requires     => {
	'perl'                => '5.005',
    },
    );

$build->create_build_script();

# get rid of annoying warning from ExtUtils::ParseXS
my $sub = 's/\$\^W\s*=\s*1/\$^W = 0/';
system "perl -pi -e '$sub' Build";

exit 0;
