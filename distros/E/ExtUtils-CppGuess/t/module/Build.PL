#!/usr/bin/perl -w

use strict;
use blib '../..';
use Module::Build;
use ExtUtils::CppGuess;
use ExtUtils::ParseXS;

my $guess = ExtUtils::CppGuess->new;
$guess->add_extra_compiler_flags(
  '-DINCLUDE_DOT=' .
  ($guess->iostream_fname =~ /\./ ? 1 : 0)
);

# broken on 5.14, on EUPXS 3.04_01 to 3.35
if ($ExtUtils::ParseXS::VERSION > 3.04) {
  if ($] lt '5.016000') {
    $guess->add_extra_compiler_flags('-DCLANG_WORKAROUND_514');
  } elsif ($] lt '5.018000') {
    $guess->add_extra_compiler_flags('-DCLANG_WORKAROUND_516');
  }
}

my $build = Module::Build->new
  ( module_name     => 'CppGuessTest',
    dist_abstract   => 'a test module',
    license         => 'perl',
    xs_files        => { 'CppGuessTest.xs' => 'lib/CppGuessTest.xs' },
    $guess->module_build_options,
    );
$build->create_build_script;
