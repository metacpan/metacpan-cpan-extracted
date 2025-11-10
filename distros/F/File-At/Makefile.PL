#!/usr/bin/env perl
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => 'File::At',
  VERSION_FROM => 'lib/File/At.pm',
  ABSTRACT     => 'Thin FFI wrapper around the POSIX *at() filesystem syscalls',
  AUTHOR       => 'Nobody <nobody@example.com>',   # swap for real addr if you want
  LICENSE      => 'perl',

  PREREQ_PM    => {
    'FFI::Platypus' => '2.00',
    'Fcntl'         => 0,
    'Digest::MD5'   => 0,   # used by the example script
    'Test::More'    => 0,   # tests
  },

  META_MERGE => {
    resources => {
      repository => 'https://example.com/your/git/repo', # or GitHub/GitLab URL
    },
  },
);
