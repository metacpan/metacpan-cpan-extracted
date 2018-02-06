use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name       => 'Group::Git::Taggers::Perl',
    license           => 'perl',
    dist_author       => 'Ivan Wills <ivan.wills@gmail.com>',
    dist_version_from => 'lib/Group/Git/Taggers/Perl.pm',
    requires          => {
        'perl'                 => 5.008,
        'Group::Git::Taggers'  => '0.5.0',
        'Moo'                  => '1.0',
        'namespace::autoclean' => 0,
        'version'              => 0,
    },
    build_requires => {
        'Test::More'     => '0.88',
        'Test::Warnings' => '0.026',
    },
    add_to_cleanup     => [ 'Group-Git-Taggers-Perl-*' ],
    create_license     => 1,
    meta_merge => {
        resources => {
            repository => 'git://github.com/ivanwills/Group-Git-Taggers-Perl.git',
            bugtracker => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Group::Git::Taggers::Perl',
        },
    },
);

$builder->create_build_script();
