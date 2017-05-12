
use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  DISTNAME  => 'Log-Dispatch-Channels',
  NAME      => 'Log::Dispatch::Channels',
  AUTHOR    => 'Jesse\ Luehrs\ \<doy\ at\ tozt\ dot\ net\>',
  ABSTRACT  => 'Adds separate logging channels to Log::Dispatch',
  VERSION   => '0.01',
  EXE_FILES => [ qw() ],
  (eval { ExtUtils::MakeMaker->VERSION(6.21) } ? (LICENSE => 'perl') : ()),
  PREREQ_PM    => {
    "Test::More" => '0',
    "Test::Exception" => '0',
    "Log::Dispatch" => '0',
    "Carp" => '0',
  },
);
