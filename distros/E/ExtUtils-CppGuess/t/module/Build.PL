#!/usr/bin/perl -w

use strict;
use blib '../..';
use Module::Build;
use ExtUtils::CppGuess;

my $guess = ExtUtils::CppGuess->new;

my $build = Module::Build->new
  ( module_name     => 'CppGuessTest',
    dist_abstract   => 'a test module',
    license         => 'perl',
    xs_files        => { 'CppGuessTest.xs' => 'lib/CppGuessTest.xs' },
    $guess->module_build_options,
    );
$build->create_build_script;
