use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Graphics::GnuplotIF',
    license             => 'perl',
    dist_author         => 'Dr.-Ing. Fritz Mehner <mehner.fritz@web.de>',
    dist_version_from   => 'lib/Graphics/GnuplotIF.pm',
    requires => {
        'Test::More' => 0,
        'version'    => 0,
    },
    add_to_cleanup      => [ 'Graphics-GnuplotIF-*' ],
);

$builder->create_build_script();
