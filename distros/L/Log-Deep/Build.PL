use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name       => 'Log::Deep',
    license           => 'perl',
    dist_author       => 'Ivan Wills <ivan.wills@gmail.com>',
    dist_version_from => 'lib/Log/Deep.pm',
    requires          => {
        perl                         => 5.008,
        'Data::Dump::Streamer'       => '2.08',
        'Clone'                      => '0.29',
        'List::MoreUtils'            => 0,
        'Path::Tiny'                 => 0,
        'Term::ANSIColor'            => 0,
        'Time::HiRes'                => '1.9711',
        'Readonly'                   => '1.03',
        'version'                    => 0,
    },
    configure_requires => {
        'Module::Build' => 0.38,
    },
    build_requires => {
        'Test::More'      => '0.88',
        'Test::Warnings'  => 0,
        'Test::Warn'      => 0,
        'Test::Exception' => 0,
    },
    recommends => {
        'Test::Pod'           => 0,
        'Test::Pod::Coverage' => 0,
        'Test::Spelling'      => 0,
    },
    add_to_cleanup     => [ 'Log-Deep-*' ],
    create_makefile_pl => 'traditional',
    create_license     => 1,
    meta_merge         => {
        resources => {
            repository => 'http://github.com/ivanwills/Log-Deep',
            bugtracker => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Log-Deep',
        },
    },
);

$builder->create_build_script();
