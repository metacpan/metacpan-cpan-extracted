use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name       => 'File::CodeSearch',
    license           => 'perl',
    dist_author       => 'Ivan Wills <ivan.wills@gmail.com>',
    dist_version_from => 'lib/File/CodeSearch.pm',
    requires          => {
        perl                   => 5.006,
        autodie                => 0,
        'Carp'                 => 0,
        'Clone'                => 0,
        'Config::General'      => 0,
        'File::chdir'          => 0,
        'File::Slurp'          => 0,
        'File::Basename'       => 0,
        'File::Spec'           => 0,
        'File::TypeCategories' => 0.01,
        'File::chdir'          => 0,
        'IO::Handle'           => 0,
        'IO::Prompt'           => 0,
        'List::MoreUtils'      => 0,
        'List::Util'           => 0,
        'Moose'                => 0,
        'Path::Tiny'           => '0.005',
        'Pod::Usage'           => 0,
        'Readonly'             => 0,
        'Scalar::Util'         => 0,
        'Term::ANSIColor'      => 0,
        'Term::Size::Any'      => 0,
        'version'              => 0,
        'warnings'             => 0,
    },
    configure_requires => {
        'Module::Build' => 0.38,
    },
    build_requires => {
        'File::Spec'     => 0,
        'Test::More'     => '0.88',
        'Test::Warnings' => '0.016',
    },
    add_to_cleanup     => [ 'File-CodeSearch-*' ],
    create_license     => 1,
    meta_merge         => {
        resources => {
            repository => 'http://github.com/ivanwills/File-CodeSearch',
            bugtracker => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=File-CodeSearch',
        },
        abstract => 'Search file contents in code repositories',
    },
);

$builder->create_build_script();
