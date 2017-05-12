use 5.008;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'HTTP::Validate',
    license             => 'perl',
    dist_author         => q{Michael McClennen <mmcclenn@geology.wisc.edu>},
    dist_version_from   => 'lib/HTTP/Validate.pm',
    build_requires => {
        'Test::More' => 0,
    },
    configure_requires => {
	'Module::Build' => 0.4,
    },
    requires => {
        'perl' => '5.8.1',
    },
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
