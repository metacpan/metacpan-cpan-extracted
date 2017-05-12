#!/usr/bin/perl -w

use strict;
use Module::Build;

my $build = Module::Build->new
  ( module_name        => 'Log::Dispatch::Wx',
    license            => 'perl',
    author             => 'Mattia Barbon <mbarbon@cpan.org>',
    requires           => { 'Log::Dispatch'  => '2.11',
                            'Wx'             => '0.16',
                            'perl'           => '5.6',
                            'Test::More'     => '0.48',
                            },
    build_requires     => { 'Module::Build'                  => '0.26',
                            },
    create_makefile_pl => 'passthrough',
  );
$build->create_build_script;
