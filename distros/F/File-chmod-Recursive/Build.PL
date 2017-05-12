#!perl

####################
# LOAD MODULES
####################
use strict;
use warnings FATAL => 'all';
use Module::Build;

# Autoflush ON
local $| = 1;

####################
# INIT BUILDER
####################

my $builder = Module::Build->new(
    module_name        => 'File::chmod::Recursive',
    license            => 'perl',
    dist_author        => 'Mithun Ayachit <mithun@cpan.org>',
    configure_requires => { 'Module::Build' => 0.38 },
    build_requires     => {
        'Test::More' => 0,
        'version'    => 0,
    },
    requires => {
        'File::chmod' => '0.42',
        'File::Find'  => 0,
        'Cwd'         => 0,
    },
    add_to_cleanup     => ['File-chmod-Recursive-*'],
    create_license     => 1,
    create_makefile_pl => 'traditional',
    meta_merge         => {
        keywords  => [qw(chmod stat permissions mode file recursive)],
        resources => {
            bugtracker =>
              'https://github.com/mithun/perl-file-chmod-recursive/issues',
            repository =>
              'git://github.com/mithun/perl-file-chmod-recursive.git',
            homepage => 'https://github.com/mithun/perl-file-chmod-recursive',
        },
    },
);

####################
# CREATE BUILD SCRIPT
####################
$builder->create_build_script();
