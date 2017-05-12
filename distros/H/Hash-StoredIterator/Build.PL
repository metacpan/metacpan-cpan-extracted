#!/usr/bin/perl
use strict;
use warnings;
use Module::Build;

my $build = Module::Build->new(
    module_name => 'Hash::StoredIterator',
    license     => 'perl',
    dist_author => 'Chad Granum <exodist7@gmail.com>',
    create_readme  => 1,
    create_license => 1,
    requires => {
        'perl' => '5.10.0',
    },
    build_requires => {
        'ExtUtils::ParseXS' => '3.15',
    },
    test_requires  => {
        'Test2::Bundle::Extended'       => 0,
        'Test2::Tools::Spec'            => 0,
    },
    meta_merge => {
        resources => {
            repository => 'https://github.com/exodist/Hash-StoredIterator',
        },
    },
);

$build->create_build_script;
