
use strict;
use warnings;



use ExtUtils::MakeMaker;

WriteMakefile(
  DISTNAME  => 'Devel-IntelliPerl',
  NAME      => 'Devel::IntelliPerl',
  AUTHOR    => "Moritz\ Onken\ \<onken\@netcubed\.de\>",
  ABSTRACT  => "Auto\-completion\ for\ Perl",
  VERSION   => '0.04',
  EXE_FILES => [ qw() ],
  (eval { ExtUtils::MakeMaker->VERSION(6.31) } ? (LICENSE => 'bsd') : ()),
  PREREQ_PM    => {
    "PPI" => '1.203',
    "MooseX::Method::Signatures" => '0.29',
    "Path::Class" => '0',
    "Devel::Declare" => '0.005011',
    "Moose" => '0.81',
  },
  test => {TESTS => 't/*.t t/editor/*.t'}
);

