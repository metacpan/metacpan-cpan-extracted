#!/usr/bin/perl -w

use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new
  ( module_name => 'ExtUtils::XSpp::Plugin::Cloning',
    license     => 'perl',
    requires    =>
      { 'perl'                => '5.6.1',
        'ExtUtils::XSpp'      => '0.11_02',
        },
    build_requires =>
      { 'Test::More'        => '0',
        'Module::Build'     => '0',
        },
    #add_to_cleanup => [ qw(t/files/foo.h) ],
    #script_files => 'scripts',
    );
$build->create_build_script;
