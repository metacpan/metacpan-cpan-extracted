#!/usr/bin/perl
use strict;
use warnings;

use Module::Build;

my $class = Module::Build->subclass(
    class => 'Evented::API::Builder',
    code => q{
        sub ACTION_docs {
            use Pod::Select;
            use Pod::Readme;
            use File::Copy;

            my $self = shift;

            # Generate .pod files
            podselect({ -output => 'doc/Evented/API/Engine.pod' },
                'lib/Evented/API/Engine.pm');
            podselect({ -output => 'doc/Evented/API/Module.pod' },
                'lib/Evented/API/Module.pm');

            # Copy Engine.pod to README.pod
            copy('doc/Evented/API/Engine.pod', 'README.pod');

            # Extract text to generate plain-text README
            my $parser = Pod::Readme->new();
            $parser->parse_from_file('README.pod', 'README');

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
        'Pod::Select'   => 0,
        'Pod::Readme'   => 0
    },
    auto_configure_requires => 0,
    license             => 'bsd',
    create_readme       => 1,
    dynamic_config      => 0,
    meta_merge          => {
        resources => {
            repository => 'https://github.com/cooper/evented-api-engine'
        }
    },
);

$build->create_build_script;
