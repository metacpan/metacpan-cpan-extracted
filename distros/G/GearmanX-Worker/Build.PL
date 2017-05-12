use strict;
use warnings;

use Config;
$Config{useithreads} or die 'This Perl binary has been built without threads. But threads are needed here.';

use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'GearmanX::Worker',
    license             => 'perl',
    dist_author         => 'Robert Barta <rho@devc.at>',
    dist_version_from   => 'lib/GearmanX/Worker.pm',
    build_requires => {
        'Test::More'      => 0,
	'Gearman::Worker' => 0,
	'Gearman::Client' => 0,
	'Attribute::Handlers' => 0,
    },
    add_to_cleanup      => [ 'GearmanX-Worker-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
