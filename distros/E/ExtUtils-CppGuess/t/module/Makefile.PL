#!/usr/bin/perl -w

use strict;
use blib '../..';
use ExtUtils::MakeMaker;
use ExtUtils::CppGuess;

my $guess = ExtUtils::CppGuess->new;

WriteMakefile
  ( NAME            => 'CppGuessTest',
    VERSION_FROM    => 'lib/CppGuessTest.pm',
    PL_FILES        => {},
    $guess->makemaker_options,
    );
