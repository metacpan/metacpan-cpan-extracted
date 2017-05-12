#!/usr/bin/perl
use strict;
use warnings;
use Module::Build;

my $build = Module::Build->new(
    module_name => 'Declare::CLI',
    license     => 'perl',
    dist_author => 'Chad Granum <exodist7@gmail.com>',
    create_readme => 1,
    requires => {
        'Exporter::Declare' => "0.105",
    },
    build_requires => {
        'Fennec'            => '2.004',
        'Fennec::Declare'   => '1.001',
        'Parallel::Runner'  => 0,
    },
    meta_merge => {
        resources => {
            repository  => 'http://github.com/exodist/Declare-CLI',
            bugtracker  => 'http://github.com/exodist/Declare-CLI',
        },
    }
);

$build->create_build_script;
