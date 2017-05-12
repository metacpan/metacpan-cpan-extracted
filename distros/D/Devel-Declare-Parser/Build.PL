#!/usr/bin/perl
use strict;
use warnings;
use Module::Build;

my $build = Module::Build->new(
    module_name => 'Devel::Declare::Parser',
    license     => 'perl',
    dist_author => 'Chad Granum <exodist7@gmail.com>',
    create_readme => 1,
    requires => {
        'B::Compiling' => 0.02,
        'B::Hooks::EndOfScope' => 0.08,
        'Devel::Declare' => 0.006000,
        'Test::Exception::LessClever' => 0.005,
        'Test::Simple' => 0.88,
        'Scalar::Util' => 0,
        'Carp' => 0,
    },
    meta_merge => {
        resources => {
            repository  => 'http://github.com/exodist/Devel-Declare-Parser',
            bugtracker  => 'http://github.com/exodist/Devel-Declare-Parser/issues',
        },
    }
);

$build->create_build_script;
