#======================================================================
# Makefile Maker for latexmls - A socket server for LaTeXML
# deyan.ginev@gmail.com
#======================================================================
use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  NAME => 'LaTeXML::Plugin::latexmls',
  AUTHOR => 'Deyan Ginev <deyan.ginev@gmail.com>',
  ABSTRACT => "latexmls - A socket server for daemonized LaTeXML processing",
  VERSION_FROM => 'lib/LaTeXML/Plugin/Latexmls.pm',
  PREREQ_PM => {
    'LaTeXML' => '0.8.5',
    'HTTP::Daemon' => '6',
    'POSIX' => 0,
    'URI' => 0,
    'Encode' => 0,
    'JSON::XS' => 0,
  },
  EXE_FILES => ['bin/latexmls'],
  test => {TESTS => 't/*.t'},
  (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
    'meta-spec' => { version => 2 },
      resources => {
        repository => {
          type => 'git',
          url => 'https://github.com/dginev/LaTeXML-Plugin-latexmls.git',
          web => 'https://github.com/dginev/LaTeXML-Plugin-latexmls',
        }}})
  : ())
);
