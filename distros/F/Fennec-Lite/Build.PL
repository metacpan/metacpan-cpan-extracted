#!/usr/bin/perl
use 5.006;
use strict;
use warnings;
use Module::Build;

my $build = Module::Build->new(
    module_name => 'Fennec::Lite',
    license     => 'perl',
    dist_author => 'Chad Granum <exodist7@gmail.com>',
    create_readme => 1,
    requires => {
        'perl' => 5.006,
        'Test::More' => 0,
        'Test::Builder' => 0,
        'List::Util' => 0,
    },
    meta_merge => {
        resources => {
            repository => 'http://github.com/exodist/Fennec-Lite',
            bugtracker => 'http://github.com/exodist/Fennec-Lite/issues',
            homepage   => 'http://open-exodus.net/projects/Fennec-Lite'
        },
    }
);

$build->create_build_script;
