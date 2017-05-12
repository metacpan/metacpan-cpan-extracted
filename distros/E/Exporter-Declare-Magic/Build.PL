#!/usr/bin/perl
use strict;
use warnings;
use Module::Build;

my $build = Module::Build->new(
    module_name => 'Exporter::Declare::Magic',
    license     => 'perl',
    dist_author => 'Chad Granum <exodist7@gmail.com>',
    create_readme => 1,
    requires => {
        'perl'          => '5.8.0',
        'Carp'          => 0,
        'Scalar::Util'  => 0,
        'aliased'       => 0,
        'Meta::Builder' => '0.003',
        'Exporter::Declare' => '0.107',
        'Devel::Declare::Parser' => '0.017',
    },
    build_requires => {
        'Test::Simple'    => 0.88,
        'Fennec::Lite'    => '0.004',
        'Test::Exception' => '0.29',
    },
    meta_merge => {
        resources => {
            repository  => 'http://github.com/exodist/Exporter-Declare-Magic',
            bugtracker  => 'http://github.com/exodist/Exporter-Declare-Magic/issues',
        },
    }
);

$build->create_build_script;
