#!/usr/bin/perl
use strict;
use warnings;
use Module::Build;

my $build = Module::Build->new(
    module_name => 'Devel::Declare::Parser::Fennec',
    license     => 'perl',
    dist_author => 'Chad Granum <exodist7@gmail.com>',
    create_readme => 1,
    requires => {
        'Devel::Declare::Parser' => 0.017,
        'Exporter::Declare::Magic' => 0.107,
    },
    meta_merge => {
        resources => {
            repository  => 'http://github.com/exodist/Devel-Declare-Parser-Fennec',
            bugtracker  => 'http://github.com/exodist/Devel-Declare-Parser-Fennec/issues',
        },
    }
);

$build->create_build_script;
