use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Lingua::LO::Romanize',
    license             => 'perl',
    dist_author         => 'Joakim Lagerqvist <jokke@cpan.org>',
    dist_version_from   => 'lib/Lingua/LO/Romanize.pm',
    build_requires => {
        'Moose'                         => 0,
        'utf8'                          => 0,
        'Moose::Util::TypeConstraints'  => 0,
        'MooseX::AttributeHelpers'      => 0,
        'MooseX::Params::Validate'      => 0,
        'Test::More'                    => 0,
    },
    add_to_cleanup      => [ 'Lingua-LO-Romanize-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
