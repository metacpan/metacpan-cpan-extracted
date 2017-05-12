use 5.008;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Exporter::ConditionalSubs',
    license             => 'artistic_2',
    dist_author         => q{Larry Leszczynski <larryl@cpan.org>},
    dist_version_from   => 'lib/Exporter/ConditionalSubs.pm',
    release_status      => 'stable',
    configure_requires => {
        'Module::Build' => 0,
    },
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'B'              => 0,
        'B::CallChecker' => 0,
        'B::Generate'    => 0,
        'Carp'           => 0,
        'Exporter'       => 0,
    },
    add_to_cleanup     => [ 'Exporter-ConditionalSubs-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
