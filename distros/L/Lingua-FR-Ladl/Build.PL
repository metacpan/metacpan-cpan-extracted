use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Lingua::FR::Ladl',
    license             => 'perl',
    dist_author         => 'Ingrid Falk <ingrid dot falk at loria dot fr>',
    dist_version_from   => 'lib/Lingua/FR/Ladl.pm',
    requires => {
        'Test::More' => 0,
        'version'    => 0,
    },
    add_to_cleanup      => [ 'Lingua-FR-Ladl-*' ],
);

$builder->create_build_script();
