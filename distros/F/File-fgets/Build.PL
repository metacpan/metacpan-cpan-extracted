#!/usr/bin/perl -w

use 5.008001;

use strict;
use Module::Build;

my $builder = Module::Build->new(
    module_name => 'File::fgets',
    license     => 'perl',
    dist_author => 'Michael G Schwern <schwern@pobox.com>',

    meta_merge  => {
        resources => {
            repository =>
              'http://github.com/schwern/File-fgets/tree/master',
        },

        keywords => [ 'fgets', 'XS' ],

        configure_requires => {
            'Module::Build'     => 0.2808
        },
    },

    build_requires      => {
        'Test::More'        => '0.88',
    },

    requires             => {
        perl                => '5.8.1',
        XSLoader            => '0.02',
        'File::Temp'        => '0.14',
    },

    create_readme       => 1,
    create_license      => 1,
);

$builder->create_build_script();
