#!/usr/bin/perl
use strict;
use warnings;

use Module::Build;

my $class = Module::Build->subclass(
    class => 'Evented::API::Builder',
    code => q{
        sub ACTION_distmeta {
            use Pod::Select;

            my $self = shift;

            podselect({ -output => 'doc/engine.pod' },
                'lib/Evented/API/Engine.pm');
                
            podselect({ -output => 'doc/module.pod' },
                'lib/Evented/API/Module.pm');

            return $self->SUPER::ACTION_docs;
        }
    }
);

my $build = $class->new(
    module_name         => 'Evented::API::Engine',
    dist_author         => 'Mitchell Cooper <cooper@cpan.org>',
    dist_abstract       => 'Evented API Engine for Perl applications',
    requires            => {
        perl                => '5.010',
        'Evented::Object'   => '5.63',
        'JSON::XS'          => '3.00',
        'Module::Loaded'    => '0.08',
        # Scalar::Util (nothing used unavailable in 5.10 core dist)
    },
    configure_requires  => {
        'Pod::Select'   => 0
    },
    auto_configure_requires => 0,
    license             => 'bsd',
    create_makefile_pl  => 'traditional',
    create_readme       => 1,
    dynamic_config      => 0,
    meta_merge          => {
        resources => {
            repository => 'https://github.com/cooper/evented-api-engine'
        }
    },
);

$build->create_build_script;
