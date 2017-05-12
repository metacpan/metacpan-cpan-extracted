use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name       => 'Game::Life::NDim',
    license           => 'perl',
    dist_author       => q{Ivan Wills <ivan.wills@gmail.com>},
    dist_version_from => 'lib/Game/Life/NDim.pm',
    requires          => {
        'perl'           => 5.010,
        'Moose'          => 0,
        'Params::Coerce' => 0,
    },
    configure_requires => {
        'Module::Build' => 0.38,
    },
    build_requires => {
        'Test::More'       => '0.88',
        'Test::NoWarnings' => 0,
        'Test::Warn'       => 0,
    },
    add_to_cleanup     => [ 'Game-Life-NDim-*' ],
    create_license     => 1,
    meta_merge         => {
        resources => {
            repository => 'http://github.com/ivanwills/Game-Life-NDim',
            bugtracker => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Game-Life-NDim',
        },
    },
);

$builder->create_build_script();
