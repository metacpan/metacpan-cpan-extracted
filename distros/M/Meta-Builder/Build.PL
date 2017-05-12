#!/usr/bin/perl
use strict;
use warnings;
use Module::Build;

my $build = Module::Build->new(
    module_name => 'Meta::Builder',
    license     => 'perl',
    dist_author => 'Chad Granum <exodist7@gmail.com>',
    create_readme => 1,
    requires => {
        Carp => 0,
    },
    build_requires => {
        'Fennec::Lite'    => "",
        'Test::More'      => "",
        'Test::Exception' => "",
    },
    meta_merge => {
        resources => {
            repository => 'http://github.com/exodist/Meta-Builder',
            bugtracker => 'http://github.com/exodist/Meta-Builder/issues',
        },
    }
);

$build->create_build_script;
