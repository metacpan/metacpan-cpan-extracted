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
    module_name        => 'Jar::Manifest',
    license            => 'perl',
    dist_author        => 'Mithun Ayachit <mithun@cpan.org>',
    configure_requires => { 'Module::Build' => 0.38 },
    build_requires     => {
        'Test::More' => 0,
        'version'    => 0,
    },
    requires => {
        'Encode'     => 0,
        'Text::Wrap' => 0,
    },
    add_to_cleanup     => ['Jar-Manifest-*'],
    create_license     => 1,
    create_makefile_pl => 'traditional',
    meta_merge         => {
        keywords  => [qw(java jar manifest)],
        resources => {
            bugtracker =>
              'https://github.com/mithun/perl-jar-manifest/issues',
            repository => 'git://github.com/mithun/perl-jar-manifest.git',
            homepage   => 'https://github.com/mithun/perl-jar-manifest',
        },
    },
);

####################
# CREATE BUILD SCRIPT
####################
$builder->create_build_script();
