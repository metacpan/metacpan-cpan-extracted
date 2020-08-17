#!/usr/bin/env perl

use strict;
use warnings;

use Module::Build;

my $builder = Module::Build->new(
    module_name => 'Docker::Client',

    dist_author   => 'Tudor Marghidanu',
    dist_abstract => 'Docker client',

    meta_merge => {
        resources => {
            repository => 'https://gitlab.com/marghidanu/docker-client.git',
        },

        x_contributors => [ 'Tudor Marghidanu <tudor@marghidanu.com>', ],
    },

    license => 'artistic_2',

    share_dir => 'share',

    requires => {
        'Array::Utils'     => '0.5',
        'Class::Inspector' => '1.36',
        'Moose'            => '2.2013',
        'OpenAPI::Client'  => '0.25',
    },

    test_requires => {
        'Test::More' => '1.302177',
        'Test::Pod'  => '1.52',
    },
);

$builder->create_build_script();
