use 5.006;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Lingua::Diversity',
    license             => 'perl',
    dist_author         => q{Aris Xanthos <aris.xanthos@unil.ch>},
    dist_version_from   => 'lib/Lingua/Diversity.pm',
    build_requires => {
        'Test::More' => 0,
        'Test::Pod::Coverage' => 0,
    },
    requires => {
        'perl'              => 5.006,
        'Moose'             => 0,
        'Exception::Class'  => 0,
    },
    add_to_cleanup      => [ 'Lingua-Diversity-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
