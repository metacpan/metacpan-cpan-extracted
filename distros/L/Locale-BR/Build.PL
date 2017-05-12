use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Locale::BR',
    license             => 'perl',
    dist_author         => q{Breno G. de Oliveira <garu@cpan.org>},
    dist_version_from   => 'lib/Locale/BR.pm',
    dist_abstract       => 'Identify Brazilian states by two-letter codes and vice-versa',
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'Exporter' => 0,
    },
    add_to_cleanup      => [ 'Locale-BR-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
