#!/usr/bin/perl

use 5.006;

use strict;
use warnings;

use lib 'inc';
use Module::Build;

my $module = 'Geo::Coder::GeocodeFarm';

(my $dist = $module) =~ s/::/-/g;

my $build = Module::Build->new(
    module_name             => $module,
    license                 => 'perl',
    requires                => {
        'perl'                  => 5.008,
        'Carp'              => 0,
        'HTTP::Tiny'        => 0,
        'JSON'              => 0,
        'URI'               => 0,
    },
    build_requires          => {
        'Test::Exception'       => 0,
        'Test::Deep'            => 0,
        'Test::More'            => 0.88,
        'Test::RequiresInternet' => 0,
    },
    auto_configure_requires => 0,
    create_makefile_pl      => 'traditional',
    create_readme           => 1,
    create_license          => 1,
    recursive_test_files    => 0,
    add_to_cleanup          => [
        '*.bak', '*.gz', '*.tgz', '*.ppd', '*.ppmx', '*.deb', '*.bat',
        'Makefile', 'pm_to_blib', 'cover_db', 'Debian_CPANTS.txt',
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
