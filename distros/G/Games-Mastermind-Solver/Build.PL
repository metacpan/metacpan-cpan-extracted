#!/usr/bin/perl -w

use strict;
use Module::Build;

my $builder = Module::Build->new
  ( module_name        => 'Games::Mastermind::Solver',
    license            => 'perl',
    dist_author        => 'Mattia Barbon <mbarbon@cpan.org>',
    requires           => { 'Class::Accessor'         => '0.27',
                            'Games::Mastermind'       => '0.01',
                            'Test::More'              => '0.48',
                            },
    create_makefile_pl => 'passthrough',
    );
$builder->create_build_script;
