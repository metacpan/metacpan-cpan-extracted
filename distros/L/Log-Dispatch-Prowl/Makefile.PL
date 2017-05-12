
use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  DISTNAME  => 'Log-Dispatch-Prowl',
  NAME      => 'Log::Dispatch::Prowl',
  AUTHOR    => 'Moritz\ Onken',
  ABSTRACT  => 'Object\ for\ logging\ to\ the\ iPhone',
  VERSION   => '1.000',
  EXE_FILES => [ qw() ],
  (eval { ExtUtils::MakeMaker->VERSION(6.31) } ? (LICENSE => 'mit') : ()),
  PREREQ_PM    => {
    "File::Find::Rule" => '0',
    "Test::More" => '0.92',
    "WebService::Prowl" => '0',
    "Log::Dispatch" => '0',
  },
);
