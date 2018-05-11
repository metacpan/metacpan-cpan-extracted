#!/usr/bin/perl
use 5.006;
use strict;
use warnings;
use Module::Build;

my $build = Module::Build->new(
    module_name => 'Hook::AfterRuntime',
    license     => 'perl',
    dist_author => 'Chad Granum <exodist7@gmail.com>',
    requires => {
        'perl' => '5.006',
        'Exporter' => 5.57,
        'B::Hooks::Parser' => '0.09',
    },
    configure_requires => {
	'Module::Build'   => 0,
    },
    build_requires => {
        'Test::More'      => 0.88,
    },
    meta_merge => {
        resources => {
            repository => 'http://github.com/exodist/Hook-AfterRuntime',
            bugtracker => 'http://github.com/exodist/Hook-AfterRuntime/issues',
            homepage   => 'http://github.com/exodist/Hook-AfterRuntime'
        },
    }
);

$build->create_build_script;
