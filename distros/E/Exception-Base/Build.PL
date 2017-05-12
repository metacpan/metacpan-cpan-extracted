#!/usr/bin/perl

use 5.006;

use strict;
use warnings;

use Module::Build;

my $module = 'Exception::Base';

(my $dist = $module) =~ s/::/-/g;

my $build = Module::Build->new(
    module_name             => $module,
    license                 => 'perl',
    requires                => {
        'perl'                  => 5.006,
    },
    recommends              => {
    },
    build_requires          => {
        'Test::Unit::Lite'        => 0.12,
    },
    auto_configure_requires => 0,
    create_makefile_pl      => 'traditional',
    create_readme           => 1,
    create_license          => 1,
    recursive_test_files    => 0,
    add_to_cleanup          => [
        '*.bak', '*.gz', '*.tgz', '*.ppd', '*.ppmx', '*.deb',
        'pm_to_blib', 'cover_db', 'nytprof', 'nytprof.out', 'Debian_CPANTS.txt',
        'compilet*', 'test-*',
        "$dist-*",
    ],
    meta_merge              => {
        resources               => {
            bugtracker => "http://github.com/dex4er/perl-$dist/issues",
            repository => "http://github.com/dex4er/perl-$dist",
        },
    },
);

$build->create_build_script;
