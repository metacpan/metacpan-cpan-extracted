#!/usr/bin/perl -w

use strict;
use blib '../..';
use ExtUtils::MakeMaker;
use ExtUtils::CppGuess;
use ExtUtils::ParseXS;

my $guess = ExtUtils::CppGuess->new;

# broken on 5.14, on EUPXS 3.04_01 to 3.35
if ($ExtUtils::ParseXS::VERSION > 3.04) {
  if ($] lt '5.016000') {
    $guess->add_extra_compiler_flags('-DCLANG_WORKAROUND_514');
  } elsif ($] lt '5.018000') {
    $guess->add_extra_compiler_flags('-DCLANG_WORKAROUND_516');
  }
}

$guess->add_extra_compiler_flags(
  '-DINCLUDE_DOT=' .
  ($guess->iostream_fname =~ /\./ ? 1 : 0)
);

WriteMakefile
  ( NAME            => 'CppGuessTest',
    VERSION_FROM    => 'lib/CppGuessTest.pm',
    PL_FILES        => {},
    $guess->makemaker_options,
    );
