#!/usr/bin/perl
use strict;
use warnings;
use Module::Build;

my $build = Module::Build->new(
    module_name => 'Devel::Memalyzer',
    license     => 'perl',
    dist_author => 'Chad Granum <exodist7@gmail.com>',
    create_readme => 1,
    build_requires => {
        'Test::More' => 0,
        'Test::Exception' => 0,
    },
);

$build->create_build_script;
