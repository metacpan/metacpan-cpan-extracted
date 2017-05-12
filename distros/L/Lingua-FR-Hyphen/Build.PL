use 5.006;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Lingua::FR::Hyphen',
    license             => 'perl_5',
    dist_author         => q{Djibril Ousmanou <djibel@cpan.org>},
    dist_version_from   => 'lib/Lingua/FR/Hyphen.pm',
    release_status      => 'stable',
    configure_requires => {
        'Module::Build' => 0,
    },
    build_requires => {
        'Test::More' => 0,
    },
    requires => {},
    add_to_cleanup     => [ 'Lingua-FR-Hyphen-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
