#!/usr/bin/perl
use strict;
use warnings;

use Module::Build;

my $class = Module::Build->subclass(
    class => 'Evented::Configuration::Builder',
    code => q{
        sub ACTION_distmeta {
            use Pod::Readme;
            use Pod::Select;

            my $self = shift;

            podselect({ -output => 'README.pod' },
                'lib/Evented/Configuration.pm');

            my $parser = Pod::Readme->new();
            $parser->parse_from_file('README.pod', 'README');

            return $self->SUPER::ACTION_docs;
        }
    }
);

my $build = $class->new(
    module_name         => 'Evented::Configuration',
    dist_author         => 'Mitchell Cooper <cooper@cpan.org>',
    dist_abstract       => 'an evented configuration file in a unique and clean format',
    requires            => {
        'perl'              => '5.010',
        'Evented::Object'   => '5.55'
    },
    build_requires      => {
        'Test::More'    => 0,
    },
    configure_requires  => {
        'Module::Build'     => '0.42',
        'Pod::Readme'       => 0,
        'Pod::Select'       => 0
    },
    recommends          => {},
    build_requires      => {},
    license             => 'bsd',
    create_makefile_pl  => 'traditional',
    dynamic_config      => 0,
    meta_merge          => {
        resources => {
            repository => 'https://github.com/cooper/evented-configuration'
        }
    },
);

$build->create_build_script;
