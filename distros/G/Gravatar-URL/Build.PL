#!/usr/bin/perl -w

use 5.006;

use strict;
use Module::Build;

my $builder = Module::Build->new(
    module_name => 'Gravatar::URL',
    license     => 'perl',

    meta_merge  => {
        resources => {
            bugtracker =>
              'http://rt.cpan.org/Public/Dist/Display.html?Name=Gravatar-URL',
            repository =>
              'http://github.com/schwern/gravatar-url/tree/master',
        },

        keywords => [ 'Gravatar' ],

        configure_requires => {
            'Module::Build'     => 0.2808
        },
    },

    build_requires      => {
        'Test::More'        => 0.40,
        'Test::Warn'        => 0.11,
        'Test::MockRandom'  => 1.01,
    },

    requires             => {
        'Net::DNS'           => 1.01,
        'URI::Escape'        => 0,
        'Digest::MD5'        => 0,
        'Digest::SHA'        => 0,
        'Carp'               => 0,
        perl                 => '5.6.0',
        'parent'             => 0,
    },
    dist_version_from => 'lib/Gravatar/URL.pm',
    create_readme => 1,
    create_license => 1,
    dist_author => 'Michael G. Schwern <schwern@pobox.com>'
);

$builder->create_build_script();
