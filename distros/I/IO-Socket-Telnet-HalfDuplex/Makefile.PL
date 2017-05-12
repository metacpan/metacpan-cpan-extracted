
use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  DISTNAME  => 'IO-Socket-Telnet-HalfDuplex',
  NAME      => 'IO::Socket::Telnet::HalfDuplex',
  AUTHOR    => 'Jesse\ Luehrs\ \<doy\ at\ tozt\ dot\ net\>',
  ABSTRACT  => 'more\ reliable\ telnet\ communication',
  VERSION   => '0.02',
  EXE_FILES => [ qw() ],
  (eval { ExtUtils::MakeMaker->VERSION(6.21) } ? (LICENSE => 'perl') : ()),
  PREREQ_PM    => {
    "IO::Socket::Telnet" => '0',
  },
);
