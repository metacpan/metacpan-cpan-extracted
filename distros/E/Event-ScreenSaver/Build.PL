use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name       => 'Event::ScreenSaver',
    license           => 'perl',
    dist_author       => 'Ivan Wills <ivan.wills@gmail.com>',
    dist_version_from => 'lib/Event/ScreenSaver.pm',
    requires          => {
        perl               => 5.006,
        'List::MoreUtils'  => 0,
        'Module::Build'    => 0,
        'Moose'            => 0,
        'Pod::Usage'       => 0,
        'Test::More'       => 0,
        'Test::NoWarnings' => 0,
        'version'          => 0,
        'warnings'         => 0,
    },
    configure_requires => {
        'Module::Build' => 0.38,
    },
    build_requires => {
        'Test::More'     => 0,
        'Test::Warnings' => 0,
    },
    add_to_cleanup     => [ 'Event-ScreenSaver-*' ],
    create_makefile_pl => 'traditional',
    create_license     => 1,
    meta_merge         => {
        resources => {
            repository => 'http://github.com/ivanwills/Event-ScreenSaver',
            bugtracker => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Event-ScreenSaver',
        },
    },
);

$builder->create_build_script();
