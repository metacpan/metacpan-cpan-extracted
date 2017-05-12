use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name       => 'File::TypeCategories',
    license           => 'perl',
    dist_author       => 'Ivan Wills <ivan.wills@gmail.com>',
    dist_version_from => 'lib/File/TypeCategories.pm',
    requires          => {
        'perl'            => '5.006',
        'autodie'         => 0,
        'File::chdir'     => 0,
        'File::ShareDir'  => '1.0',
        'Moo'             => '1.0',
        'Path::Tiny'      => 0,
        'Type::Tiny'      => '1.0',
        'Types::Standard' => '1.0',
        'YAML'            => '1.0',
    },
    build_requires => {
        'Test::More'      => '0.88',
        'Test::Warnings'  => 0,
    },
    share_dir => {
        dist => [
            'config',
        ],
    },
    add_to_cleanup     => [ 'File-TypeCategories-*' ],
    create_license     => 1,
    meta_merge => {
        resources => {
            repository => 'git://github.com/ivanwills/File-TypeCategories.git',
            bugtracker => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=File::TypeCategories',
        },
    },
);

$builder->create_build_script();
