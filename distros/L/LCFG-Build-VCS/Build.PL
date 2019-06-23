#!/usr/bin/perl
use strict;
use warnings;
use Module::Build;

my $build = Module::Build->new(
    module_name   => 'LCFG::Build::VCS',
    dist_abstract => 'LCFG version control infrastructure',
    dist_author   => 'Stephen Quinney <squinney@inf.ed.ac.uk>',
    dist_version  => '0.3.9',
    license => 'gpl',
    requires => {
        'perl'         => '5.10.0',
        'Moose'        => '0.57',
        'DateTime'     => '0',
        'IPC::Run'     => '0',
        'File::Copy::Recursive' => '0.36',
        'File::HomeDir' => '0.58',
        'URI'           => '0',
        'Template'      => '2.14',
    },
    build_requires => { 'Test::More' => 0 },
    configure_requires => { 'Module::Build' => '0.40' },
    create_makefile_pl => 'traditional',
    add_to_cleanup => [ 'MANIFEST.bak', 'Changes.bak' ],
);
$build->create_build_script;
