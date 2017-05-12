#======================================================================
# Makefile Maker for ltxMojo - LaTeXML's web service
# d.ginev@jacobs-university.de
#======================================================================
use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  NAME => 'LaTeXML::Plugin::LtxMojo',
  AUTHOR => 'Deyan Ginev <d.ginev@jacobs-university.de>',
  ABSTRACT => "ltxMojo - LaTeXML's web service",
  VERSION_FROM => 'lib/LaTeXML/Plugin/LtxMojo.pm',
  PREREQ_PM => {
    'LaTeXML' => '0.8.0',
    'Mojolicious' => '5.0',
    'Archive::Zip' => 0,
    'IO::String' => 0
  },
  EXE_FILES => ['script/ltxmojo'],
  test => {TESTS => 't/*.t'}
);
