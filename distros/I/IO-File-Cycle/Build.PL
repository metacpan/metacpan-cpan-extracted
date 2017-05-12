use 5.006;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'IO::File::Cycle',
    license             => 'perl',
    dist_author         => q{Nic Wolff <nic@angel.net>},
    dist_version_from   => 'lib/IO/File/Cycle.pm',
    configure_requires => { 'Module::Build' => 0.40 },
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'perl' => 5.006,
	'IO::File' => 0,
    },
    add_to_cleanup      => [ 'IO-File-Cycle-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
