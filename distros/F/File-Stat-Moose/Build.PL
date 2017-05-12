#!/usr/bin/perl

use 5.008;

use strict;
use warnings;

use Module::Build;

my $module = 'File::Stat::Moose';

(my $dist = $module) =~ s/::/-/g;

my $build = Module::Build->new(
    module_name => $module,
    license => 'perl',
    requires => {
        'perl'                => 5.008,
        'constant::boolean'   => 0,
        'DateTime'            => 0,
        'Exception::Argument' => 0.05,
        'Exception::Base'     => 0.21,
        'Exception::System'   => 0.11,
        'Moose'               => 0,
        'Sub::Exporter'       => 0,
        'Test::Assert'        => 0.04,
    },
    optional => {
    },
    build_requires => {
        'parent'              => 0,
        'Exception::Died'     => 0.04,
        'Exception::Warning'  => 0.03,
        'Test::Unit::Lite'    => 0.11,
    },
    create_makefile_pl => 'traditional',
    sign => 1,
    create_readme => 1,
    create_license => 1,
    recursive_test_files => 1,
    add_to_cleanup => [
        '*.bak', '*.gz', '*.tgz', '*.ppd', '*.ppmx', '*.deb', '*.bat',
        'Makefile', 'pm_to_blib', 'cover_db', 'Debian_CPANTS.txt',
        "$dist-*",
    ],
    meta_merge => {
        resources => {
            bugtracker => "http://rt.cpan.org/NoAuth/Bugs.html?Dist=$dist",
            repository => "http://code2.0beta.co.uk/moose/svn/$dist",
        }
    },
);

$build->create_build_script;
