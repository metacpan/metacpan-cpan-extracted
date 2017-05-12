use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name       => 'Group::Git::Cmd::Ivan',
    license           => 'perl',
    dist_author       => 'Ivan Wills <ivan.wills@gmail.com>',
    dist_version_from => 'lib/Group/Git/Cmd/Ivan.pm',
    requires          => {
        'perl'                          => 5.008,
        'DateTime::Format::Strptime'    => 0,
        'Group::Git'                    => 0,
        'Group::Git::Cmd::SinceRelease' => 0,
        'Group::Git::Cmd::Stats'        => 0,
        'Group::Git::Cmd::Todo'         => 0,
        'Group::Git::Taggers::Maven'    => 0,
        'Group::Git::Taggers::Node'     => 0,
        'Group::Git::Taggers::Perl'     => 0,
        'Group::Git::Taggers::Ruby'     => 0,
        'File::chdir'                   => 0,
        'Getopt::Alt'                   => '0.1.1',
        'Moose::Role'                   => 0,
        'version'                       => 0,
    },
    configure_requires => {
        'Module::Build' => 0.38,
    },
    build_requires => {
        'Test::More'     => '0.88',
        'Test::Warnings' => 0,
    },
    add_to_cleanup     => [ 'Group-Git-Cmd-Ivan-*' ],
    create_license     => 1,
    meta_merge => {
        resources => {
            repository => 'git://github.com/ivanwills/Group-Git-Cmd-Ivan.git',
            bugtracker => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Group::Git::Cmd::Ivan',
        },
    },
);

$builder->create_build_script();
