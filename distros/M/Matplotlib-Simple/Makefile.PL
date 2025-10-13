#!/usr/bin/env perl

use 5.042;
no source::encoding;
use warnings FATAL => 'all';
use autodie ':default';
use DDP {output => 'STDOUT', array_max => 10, show_memsize => 1};
use Devel::Confess 'color';
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME             => 'Matplotlib::Simple',
  VERSION_FROM     => 'mpl.pm',
#  ABSTRACT_FROM    => 'MatPlotLib-Simple/mpl.pm',
  AUTHOR           => 'David E. Condon',
  LICENSE          => 'freebsd',
  MIN_PERL_VERSION => '5.012',
  EXE_FILES        => ['MatPlotLib-Simple'],
  PREREQ_PM        => {
    'strict'   => 1,
    'warnings' => 1,
    'Data::Printer'  => 1.002001,
    'Capture::Tiny'  => 0.50,
    'Devel::Confess' => 0.009004
  },
  (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
      'meta-spec' => { version => 2 },
      resources => {
          repository => {
              type => 'git',
              url  => 'https://github.com/hhg7/MatPlotLib-Simple.git',
              web  => 'https://github.com/hhg7/MatPlotLib-Simple',
          },
      }})
   : ()
  ),
);
