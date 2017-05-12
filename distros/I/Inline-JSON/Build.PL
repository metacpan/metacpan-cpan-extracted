use 5.006;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Inline::JSON',
    license             => 'perl',
    dist_author         => q{Anthony Kilna <anthony@kilna.com>},
    dist_version_from   => 'lib/Inline/JSON.pm',
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'perl' => 5.010,
        'JSON' => 0,
    },
    add_to_cleanup      => [ 'Inline-JSON-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
