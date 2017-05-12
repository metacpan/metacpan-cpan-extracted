#!/usr/bin/perl
# Copyright 2009-2011, Bartłomiej Syguła (perl@bs502.pl)
#
# This is free software. It is licensed, and can be distributed under the same terms as Perl itself.
#
# For more, see my website: http://bs502.pl/
use strict; use warnings;

use Module::Build;
my $build = Module::Build->new (
    # Who I am :)
    module_name => 'Devel::CoverReport',
    license     => 'perl',

    dist_abstract => 'Advanced coverage reports based on Devel::Cover',
    dist_author   => 'Bartłomiej Syguła <bs@bs502.pl>',

    # What You must have, and what will do You good.
    requires => {
        'perl' => '5.8.0',

        'Devel::Cover'       => '0.74',

        'App::Prove'         => '3.11',
        'Cwd'                => '3.12',
        'Carp::Assert::More' => '1.12',
        'File::Path'         => '1.07',
        'File::Slurp'        => '9999.13',
        'FindBin'            => '1.47',
        'Getopt::Long'       => '2.36',
        'Params::Validate'   => '0.88',
        'Pod::Usage'         => '1.35',
        'Storable'           => '2.15',
        'YAML::Syck'         => '1.05',
        'JSON'               => '2.17',
    },
    build_requires => {
        'Data::Compare' => '1.22',
    },
    recommends => {
    },

    # Play nice with friends ;)
    create_makefile_pl => 'traditional',
    create_packlist    => 1,
    create_readme      => 1,
    dynamic_config     => 0, # No dynamics needed, as of now.
);

$build->create_build_script;

# vim: fdm=marker
