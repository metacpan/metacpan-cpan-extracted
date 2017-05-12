use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name       => 'Group::Git::Taggers::Maven',
    license           => 'perl',
    dist_author       => 'Ivan Wills <ivan.wills@gmail.com>',
    dist_version_from => 'lib/Group/Git/Taggers/Maven.pm',
    requires          => {
        'perl'                 => 5.008,
        'Group::Git::Taggers'  => '0.5.0',
        'Moo'                  => '1.0',
        'namespace::autoclean' => 0,
        'version'              => 0,
    },
    build_requires => {
        'Test::More'     => 0,
        'Test::Warnings' => 0,
    },
    add_to_cleanup     => [ 'Group-Git-Taggers-Maven-*' ],
    create_license     => 1,
    meta_merge => {
        resources => {
            repository => 'git://github.com/ivanwills/Group-Git-Taggers-Maven.git',
            bugtracker => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Group::Git::Taggers::Maven',
        },
    },
);

$builder->create_build_script();
