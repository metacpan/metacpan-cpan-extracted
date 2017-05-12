use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'File::Find::Age',
    license             => 'perl',
    dist_author         => 'Jozef Kutej <jkutej@cpan.org>',
    dist_version_from   => 'lib/File/Find/Age.pm',
    requires => {
        'File::Find::Rule' => 0,
        'File::Spec'       => 0,
    },
    configure_requires => {
        'Module::Build'   => '0.36',
    },
    build_requires => {
        'Test::More'      => 0,
    },
    add_to_cleanup      => [ 'File-Find-Age-*' ],
    create_readme       => 1,
    sign                => 1,
    meta_merge => {
        resources => {
            repository => 'http://github.com/jozef/File-Find-Age',
            bugtracker => 'http://github.com/jozef/File-Find-Age/issues',
        },
        keywords => [ qw/ file mtime age / ],
    },
);

$builder->create_build_script();
