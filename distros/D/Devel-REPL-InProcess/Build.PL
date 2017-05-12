#!/usr/bin/perl

use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
    module_name => 'Devel::REPL::InProcess',
    license     => 'perl',
    script_files=> ['scripts/inprocess-repl-client'],
    requires    => {
        'perl'                  => '5.10.0',
        'AnyEvent'              => '1.0031',
        'Devel::REPL'           => '1.003012',
        'Term::ReadKey'         => '2.30',
        'PadWalker'             => '2.2',
        'IO::Pty'               => '1.12',
        'Term::ReadLine'        => '1.14',
    },
    configure_requires => {
        'Module::Build' => 0.42,
    },
    test_requires => {
        'Test::Differences'     => 0,
    },
    meta_merge  => {
        resources   => {
            license     => [ 'http://dev.perl.org/licenses/' ],
            bugtracker  => 'https://github.com/mbarbon/devel-repl-inprocess/issues',
            repository  => 'https://github.com/mbarbon/devel-repl-inprocess.git',
        },
    },
);
$build->create_build_script;
