#!/usr/bin/perl -w

use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME => 'ExtUtils::CppGuess',
    VERSION_FROM => 'lib/ExtUtils/CppGuess.pm',
    LICENSE => 'perl',
    PREREQ_PM => {
        'Capture::Tiny' => '0',
        'File::Basename' => '0',
    },
    TEST_REQUIRES  => {
        'Capture::Tiny' => '0',
        'Module::Build' => '0',
        'ExtUtils::MakeMaker' => '0',
        'Test::More' => '0.88',
        'File::Spec' => '0',
        'ExtUtils::Manifest' => '0',
        'Fatal' => '0',
        'Cwd' => '0',
        'Data::Dumper' => 0,
    },
    clean => { FILES => 't/module_build t/makemaker' },
    META_MERGE => {
      "meta-spec" => { version => 2 },
      resources => {
        repository => {
          type => 'git',
          url => 'git://github.com/tsee/extutils-cppguess',
          web => 'https://github.com/tsee/extutils-cppguess',
        },
      },
    },
);
