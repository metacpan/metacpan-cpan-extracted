use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name       => 'Group::Git::Cmd::Todo',
    license           => 'perl',
    dist_author       => 'Ivan Wills <ivan.wills@gmail.com>',
    dist_version_from => 'lib/Group/Git/Cmd/Todo.pm',
    requires          => {
        'perl'             => 5.010,
        'File::chdir'    => 0,
        'Getopt::Alt'    => '0.3.1',
        'Moose::Role'    => '2.1',
        'Path::Tiny'     => '0.06',
        'version'        => '0.9902',
    },
    configure_requires => {
        'Module::Build' => 0.38,
    },
    build_requires => {
        'Test::More'     => '0.88',
        'Test::Warnings' => '0.026',
    },
    add_to_cleanup     => [ 'Group-Git-Cmd-Todo-*' ],
    create_license     => 1,
    meta_merge => {
        resources => {
            repository => 'git://github.com/ivanwills/Group-Git-Cmd-Todo.git',
            bugtracker => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Group::Git::Cmd::Todo',
        },
    },
);

$builder->create_build_script();
