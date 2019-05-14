use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name       => 'Group::Git::Cmd::SinceRelease',
    license           => 'perl',
    dist_author       => 'Ivan Wills <ivan.wills@gmail.com>',
    dist_version_from => 'lib/Group/Git/Cmd/SinceRelease.pm',
    requires          => {
        'perl'        => 5.008,
        'File::chdir' => 0,
        'Getopt::Alt' => '0.3.1',
        'Moose::Role' => '2.0',
        'version'     => 0,
    },
    configure_requires => {
        'Module::Build' => 0.38,
    },
    build_requires => {
        'Test::More'     => '0.88',
        'Test::Warnings' => '0.026',
    },
    add_to_cleanup     => [ 'Group-Git-Cmd-SinceRelease-*' ],
    create_license     => 1,
    meta_merge => {
        resources => {
            repository => 'git://github.com/ivanwills/Group-Git-Cmd-SinceRelease.git',
            bugtracker => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Group::Git::Cmd::SinceRelease',
        },
    },
);

$builder->create_build_script();
