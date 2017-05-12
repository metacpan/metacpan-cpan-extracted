#!/usr/bin/perl
use strict;
use warnings;
use Module::Build;

my $build = Module::Build->new(
    module_name => 'Fuckin::Lazy',
    license     => 'perl',
    dist_author => 'Chad Granum <exodist7@gmail.com>',
    create_readme => 1,
    requires => {
        'Test::Simple'      => '0.88',
    },
    meta_merge => {
        resources => {
            repository  => 'http://github.com/exodist/Fuckin-Lazy',
            bugtracker  => 'http://github.com/exodist/Fuckin-Lazy/issues',
        },
    },
);

$build->create_build_script;
