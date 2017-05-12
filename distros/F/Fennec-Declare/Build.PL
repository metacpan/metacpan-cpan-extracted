#!/usr/bin/perl
use strict;
use warnings;
use Module::Build;

my $build = Module::Build->new(
    module_name => 'Fennec::Declare',
    license     => 'perl',
    dist_author => 'Chad Granum <exodist7@gmail.com>',
    create_readme => 1,
    requires => {
        'Fennec' => '1.012',
        'Exporter::Declare'              => '0.107',
        'Exporter::Declare::Magic'       => '0.107',
        'Devel::Declare::Parser'         => '0.017',
        'Devel::Declare::Parser::Fennec' => '0.004',
    },
    meta_merge => {
        resources => {
            repository  => 'http://github.com/exodist/Fennec-Declare',
            bugtracker  => 'http://github.com/exodist/Fennec-Declare/issues',
            homepage    => 'http://open-exodus.net/projects/Fennec-Declare'
        },
    }
);

$build->create_build_script;
