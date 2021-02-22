
use utf8;
use 5.006;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Math::MatrixLUP',
    license             => 'artistic_2',
    dist_author         => q<Daniel Șuteu <trizen@cpan.org>>,
    dist_version_from   => 'lib/Math/MatrixLUP.pm',
    release_status      => 'stable',

    dynamic_config    => 0,
    extra_manify_args => { utf8 => 1 },

    meta_merge => {
                   resources => {
                                 bugtracker => "https://github.com/trizen/Math-MatrixLUP/issues",
                                 homepage   => "https://github.com/trizen/Math-MatrixLUP",
                                 repository => "https://github.com/trizen/Math-MatrixLUP",
                                },
                  },

    configure_requires => {
        'Module::Build' => '0',
    },
    build_requires => {
        'Test::More' => '0',
    },
    requires => {
        perl => '5.010',
        Carp => 0,
    },
    recommends => {
        'Math::AnyNum' => '0.38',
    },
    add_to_cleanup     => [ 'Math-MatrixLUP-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
