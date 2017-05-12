use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name       => 'Group::Git::Cmd::Stats',
    license           => 'perl',
    dist_author       => 'Ivan Wills <ivan.wills@gmail.com>',
    dist_version_from => 'lib/Group/Git/Cmd/Stats.pm',
    requires          => {
        'perl'           => '5.010',
        'File::chdir'    => 0,
        'Getopt::Alt'    => '0.3.1',
        'List::Util'     => '1.41',
        'Moose::Role'    => '2.1',
        'Path::Tiny'     => '0.06',
        'version'        => '0.9902',
        'YAML::Syck'     => '1.29',
    },
    build_requires => {
        'Test::More'     => 0,
        'Test::Warnings' => 0,
    },
    add_to_cleanup     => [ 'Group-Git-Cmd-Stats-*' ],
    create_license     => 1,
    meta_merge => {
        resources => {
            repository => 'git://github.com/ivanwills/Group-Git-Cmd-Stats.git',
            bugtracker => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Group::Git::Cmd::Stats',
        },
    },
);

$builder->create_build_script();
