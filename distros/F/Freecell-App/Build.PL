use 5.006;
use strict;
use warnings FATAL => 'all';
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Freecell::App',
    license             => 'artistic_2',
    dist_author         => q{Shirl Hart <shirha@cpan.org>},
    dist_version_from   => 'lib/Freecell/App.pm',
    release_status      => 'stable',
    script_files        => [ qw(bin/freecell-solver) ],
    share_dir           => 'images',
    configure_requires => {
        'Module::Build' => 0,
    },
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'Storable'          => 2.34,
        'List::Util'        => 1.25,
        'Getopt::Long'      => 2.38,
        'File::Slurp'       => 9999.19,
        'Log::Log4perl'     => 1.39,
    },
    add_to_cleanup     => [ 'Freecell-App-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
